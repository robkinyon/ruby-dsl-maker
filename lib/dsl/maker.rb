require 'dsl/maker/version'

require 'docile'

# This is the base class we provide.
class DSL::Maker
  # This is the base class for all DSL-parsing classes.
  class Base
    # 21 character method names are obscene. Make it easier to read.
    alias :___set :instance_variable_set

    # 21 character method names are obscene. Make it easier to read.
    alias :___get :instance_variable_get
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

  # Parse the DSL provided in the parameter.
  #
  # @note If the DSL contains multiple entrypoints, then this will return an
  # Array. This is desirable.
  #
  # @param dsl [String] The DSL to be parsed by this class.
  #
  # @return    [Object] Whatever is returned by the block defined in this class.
  def self.parse_dsl(dsl)
    __run_dsl { eval dsl, self.get_binding }
  end

  # Execute the DSL provided in the block.
  #
  # @note If the DSL contains multiple entrypoints, then this will return an
  # Array. This is desirable.
  #
  # @param &block [Block] The DSL to be executed by this class.
  #
  # @return    [Object] Whatever is returned by &block
  def self.execute_dsl(&block)
    raise 'Block required for execute_dsl' unless block_given?

    __run_dsl { instance_eval(&block) }
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

    @@types[type] = ->(klass, name, type) {
      klass.class_eval do
        define_method(name.to_sym) do |*args|
          instance_exec('@' + name.to_s, *args, &block)
        end
      end
    }

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

    if self.respond_to?(symname)
      raise "'#{name.to_s}' is already an entrypoint"
    end

    if __is_dsl(args)
      dsl_class = args
    else
      # Without defn_block, there's no way to give back the result of the
      # DSL parsing. So, raise an error if we don't get one.
      # TODO: Provide a default block that returns the datastructure as a HoH.

      raise "Block required for add_entrypoint" unless block_given?
      dsl_class = generate_dsl(args, &defn_block)
    end

    define_singleton_method(symname) do |*args, &dsl_block|
      obj = dsl_class.new
      Docile.dsl_eval(obj, &dsl_block) if dsl_block
      rv = obj.__apply(*args)

      if @verifications && @verifications.has_key?(symname)
        @verifications[symname].each do |verify|
          failure = verify.call(rv)
          raise failure if failure
        end
      end

      @accumulator.push(rv)
      return rv
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
    unless __is_entrypoint(name)
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
  # Note: These verifications are specific to the DSL you add them to.
  # Note: Verifications are called in the order you specify them.
  #
  # @param name   [String] the name of the entrypoint to add a verification to
  # @param &block [Block]  The function to be executed when verifications execute
  # 
  # @return nil
  def self.add_verification(name, &block)
    raise "Block required for add_verification" unless block_given?
    raise "'#{name.to_s}' is not an entrypoint for a verification" unless __is_entrypoint(name)

    @verifications ||= {}
    @verifications[name.to_sym] ||= []

    # This craziness converts the block provided into a proc that can be called
    # in add_entrypoint(). Taken from http://stackoverflow.com/a/2946734/1732954
    # Note: self is not preserved. This should be okay because the verification
    # should only care about the value provided.
    obj = Object.new
    obj.define_singleton_method(:_, &block)
    @verifications[name.to_sym].push(obj.method(:_).to_proc)

    return
  end

  private

  # Returns the binding as needed by parse_dsl() and execute_dsl()
  #
  # @return [Binding] The binding of the invoking class.
  def self.get_binding
    binding
  end

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
  #
  # @param klass [Class]  The class representing this level in the DSL.
  # @param name  [String] The name of the element we're working on.
  # @param type  [Class]  The type of this element we're working on.
  #                       This is the type coercion spoken above.
  #
  # @return   nil

  def self.build_dsl_element(klass, name, type)
    if @@types.has_key?(type)
      @@types[type].call(klass, name, type)
    elsif __is_dsl(type)
      as_attr = '@' + name.to_s
      klass.class_eval do
        define_method(name.to_sym) do |*args, &dsl_block|
          if (!args.empty? || dsl_block)
            obj = type.new
            Docile.dsl_eval(obj, &dsl_block) if dsl_block
            ___set(as_attr, obj.__apply(*args))
          end
          ___get(as_attr)
        end
      end
    else
      raise "Unrecognized element type '#{type}'"
    end

    return
  end

  def self.__run_dsl()
    # add_entrypoint() will use @accumulator to handle multiple entrypoints.
    # Reset it here so that we're only handling the values from this run.
    @accumulator = []

    yield

    if @accumulator.length <= 1
      return @accumulator[0]
    end
    return @accumulator
  end

  def self.__is_dsl(proto)
    proto.is_a?(Class) && proto.ancestors.include?(DSL::Maker::Base)
  end

  def self.__is_entrypoint(name)
    respond_to?(name.to_sym)
  end
end

# These are the default setups.

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
