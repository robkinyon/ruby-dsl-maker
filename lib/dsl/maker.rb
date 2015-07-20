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

    def self.generate_dsl(args={})
      # Inherit from the Boolean class to gain access to the useful methods
      Class.new(Boolean) do
        args.each do |name, type|
          raise "Illegal attribute name '#{name}'" if Boolean.new.respond_to? name

          as_attr = '@' + name.to_s
          if type == String
            define_method(name.to_sym) do |*args|
              instance_variable_set(as_attr, args[0].to_s) unless args.empty?
              instance_variable_get(as_attr)
            end
          elsif type == Boolean
            define_method(name.to_sym) do |*args|
              instance_variable_set(as_attr, $to_bool.call(args[0])) unless args.empty?
              # Ensure that the default nil returns as false.
              !!instance_variable_get(as_attr)
            end
          else
            raise "Unrecognized attribute type '#{type}'"
          end
        end
      end
    end

    def self.add_entrypoint(name, args={}, &definition_block)
      # Without definition_block, there's no way to give back the result of the
      # DSL parsing. So, raise an error if we don't get one.
      # TODO: Provide a default block that returns the datastructure as a HoH.
      raise "Block required for add_entrypoint" unless definition_block

      # Ensure that get_binding() exists in the child class.
      unless self.respond_to? :get_binding
        define_singleton_method(:get_binding) {
          binding
        }
      end

      kls = generate_dsl(args)
      define_singleton_method(name.to_sym) do |&dsl_block|
        obj = kls.new
        Docile.dsl_eval(obj, &dsl_block) if dsl_block
        return obj.instance_exec(&definition_block)
      end
      return kls
    end
  end
end
