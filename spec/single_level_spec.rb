# This will use the pizza-maker DSL from Docile's tests.
# @sauce_level = :extra
# pizza do
#   cheese
#   pepperoni
#   sauce @sauce_level
# end
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>
describe 'Single-level DSL' do
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

  it 'makes a cheese pizza' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => true,
      }) do
        Pizza.new(cheese, nil, nil, nil)
      end
    end

    pizza = dsl_class.parse_dsl('pizza { cheese }')
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
end
