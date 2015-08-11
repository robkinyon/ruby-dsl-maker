# This is to test the AliasOf(:name) type

describe "Packager DSL AliasOf" do
  # This uses $toppings defined in spec/spec_helper.rb
  def verify_pizza(pizza, values={})
    expect(pizza).to be_instance_of(Structs::Pizza)
    $toppings.each do |topping|
      expect(pizza.send(topping)).to eq(values[topping])
    end
  end

  it "can alias a Boolean" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => DSL::Maker::Boolean,
        :cheeseyness => DSL::Maker::AliasOf(:cheese),
      }) {
        Structs::Pizza.new(cheeseyness)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza { cheese yes }
    }
    verify_pizza(pizza[0], :cheese => true)
  end

  it "can alias multiple times" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => DSL::Maker::Boolean,
        :cheeseyness => DSL::Maker::AliasOf(:cheese),
        :fromage => DSL::Maker::AliasOf(:cheese),
      }) {
        Structs::Pizza.new(cheeseyness)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza { fromage yes }
    }
    verify_pizza(pizza[0], :cheese => true)
  end

  it "can have many different aliases" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => DSL::Maker::Boolean,
        :fromage => DSL::Maker::AliasOf(:cheese),
        :bacon => DSL::Maker::Boolean,
        :panceta => DSL::Maker::AliasOf(:bacon),
      }) {
        Structs::Pizza.new(fromage, nil, panceta)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza {
        cheese yes
        bacon yes
      }
    }
    verify_pizza(pizza[0], :cheese => true, :bacon => true)
  end

  it "can alias a DSL" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheese => generate_dsl({
          :type => String,
          :color => String,
        }) do
          Structs::Cheese.new(type, color)
        end,
        :cheeseyness => DSL::Maker::AliasOf(:cheese)
      }) {
        Structs::Pizza.new(cheeseyness)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza {
        cheese {
          type 'mozzarrella'
          color 'white'
        }
      }
    }
    verify_pizza(pizza[0], :cheese => Structs::Cheese.new('mozzarrella', 'white'))
  end
end
