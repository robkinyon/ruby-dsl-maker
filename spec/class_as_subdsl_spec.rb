# This is testing the ability to pass a class into generate_dsl and it
# does the right thing.

describe "Passing a class into generate_dsl" do
  $Car = Struct.new(:maker, :wheel)
  $Wheel = Struct.new(:maker, :size)

  it "can do it" do
    wheel_dsl = Class.new(DSL::Maker) do
      add_entrypoint(:wheel, {
        :size => String,
        :maker => String,
      }) do |*args|
        default(:maker, args, 0)
        $Wheel.new(maker, size)
      end
    end

    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
        :wheel => wheel_dsl.entrypoint(:wheel),
      }) do |*args|
        default(:maker, args, 0)
        $Car.new(maker, wheel)
      end
    end

    car = dsl_class.execute_dsl do
      car 'honda' do
        wheel 'goodyear' do
          size 26
        end
      end
    end
    expect(car).to be_instance_of($Car)
    expect(car.maker).to eq('honda')
    expect(car.wheel).to be_instance_of($Wheel)
    expect(car.wheel.maker).to eq('goodyear')
    expect(car.wheel.size).to eq('26')
  end

  # This ensures that if we create multiple entrypoints with the same name, they
  # won't tramp on each other.
  it "will not tramp on the entrypoints with the same name" do
    wheel_dsl = Class.new(DSL::Maker) do
      add_entrypoint(:wheel, {
        :size => String,
        :maker => String,
      }) do |*args|
        default(:maker, args, 0)
        $Wheel.new(maker, size)
      end
    end

    other_wheel_dsl = Class.new(DSL::Maker) do
      add_entrypoint(:wheel, {}) { nil }
    end

    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
        :wheel => wheel_dsl.entrypoint(:wheel),
      }) do |*args|
        default(:maker, args, 0)
        $Car.new(maker, wheel)
      end
    end

    car = dsl_class.execute_dsl do
      car 'honda' do
        wheel 'goodyear' do
          size 26
        end
      end
    end
    expect(car).to be_instance_of($Car)
    expect(car.maker).to eq('honda')
    expect(car.wheel).to be_instance_of($Wheel)
    expect(car.wheel.maker).to eq('goodyear')
    expect(car.wheel.size).to eq('26')
  end
end
