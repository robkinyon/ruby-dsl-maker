# This will use a DSL that defines $Cars

describe "A DSL describing cars used with multiple invocations" do
  $Car = Struct.new(:maker)
  $Truck = Struct.new(:maker)

  it "returns two items in the right order" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
      }) do
        $Car.new(maker)
      end
    end

    cars = dsl_class.parse_dsl("
      car { maker 'Honda' }
      car { maker 'Acura' }
    ")
    expect(cars).to be_instance_of(Array)
    expect(cars.length).to eq(2)
    expect(cars[0]).to be_instance_of($Car)
    expect(cars[0].maker).to eq('Honda')
    expect(cars[1]).to be_instance_of($Car)
    expect(cars[1].maker).to eq('Acura')
  end

  it "returns items from different entrypoints in the right order" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
      }) do
        $Car.new(maker)
      end
      add_entrypoint(:truck, {
        :maker => String,
      }) do
        $Truck.new(maker)
      end
    end

    vehicles = dsl_class.parse_dsl("
      truck { maker 'Ford' }
      car { maker 'Honda' }
      truck { maker 'Toyota' }
    ")
    expect(vehicles).to be_instance_of(Array)
    expect(vehicles.length).to eq(3)
    expect(vehicles[0]).to be_instance_of($Truck)
    expect(vehicles[0].maker).to eq('Ford')
    expect(vehicles[1]).to be_instance_of($Car)
    expect(vehicles[1].maker).to eq('Honda')
    expect(vehicles[2]).to be_instance_of($Truck)
    expect(vehicles[2].maker).to eq('Toyota')
  end

  it "does all the same things with execute_dsl" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
      }) do
        $Car.new(maker)
      end
      add_entrypoint(:truck, {
        :maker => String,
      }) do
        $Truck.new(maker)
      end
    end

    vehicles = dsl_class.execute_dsl do
      truck { maker 'Ford' }
      car { maker 'Honda' }
      truck { maker 'Toyota' }
    end
    expect(vehicles).to be_instance_of(Array)
    expect(vehicles.length).to eq(3)
    expect(vehicles[0]).to be_instance_of($Truck)
    expect(vehicles[0].maker).to eq('Ford')
    expect(vehicles[1]).to be_instance_of($Car)
    expect(vehicles[1].maker).to eq('Honda')
    expect(vehicles[2]).to be_instance_of($Truck)
    expect(vehicles[2].maker).to eq('Toyota')
  end
end
