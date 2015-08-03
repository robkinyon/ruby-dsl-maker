# These are tests about the validation process for DSL::Maker

describe "Validations" do
  it "validates entrypoint-specific items" do
    dsl_class = Class.new(DSL::Maker) do
      toppings_dsl = generate_dsl({
        :cheese => DSL::Maker::Boolean,
        :bacon => DSL::Maker::Boolean,
        :pepperoni => DSL::Maker::Boolean,
        :sauce => String,
      }) do
        $Pizza.new(cheese, pepperoni, bacon, sauce)
      end

      add_entrypoint(:pizza, toppings_dsl)
      add_verification(:pizza) do |item|
        return "Pizza must have sauce" unless item.sauce
      end
    end

    expect {
      dsl_class.parse_dsl("pizza {}")
    }.to raise_error("Pizza must have sauce")

    expect {
      dsl_class.parse_dsl("pizza { sauce :extra }")
    }.to_not raise_error
  end
end
