# This uses a DSL that also provides a set of useful helpers.
#
describe "A DSL with helpers" do
  $Car = Struct.new(:maker, :wheel)
  $Wheel = Struct.new(:maker, :size)

  it "can add a helper that's useful" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
      }) do
        $Car.new(maker)
      end

      add_helper(:transform) do |name|
        name.upcase
      end
    end

    car = dsl_class.parse_dsl("
      car {
        maker transform('Honda')
      }
    ")
    expect(car).to be_instance_of($Car)
    expect(car.maker).to eq('HONDA')
  end

  # TODO: There is a wart here. We cannot call add_helper() twice in our tests
  # for the same name even in different specs. The specs should be able to reset
  # the class, but I'm not sure how.
  it "adds the helper to every level" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
        :wheel => generate_dsl({
          :maker => String,
        }) do
          $Wheel.new(maker)
        end
      }) do
        $Car.new(maker, wheel)
      end

      add_helper(:transform2) do |name|
        name.upcase
      end
    end

    car = dsl_class.parse_dsl("
      car {
        maker 'Honda'
        wheel {
          maker transform2('goodyear')
        }
      }
    ")
    expect(car).to be_instance_of($Car)
    expect(car.maker).to eq('Honda')
    expect(car.wheel).to be_instance_of($Wheel)
    expect(car.wheel.maker).to eq('GOODYEAR')
  end
end
