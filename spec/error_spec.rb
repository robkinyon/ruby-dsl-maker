# This verifies the various error-handling situations.

describe "DSL::Maker validation" do
  it "requires a block for :add_entrypoint" do
    expect {
      Class.new(DSL::Maker) do
        add_entrypoint(:pizza)
      end
    }.to raise_error('Block required for add_entrypoint')
  end
end
