module DSL
  class Maker
    def self.parse_dsl(dsl)
      eval dsl, self.get_binding
    end

    def self.add_entrypoint(name, &definition_block)
      # Ensure that definition_block has been provided. Otherwise, there's nothing
      # to do.

      # Ensure that get_binding() exists in the child class.
      unless self.respond_to? :get_binding
        define_singleton_method(:get_binding) {
          binding
        }
      end

      kls = Class.new
      define_singleton_method(name.to_sym) do
        obj = kls.new
        return obj.instance_exec(&definition_block)
      end
      return kls
    end
  end
end
