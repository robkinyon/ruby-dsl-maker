describe "Packager DSL ArrayOf" do
  # This uses $toppings defined in spec/spec_helper.rb
  def verify_pizza(pizza, values={})
    expect(pizza).to be_instance_of(Structs::Pizza)
    $toppings.each do |topping|
      expect(pizza.send(topping)).to eq(values[topping])
    end
  end

  it "can array a String" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:pizza, {
        :cheeses => DSL::Maker::ArrayOf[String],
        :cheese => DSL::Maker::AliasOf(:cheeses),
      }) {
        Structs::Pizza.new(cheeses)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza {
        cheeses :cheddar
        cheeses 'mozzarrella'
      }
    }
    verify_pizza(pizza, :cheese => %w(cheddar mozzarrella))

    pizza = dsl_class.execute_dsl {
      pizza {
        cheeses 'cheddar', 'mozzarrella'
      }
    }
    verify_pizza(pizza, :cheese => %w(cheddar mozzarrella))
  end

  it "can array a DSL" do
    dsl_class = Class.new(DSL::Maker) do
      cheese_dsl = generate_dsl({
        :type => String,
        :color => String,
      }) do
        Structs::Cheese.new(type, color)
      end

      add_entrypoint(:pizza, {
        :cheeses => DSL::Maker::ArrayOf[cheese_dsl],
        :cheese => DSL::Maker::AliasOf(:cheeses),
      }) {
        Structs::Pizza.new(cheeses)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza {
        cheese {
          type 'mozzarrella'
          color 'white'
        }
        cheese {
          type 'cheddar'
          color 'orange'
        }
      }
    }
    verify_pizza(pizza, :cheese => [
      Structs::Cheese.new('mozzarrella', 'white'),
      Structs::Cheese.new('cheddar', 'orange'),
    ])
  end

  it "can array a DSL with verifications" do
    dsl_class = Class.new(DSL::Maker) do
      cheese_dsl = generate_dsl({
        :type => String,
        :color => String,
      }) do
        Structs::Cheese.new(type, color)
      end
      cheese_dsl.add_verification do |item|
        return "Cheese must have a color" unless item.color
      end

      add_entrypoint(:pizza, {
        :cheeses => DSL::Maker::ArrayOf[cheese_dsl],
        :cheese => DSL::Maker::AliasOf(:cheeses),
      }) {
        Structs::Pizza.new(cheeses)
      }
    end

    expect {
      dsl_class.execute_dsl {
        pizza {
          cheese {
            type 'mozzarrella'
          }
        }
      }
    }.to raise_error("Cheese must have a color")
  end

  it "can array a DSL with arguments" do
    dsl_class = Class.new(DSL::Maker) do
      cheese_dsl = generate_dsl({
        :type => String,
        :color => String,
      }) do |*args|
        default(:type, args, 0)
        Structs::Cheese.new(type, color)
      end

      add_entrypoint(:pizza, {
        :cheeses => DSL::Maker::ArrayOf[cheese_dsl],
        :cheese => DSL::Maker::AliasOf(:cheeses),
      }) {
        Structs::Pizza.new(cheeses)
      }
    end

    pizza = dsl_class.execute_dsl {
      pizza {
        cheese 'mozzarrella' do
          color 'white'
        end
        cheese 'cheddar' do
          color 'orange'
        end
      }
    }
    verify_pizza(pizza, :cheese => [
      Structs::Cheese.new('mozzarrella', 'white'),
      Structs::Cheese.new('cheddar', 'orange'),
    ])
  end
end
