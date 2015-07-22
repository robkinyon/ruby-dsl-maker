# This will use the pizza-maker DSL from Docile's documentation.
# @sauce_level = :extra
# pizza do
#   cheese yes
#   pepperoni yes
#   sauce @sauce_level
# end
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>

# Notes:
# 1. Because we're creating classes on the fly, we must fully-qualify the Boolean
# class name. If we created real classes, the context would be provided for us.
describe 'A single-level DSL for pizza' do
  $toppings = [:cheese, :pepperoni, :bacon, :sauce]
  Pizza = Struct.new(*$toppings)

  def verify_pizza(pizza, values={})
    expect(pizza).to be_instance_of(Pizza)
    $toppings.each do |topping|
      expect(pizza.send(topping)).to eq(values[topping])
    end
  end

  it 'makes a blank pizza' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza) { Pizza.new }
    end

    pizza = dsl_class.parse_dsl('pizza')
    verify_pizza(pizza)
  end

  # This tests all the possible Boolean invocations
  it 'makes a cheese(-less) pizza' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => DSL::Maker::Boolean,
      }) do
        Pizza.new(cheese, nil, nil, nil)
      end
    end

    # There is no way to tell if this is invocation is to set the value or to
    # retrieve the value from within the DSL. Therefore, we assume it's a getter
    # and don't default the value to true. Otherwise, false values wouldn't work.
    pizza = dsl_class.parse_dsl('pizza { cheese }')
    verify_pizza(pizza, :cheese => false)

    # Test the Ruby booleans and falsey's.
    [ true, false, nil ].each do |cheese|
      pizza = dsl_class.parse_dsl("pizza { cheese #{cheese} }")
      verify_pizza(pizza, :cheese => !!cheese)
    end

    # Test the true values we provide
    %w(Yes On True yes on).each do |cheese|
      pizza = dsl_class.parse_dsl("pizza { cheese #{cheese} }")
      verify_pizza(pizza, :cheese => true)
    end

    # Test the false values we provide
    %w(No Off False no off).each do |cheese|
      pizza = dsl_class.parse_dsl("pizza { cheese #{cheese} }")
      verify_pizza(pizza, :cheese => false)
    end

    # Test the boolean-ized strings we provide
    %w(Yes On True yes on true).each do |cheese|
      pizza = dsl_class.parse_dsl("pizza { cheese '#{cheese}' }")
      verify_pizza(pizza, :cheese => true)
    end
    %w(No Off False no off false nil).each do |cheese|
      pizza = dsl_class.parse_dsl("pizza { cheese '#{cheese}' }")
      verify_pizza(pizza, :cheese => false)
    end

    # Test some other things which should all be true
    pizza = dsl_class.parse_dsl("pizza { cheese 5 }")
    verify_pizza(pizza, :cheese => true)
  end

  it 'makes a saucy pizza' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :sauce => String,
      }) do
        Pizza.new(nil, nil, nil, sauce)
      end
    end

    [ :extra, 'extra', :none ].each do |level|
      pizza = case level
        when String
          dsl_class.parse_dsl("pizza { sauce '#{level}' }")
        when Symbol
          dsl_class.parse_dsl("pizza { sauce :#{level} }")
        else
          raise "Unexpected class #{level.class}"
      end
      verify_pizza(pizza, :sauce => level.to_s)
    end
  end

  it 'makes a pizza with everything' do
    dsl_class = Class.new(DSL::Maker) do
      toppings_dsl = generate_dsl({
        :cheese => DSL::Maker::Boolean,
        :bacon => DSL::Maker::Boolean,
        :pepperoni => DSL::Maker::Boolean,
        :sauce => String,
      }) {}

      # This is a wart - this block should be against toppings_dsl, not here.
      add_entrypoint(:pizza, toppings_dsl) do
        Pizza.new(cheese, pepperoni, bacon, sauce)
      end
    end

    pizza = dsl_class.parse_dsl("
      pizza {
        cheese yes
        pepperoni yes
        bacon no
        sauce :extra
      }
    ")
    verify_pizza(pizza,
      :sauce => 'extra',
      :pepperoni => true,
      :bacon => false,
      :cheese => true,
    )
  end
end
