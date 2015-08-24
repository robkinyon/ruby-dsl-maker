require 'dsl/maker/version'

require 'docile'

# Children of DSL::Maker are the "control class". All of the classes that inherit
# from DSL::Maker::Base are "dsl classes" - classes that are passed to Docile and
# which represent levels of the DSL. In order for :parse_dsl/:execute_dsl to
# return back the accumulated values in the order provided, we need to "pierce the
# veil" (so to speak) between the control and dsl classes. That's done using the
# parent_class class attribute in the dsl classes.

# This is the base class we provide.
class DSL::Maker
  # This is the base class for all DSL-parsing classes.
  class Base
    # 21 character method names are obscene. Make it easier to read.
    alias :___set :instance_variable_set

    # 21 character method names are obscene. Make it easier to read.
    alias :___get :instance_variable_get

    def get_binding
      binding
    end

    define_singleton_method(:add_verification) do |&block|
      # FIXME: This throws regardless. Is this because of the difference between
      # proc and block?
      #raise "Block required for add_verification" unless block_given?

      @verifications ||= []

      # This craziness converts the block provided into a proc that can be called
      # in add_entrypoint(). Taken from http://stackoverflow.com/a/2946734/1732954
      # Note: self is not preserved. This should be okay because the verification
      # should be idempotent relative to the value provided (side-effect-free).
      obj = Object.new
      obj.define_singleton_method(:_, &block)
      @verifications.push(obj.method(:_).to_proc)

      return
    end
  end

  # Create the DSL::Maker::Any type identifier, equivalent to Object.
  Any = Object

  # This is a useful module that contains all the Boolean handling we need.
  module Boolean
    {
      :yes => true, :no  => false,
      :on  => true, :off => false,
    }.each do |name, result|
      define_method(name) { result }
    end

    def self.coerce(value)
      if value
        return false if %w(no off false nil).include? value.to_s.downcase
      end
      # The bang-bang boolean-izes the value. We want this to be lossy.
      !!value
    end
  end
  Yes = On = True = true
  No = Off = False = false

  class Alias
    attr_reader :real_name
    def initialize(real_name)
      @real_name = real_name
    end
  end
  @@aliases = {}
  def self.AliasOf(name)
    @@aliases[name] ||= Alias.new(name)
  end
  def self.is_alias(type)
    type.instance_of? Alias
  end

  class ArrayType
    attr_reader :base_type
    def initialize(base_type)
      @base_type = base_type
    end
  end
  @@arrays = {}
  ArrayOf = Class.new do
    def self.[](type)
      raise "Cannot make an array of an alias" if DSL::Maker.is_alias(type)
      raise "Unknown type provided to ArrayOf" unless @@types.has_key?(type) || DSL::Maker.is_dsl(type)
      @@arrays[type] ||= ArrayType.new(type)
    end
  end
  def self.is_array(type)
    type.instance_of? ArrayType
  end

  # Parse the DSL provided in the parameter.
  #
  # @param dsl [String] The DSL to be parsed by this class.
  #
  # @return    [Array] Whatever is returned by the block defined in this class.
  def self.parse_dsl(dsl=nil)
    raise 'Must call add_entrypoint before parse_dsl' unless @klass
    raise 'String required for parse_dsl' unless dsl.instance_of? String

    run_dsl { eval dsl, @klass.new.get_binding }
  end

  # Execute the DSL provided in the block.
  #
  # @param &block [Block] The DSL to be executed by this class.
  #
  # @return    [Array] Whatever is returned by the block defined in this class.
  def self.execute_dsl(&block)
    raise 'Must call add_entrypoint before execute_dsl' unless @klass
    raise 'Block required for execute_dsl' unless block_given?

    run_dsl { @klass.new.instance_eval(&block) }
  end

  # This adds a type coercion that's used when creating the DSL.
  #
  # @note These type coercions are global to all DSLs.
  #
  # @param type   [Object] the name of the helper
  # @param &block [Block]  The function to be executed when the coercion is exercised.
  #
  # Your block will receive the following signature: |attr, *args| where 'attr' is
  # the name of the attribute and *args are the arguments passed into your method
  # within the DSL. You are responsible for acting as a mutator. You have ___get()
  # and ___set() available for your use. These are aliases to
  # instance_variable_get and instance_variable_set, respectively. Please read the
  # coercions provided for you in this source file as examples.
  # 
  # @return nil
  def self.add_type(type, &block)
    raise "Block required for add_type" unless block_given?
    raise "'#{type}' is already a type coercion" if @@types.has_key? type

    @@types[type] = block

    return
  end

  # Add the meat of a DSL block to some level of this class's DSL.
  #
  # In order for Docile to parse a DSL, each level must be represented by a
  # different class. This method creates anonymous classes that each represents
  # a different level in the DSL's structure.
  #
  # The creation of each DSL element is delegated to build_dsl_element.
  #
  # @param args  [Hash]   the elements of the DSL block (passed to generate_dsl)
  # @param defn_block [Proc]   what is executed once the DSL block is parsed.
  #
  # @return      [Class]  The class that implements this level's DSL definition.
  def self.generate_dsl(args={}, &defn_block)
    raise 'Block required for generate_dsl' unless block_given?

    dsl_class = Class.new(DSL::Maker::Base) do
      include DSL::Maker::Boolean

      class << self
        attr_accessor :parent_class, :verifications
      end

      define_method(:__apply) do |*args|
        instance_exec(*args, &defn_block)
      end
    end

    args.each do |name, type|
      if dsl_class.new.respond_to? name.to_sym
        raise "Illegal attribute name '#{name}'"
      end

      build_dsl_element(dsl_class, name, type)
    end

    return dsl_class
  end

  # Add an entrypoint (top-level DSL element) to this class's DSL.
  #
  # This delegates to generate_dsl() for the majority of the work.
  #
  # @note `args` could be a Hash (to be passed to generate_dsl()) or the result
  # of a call to generate_dsl().
  #
  # @param name  [String] the name of the entrypoint
  # @param args  [Hash]   the elements of the DSL block (passed to generate_dsl)
  # @param defn_block [Proc]   what is executed once the DSL block is parsed.
  # 
  # @return      [Class]  The class that implements this level's DSL definition.
  def self.add_entrypoint(name, args={}, &defn_block)
    symname = name.to_sym

    if is_entrypoint(symname)
      raise "'#{name.to_s}' is already an entrypoint"
    end

    if is_dsl(args)
      dsl_class = args
    else
      # Without defn_block, there's no way to give back the result of the
      # DSL parsing. So, raise an error if we don't get one.
      # TODO: Provide a default block that returns the datastructure as a HoH.

      raise "Block required for add_entrypoint" unless block_given?
      dsl_class = generate_dsl(args, &defn_block)
    end
    
    if @klass
      build_dsl_element(@klass, symname, dsl_class)
    else
      # FIXME: We shouldn't need the blank block here ...
      # This blank block is representative of the implicit (and missing) outermost
      # block around the DSL that we are not putting into place in :parse_dsl or
      # :execute_dsl.
      @klass = generate_dsl({
        symname => dsl_class
      }) {}

      # This marks @klass as the root DSL class.
      @klass.parent_class = self
    end

    @entrypoints ||= {}
    return @entrypoints[symname] = dsl_class
  end

  # This returns the DSL corresponding to the entrypoint's name.
  #
  # @param name  [String] the name of the entrypoint
  # 
  # @return      [Class]  The class that implements this name's DSL definition.
  def self.entrypoint(name)
    unless is_entrypoint(name)
      raise "'#{name.to_s}' is not an entrypoint"
    end

    return @entrypoints[name.to_sym]
  end

  # This adds a helper function that's accessible within the DSL.
  #
  # Note: These helpers are global to all DSLs.
  #
  # @param name   [String] the name of the helper
  # @param &block [Block]  The function to be executed when the helper is called.
  # 
  # @return nil
  def self.add_helper(name, &block)
    raise "Block required for add_helper" unless block_given?

    if DSL::Maker::Base.new.respond_to? name.to_sym
      raise "'#{name.to_s}' is already a helper"
    end

    DSL::Maker::Base.class_eval do
      define_method(name.to_sym, &block)
    end

    return
  end

  # This adds a verification that's executed after the DSL is finished parsing.
  #
  # The verification will be called with the value(s) returned by the entrypoint's
  # execution. If the verification returns a true value (of any kind), then that
  # will be raised as a runtime exception.
  #
  # You can also call add_verification on the return values from generate_dsl() or
  # add_entrypoint(). In those cases, omit the :name because you have already
  # chosen the DSL layer you're adding the verification to.
  #
  # @note These verifications are specific to the DSL you add them to.
  #
  # @note Verifications are called in the order you specify them.
  #
  # @param name   [String] the name of the entrypoint to add a verification to
  # @param &block [Block]  The function to be executed when verifications execute
  # 
  # @return nil
  def self.add_verification(name, &block)
    raise "Block required for add_verification" unless block_given?
    raise "'#{name.to_s}' is not an entrypoint for a verification" unless is_entrypoint(name)

    @entrypoints[name.to_sym].add_verification(&block)
  end

  private

  # This is deliberately global to the hierarchy in order for DSL::Maker to add
  # the generic types. While this has the potential to cause userspace collisions,
  # it's highly unlikely that DSLs with divergent types will coexist in the same
  # Ruby process.
  @@types = {}

  # Add a single element of a DSL to a class representing a level in a DSL.
  #
  # Each of the types represents a coercion - a guarantee and check of the value
  # in that name. The standard type coercions are:
  #
  #   * Any  - whatever you give is returned.
  #   * String  - the string value of whatever you give is returned.
  #   * Integer - the integer value of whatever you give is returned.
  #   * Boolean - the truthiness of whatever you give is returned.
  #   * generate_dsl() - this represents a new level of the DSL.
  #   * AliasOf(<name>) - this aliases a name to another name.
  #   * ArrayOf[<type>] - this creates an array of the <type> coercion.
  #
  # @param klass [Class]  The class representing this level in the DSL.
  # @param name  [String] The name of the element we're working on.
  # @param type  [Class]  The type of this element we're working on.
  #                       This is the type coercion spoken above.
  #
  # @return   nil
  def self.build_dsl_element(klass, name, type)
    if @@types.has_key?(type)
      klass.class_eval do
        define_method(name.to_sym) do |*args|
          instance_exec('@' + name.to_s, *args, &@@types[type])
        end
      end
    elsif is_dsl(type)
      as_attr = '@' + name.to_s
      klass.class_eval do
        define_method(name.to_sym) do |*args, &dsl_block|
          if (!args.empty? || dsl_block)
            obj = type.new
            Docile.dsl_eval(obj, &dsl_block) if dsl_block
            rv = obj.__apply(*args)

            if v = type.instance_variable_get(:@verifications)
              v.each do |verify|
                failure = verify.call(rv)
                raise failure if failure
              end
            end

            # This is the one place where we pull out the entrypoint results and
            # put them into the control class.
            if klass.parent_class
              # Use the full instance_variable_get() in order to avoid having to
              # create accessors that could be misused outside this class.
              klass.parent_class.instance_variable_get(:@accumulator).push(rv)
            end

            ___set(as_attr, rv)
          end
          ___get(as_attr)
        end
      end
    elsif is_alias(type)
      klass.class_eval do
        alias_method name, type.real_name
      end
    elsif is_array(type)
      as_attr = '@' + name.to_s

      klass.class_eval do
        define_method(name.to_sym) do |*args, &dsl_block|
          rv = ___get(as_attr)
          ___set(as_attr, rv = []) unless rv

          if dsl_block
            # This code is copy-pasted from the is_dsl() section above. Figure out
            # how to hoist this code into something reusable. But, we don't need
            # the parent_class section (do we?)
            obj = type.base_type.new
            Docile.dsl_eval(obj, &dsl_block)
            dsl_value = obj.__apply(*args)

            if v = type.base_type.instance_variable_get(:@verifications)
              v.each do |verify|
                failure = verify.call(dsl_value)
                raise failure if failure
              end
            end

            rv.push(dsl_value)
          elsif !args.empty?
            rv.concat(
              args.map do |item|
                # Assumption: 10x_ will never be used as an attribute name.
                klass.new.instance_exec('@__________', item, &@@types[type.base_type])
              end
            )
          end

          rv
        end
      end
    else
      raise "Unrecognized element type '#{type}'"
    end

    return
  end

  def self.run_dsl()
    # build_dsl_element() will use @accumulator to handle multiple entrypoints if
    # the class in question is a root DSL class. Reset it here so that we're only
    # handling the values from this run.
    @accumulator = []

    yield

    return @accumulator
  end

  def self.is_dsl(proto)
    proto.is_a?(Class) && proto.ancestors.include?(DSL::Maker::Base)
  end

  def self.is_entrypoint(name)
    @entrypoints && @entrypoints.has_key?(name.to_sym)
  end
end

# These are the default setups

DSL::Maker.add_type(DSL::Maker::Any) do |attr, *args|
  ___set(attr, args[0]) unless args.empty?
  ___get(attr)
end
DSL::Maker.add_type(Integer) do |attr, *args|
  ___set(attr, args[0].to_i) unless args.empty?
  ___get(attr)
end
DSL::Maker.add_type(String) do |attr, *args|
  ___set(attr, args[0].to_s) unless args.empty?
  ___get(attr)
end
DSL::Maker.add_type(DSL::Maker::Boolean) do |attr, *args|
  ___set(attr, DSL::Maker::Boolean.coerce(args[0])) unless args.empty?
  # Ensure that the default nil also returns as false.
  !!___get(attr)
end

# A helper method for handling defaults from args easily.
#
# @param method_name [String]  The name of the attribute being defaulted.
# @param args        [Array]   The arguments provided to the block.
# @param position    [Integer] The index in args to work with, default 0.
#
# @return nil
DSL::Maker.add_helper(:default) do |method_name, args, position=0|
  method = method_name.to_sym
  if args.length >= (position + 1) && !self.send(method)
    self.send(method, args[position])
  end
  return
end
