# This will use a DSL that defines fruit

describe "A DSL with argument handling describing fruit" do
  describe "with one argument in add_entrypoint" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:fruit, {
        :name => String,
      }) do |*args|
        default(:name, args, 0)
        Structs::Fruit.new(name, nil)
      end
    end

    it "can handle nil" do
      fruit = dsl_class.parse_dsl("
        fruit
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to be_nil
    end

    it "can handle the name in the attribute" do
      fruit = dsl_class.parse_dsl("
        fruit { name 'banana' }
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
    end

    it "can handle the name in the args" do
      fruit = dsl_class.parse_dsl("
        fruit 'banana'
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
    end

    it "can handle setting the name in both" do
      fruit = dsl_class.parse_dsl("
        # Minions don't get to name fruit
        fruit 'buh-nana!' do
          name 'banana'
        end
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
    end
  end

  describe "with two arguments in add_entrypoint" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:fruit, {
        :name => String,
        :color => String,
      }) do |*args|
        default('name', args)
        default('color', args, 1)

        Structs::Fruit.new(name, color)
      end
    end

    it "can handle no arguments" do
      fruit = dsl_class.parse_dsl("
        fruit
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to be_nil
      expect(fruit.color).to be_nil
    end

    it "can handle the name in args, color in attributes" do
      # Must use parentheses if you want to curly-braces
      fruit = dsl_class.parse_dsl("
        fruit('banana') {
          color 'yellow'
        }
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
      expect(fruit.color).to eq('yellow')

      # Must use do..end syntax if you want to avoid parentheses
      fruit = dsl_class.parse_dsl("
        fruit 'plantain' do
          color 'green'
        end
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('plantain')
      expect(fruit.color).to eq('green')
    end

    it "can handle everything in the args" do
      fruit = dsl_class.parse_dsl("
        fruit 'banana', 'yellow'
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
      expect(fruit.color).to eq('yellow')
    end
  end

  describe "with one argument in generate_dsl" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:fruit, {
        :name => String,
        :color => generate_dsl({
          :name => String,
        }) { |*args|
          default('name', args, 0)
          Structs::Color.new(name)
        }
      }) do |*args|
        default('name', args, 0)
        Structs::Fruit.new(name, color)
      end
    end

    it "can handle arguments for fruit, but attribute for color" do
      fruit = dsl_class.parse_dsl("
        fruit 'banana' do
          color {
            name 'yellow'
          }
        end
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
      expect(fruit.color).to be_instance_of(Structs::Color)
      expect(fruit.color.name).to eq('yellow')
    end

    it "can handle arguments for both fruit and color" do
      fruit = dsl_class.parse_dsl("
        fruit 'banana' do
          color 'yellow'
        end
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
      expect(fruit.color).to be_instance_of(Structs::Color)
      expect(fruit.color.name).to eq('yellow')
    end

    it "can handle arguments for both fruit and color" do
      fruit = dsl_class.parse_dsl("
        fruit 'banana' do
          color 'yellow' do
            name 'green'
          end
        end
      ")
      expect(fruit).to be_instance_of(Structs::Fruit)
      expect(fruit.name).to eq('banana')
      expect(fruit.color).to be_instance_of(Structs::Color)
      expect(fruit.color.name).to eq('green')
    end
  end
end
