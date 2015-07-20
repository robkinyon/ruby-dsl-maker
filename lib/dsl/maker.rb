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

    def self.parse_dsl(dsl)
      eval dsl, self.get_binding
    end

    def self.generate_dsl(args={}, &defn_block)
      raise 'Block required for generate_dsl' unless block_given?

      # Inherit from the Boolean class to gain access to the useful methods
      klass = Class.new(Boolean)
      klass.class_eval do
        # This method exists because we cannot seem to inline this method's work
        # where we call it. Could it be a problem of incorrect binding?
        define_method(:apply) do
          instance_exec(&defn_block)
        end

        args.each do |name, type|
          if klass.new.respond_to? name.to_sym
            raise "Illegal attribute name '#{name}'"
          end

          as_attr = '@' + name.to_s
          if type == String
            define_method(name.to_sym) do |*args|
              ___set(as_attr, args[0].to_s) unless args.empty?
              ___get(as_attr)
            end
          elsif type == Boolean
            define_method(name.to_sym) do |*args|
              ___set(as_attr, $to_bool.call(args[0])) unless args.empty?
              # Ensure that the default nil returns as false.
              !!___get(as_attr)
            end
          elsif type == Array
            define_method(name.to_sym) do |*args|
              ___set(as_attr, []) unless ___get(as_attr)
              ___get(as_attr).concat(args) unless args.empty?
              ___get(as_attr)
            end
          elsif type.is_a?(Class) and type.ancestors.include?(Boolean)
            define_method(name.to_sym) do |*args, &dsl_block|
              # FIXME: Ensure dsl_block exists

              unless (args.empty? && !dsl_block)
                obj = type.new(*args)
                Docile.dsl_eval(obj, &dsl_block)
                ___set(as_attr, obj.apply())
              end

              ___get(as_attr)
            end
          else
            raise "Unrecognized attribute type '#{type}'"
          end
        end
      end
      return klass
    end

    def self.add_entrypoint(name, args={}, &defn_block)
      # Without defn_block, there's no way to give back the result of the
      # DSL parsing. So, raise an error if we don't get one.
      # TODO: Provide a default block that returns the datastructure as a HoH.
      raise "Block required for add_entrypoint" unless block_given?

      # Ensure that get_binding() exists in the child class.
      unless self.respond_to? :get_binding
        define_singleton_method(:get_binding) {
          binding
        }
      end

      # FIXME: This is a wart. Really, we should be pulling out name, then
      # yielding to generate_dsl() in some fashion.
      kls = generate_dsl(args) {}

      define_singleton_method(name.to_sym) do |&dsl_block|
        obj = kls.new
        Docile.dsl_eval(obj, &dsl_block) if dsl_block
        return obj.instance_exec(&defn_block)
      end
      return kls
    end
  end
end
