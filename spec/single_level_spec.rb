# This will use the pizza-maker DSL from Docile's tests.
# @sauce_level = :extra
# pizza do
#   cheese
#   pepperoni
#   sauce @sauce_level
# end
#=> #<Pizza:0x00001009dc398 @cheese=true, @pepperoni=true, @bacon=false, @sauce=:extra>
describe 'Single-level DSL' do
  toppings = [:cheese, :pepperoni, :bacon, :sauce]
  Pizza = Struct.new(*toppings)

  it 'makes a blank pizza' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza) { Pizza.new }
    end

    pizza = dsl_class.parse_dsl('pizza')
    expect(pizza).to be_instance_of(Pizza)

    toppings.each do |topping|
      expect(pizza.send(topping)).to be_nil
    end
  end

  it 'makes a cheese pizza' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => true,
      }) do
        Pizza.new(cheese)
      end
    end

    pizza = dsl_class.parse_dsl('pizza { cheese }')
    expect(pizza).to be_instance_of(Pizza)

    toppings.each do |topping|
      case topping
        when :cheese
          expect(pizza.send(topping)).to be(true)
        else
          expect(pizza.send(topping)).to be_nil
      end
    end
  end
end
