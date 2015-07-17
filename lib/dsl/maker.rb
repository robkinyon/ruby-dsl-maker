require 'docile'

module DSL
  class Maker
    def self.parse_dsl(dsl)
      eval dsl, self.get_binding
    end

    def self.generate_dsl(args={})
      Class.new do
        args.each do |name, type|
          define_method(name.to_sym) do
            as_attr = '@' + name.to_s
            instance_variable_set(as_attr, true)
            instance_variable_get(as_attr)
          end
        end
      end
    end

    def self.add_entrypoint(name, args={}, &definition_block)
      # Without definition_block, there's no way to give back the result of the
      # DSL parsing. So, raise an error if we don't get one.
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
