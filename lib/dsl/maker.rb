require 'dsl/maker/version'

require 'docile'

module DSL
  class Maker
    class Boolean
      {
        :yes => true, :no  => false,
        :on  => true, :off => false,
      }.each do |name, result|
        define_method(name) { result }
      end

      # 21 character method names are obscene. Make it easier to read.
      alias :___set :instance_variable_set
      alias :___get :instance_variable_get

      def default(method_name, args, position=0)
        method = method_name.to_sym
        if args.length >= (position + 1) && !self.send(method)
          self.send(method, args[position])
        end
      end
    end
    Yes = On = True = true
    No = Off = False = false
    $to_bool = lambda do |value|
      if value
        return false if %w(no off false nil).include? value.to_s.downcase
      end
      # The bang-bang boolean-izes the value. We want this to be lossy.
      !!value
    end

    # TODO: Is this safe if the invoker doesn't use parse_dsl()?
    @@accumulator = []
    def self.parse_dsl(dsl)
      # add_entrypoint() will use @@accumulator to handle multiple entrypoints.
      # Reset it here so that we're only handling the values from this run.
      @@accumulator = []
      eval dsl, self.get_binding
      if @@accumulator.length <= 1
        return @@accumulator[0]
      end
      return @@accumulator
    end

    @@dsl_elements = {
      String => ->(klass, name, type) {
        as_attr = '@' + name.to_s
        klass.class_eval do
          define_method(name.to_sym) do |*args|
            ___set(as_attr, args[0].to_s) unless args.empty?
            ___get(as_attr)
          end
        end
      },
      Boolean => ->(klass, name, type) {
        as_attr = '@' + name.to_s
        klass.class_eval do
          define_method(name.to_sym) do |*args|
            ___set(as_attr, $to_bool.call(args[0])) unless args.empty?
            # Ensure that the default nil returns as false.
            !!___get(as_attr)
          end
        end
      },
    }
    def self.build_dsl_element(klass, name, type)
      if @@dsl_elements.has_key?(type)
        @@dsl_elements[type].call(klass, name, type)
      elsif type.is_a?(Class) && type.ancestors.include?(Boolean)
        as_attr = '@' + name.to_s
        klass.class_eval do
          define_method(name.to_sym) do |*args, &dsl_block|
            unless (args.empty? && !dsl_block)
              obj = type.new
              Docile.dsl_eval(obj, &dsl_block) if dsl_block

              # I don't know why this code doesn't work, but it's why __apply().
              #___set(as_attr, obj.instance_exec(*args, &defn_block))
              ___set(as_attr, obj.__apply(*args))
            end
            ___get(as_attr)
          end
        end
      else
        raise "Unrecognized element type '#{type}'"
      end
    end

    def self.generate_dsl(args={}, &defn_block)
      raise 'Block required for generate_dsl' unless block_given?

      # Inherit from the Boolean class to gain access to the useful methods
      # TODO: Convert DSL::Maker::Boolean into a Role
      # TODO: Create a DSL::Maker::Base class to inherit from
      klass = Class.new(Boolean) do
        # This instance method exists because we cannot seem to inline its work
        # where we call it. Could it be a problem of incorrect binding?
        # It has to be defined here because it needs access to &defn_block
        define_method(:__apply) do |*args|
          instance_exec(*args, &defn_block)
        end
      end

      args.each do |name, type|
        if klass.new.respond_to? name.to_sym
          raise "Illegal attribute name '#{name}'"
        end

        build_dsl_element(klass, name, type)
      end

      return klass
    end

    def self.add_entrypoint(name, args={}, &defn_block)
      # Without defn_block, there's no way to give back the result of the
      # DSL parsing. So, raise an error if we don't get one.
      # TODO: Provide a default block that returns the datastructure as a HoH.
      raise "Block required for add_entrypoint" unless block_given?

      # Ensure that get_binding() exists in the child class. This is necessary to
      # provide parse_dsl() so that eval works as expected. We have to do it here
      # because this is the only place we know for certain will be called.
      unless self.respond_to? :get_binding
        define_singleton_method(:get_binding) { binding }
      end

      # FIXME: This is a wart. Really, we should be pulling out name, then
      # yielding to generate_dsl() in some fashion.
      dsl_class = generate_dsl(args) {}

      define_singleton_method(name.to_sym) do |*args, &dsl_block|
        obj = dsl_class.new
        Docile.dsl_eval(obj, &dsl_block) if dsl_block
        rv = obj.instance_exec(*args, &defn_block)
        @@accumulator.push(rv)
        return rv
      end
      return dsl_class
    end
  end
end
