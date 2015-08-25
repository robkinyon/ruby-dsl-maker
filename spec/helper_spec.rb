# This uses a DSL that also provides a set of useful helpers.
#
describe 'A DSL with helpers' do
  context '#add_helper' do
    it "can add a helper that's useful" do
      dsl_class = Class.new(DSL::Maker) do
        add_entrypoint(:car, {
          :maker => String,
        }) do
          Structs::Car.new(maker)
        end

        add_helper(:transform) do |name|
          name.upcase
        end
      end

      car = dsl_class.parse_dsl("
        car {
          maker transform('Honda')
        }
      ")[0]
      expect(car).to be_instance_of(Structs::Car)
      expect(car.maker).to eq('HONDA')
    end

    it 'adds the helper to every level' do
      dsl_class = Class.new(DSL::Maker) do
        add_entrypoint(:car, {
          :maker => String,
          :wheel => generate_dsl({
            :maker => String,
          }) do
            Structs::Wheel.new(maker)
          end
        }) do
          Structs::Car.new(maker, wheel)
        end

        add_helper(:transform) do |name|
          name.upcase
        end
      end

      car = dsl_class.parse_dsl("
        car {
          maker 'Honda'
          wheel {
            maker transform('goodyear')
          }
        }
      ")[0]
      expect(car).to be_instance_of(Structs::Car)
      expect(car.maker).to eq('Honda')
      expect(car.wheel).to be_instance_of(Structs::Wheel)
      expect(car.wheel.maker).to eq('GOODYEAR')
    end
  end

  context '#remove_helper' do
    it 'can remove a helper' do
      dsl_class = Class.new(DSL::Maker) do
        add_entrypoint(:car, {
          :maker => String,
        }) do
          Structs::Car.new(maker)
        end

        remove_helper(:default)
        add_helper(:default) do |name|
          name.upcase
        end
      end

      car = dsl_class.parse_dsl("
        car {
          maker default('Honda')
        }
      ")[0]
      expect(car).to be_instance_of(Structs::Car)
      expect(car.maker).to eq('HONDA')
    end
  end
end
