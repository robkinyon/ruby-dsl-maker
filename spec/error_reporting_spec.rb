# This verifies that DSL::Maker reports errors sanely

describe "DSL::Maker error reporting" do
  $Car = Struct.new(:maker, :wheel)

  it "reports bad entrypoints" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
      }) do
        $Car.new(maker)
      end
    end

    expect {
      dsl_class.parse_dsl('
        truck {}
      ')
    }.to raise_error("'truck' is not an entrypoint")
  end

  it "reports bad method names" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:car, {
        :maker => String,
      }) do
        $Car.new(maker)
      end
    end

    expect {
      dsl_class.parse_dsl('
        car {
          purple :yes
        }
      ')
    }.to raise_error("'purple' is not a method")
  end
end
