# This verifies the various error-handling situations.

describe "DSL::Maker validation" do
  it "requires a block for :generate_dsl" do
    expect {
      Class.new(DSL::Maker) do
        add_entrypoint(:first, {
          :second => generate_dsl({})
        }) {}
      end
    }.to raise_error('Block required for generate_dsl')
  end

  describe "for attributes" do
    it "requires a recognized type for attributes" do
      expect {
        Class.new(DSL::Maker) do
          add_entrypoint(:pizza, {
            :cheese => true,
          }) do
            Pizza.new(cheese, nil, nil, nil)
          end
        end
      }.to raise_error("Unrecognized element type 'true'")
    end

    it "rejects attributes which block Boolean helper methods" do
      %w(yes no on off __apply).each do |name|
        expect {
          Class.new(DSL::Maker) do
            add_entrypoint(:pizza, {
              name => String,
            }) do
              Pizza.new(cheese, nil, nil, nil)
            end
          end
        }.to raise_error("Illegal attribute name '#{name}'")
      end
    end
  end

  describe "for entrypoints" do
    it "requires a block for :add_entrypoint" do
      expect {
        Class.new(DSL::Maker) do
          add_entrypoint(:pizza)
        end
      }.to raise_error('Block required for add_entrypoint')
    end

    it "rejects re-using an entrypoint name in add_entrypoint()" do
      dsl_class = Class.new(DSL::Maker) do
        add_entrypoint(:x, {}) { nil }
      end
      expect {
        dsl_class.add_entrypoint(:x, {}) { nil }
      }.to raise_error("'x' is already an entrypoint")
    end

    it "rejects an entrypoint name that doesn't exist in entrypoint()" do
      dsl_class = Class.new(DSL::Maker)

      expect {
        dsl_class.entrypoint(:x)
      }.to raise_error("'x' is not an entrypoint")
    end
  end

  describe "for helpers" do
    it "rejects a helper without a block" do
      dsl_class = Class.new(DSL::Maker)

      expect {
        dsl_class.add_helper(:x)
      }.to raise_error('Block required for add_helper')
    end

    it "rejects the helper name default" do
      dsl_class = Class.new(DSL::Maker)

      expect {
        dsl_class.add_helper(:default) {}
      }.to raise_error("'default' is already a helper")
    end

    it "rejects a helper name already in use" do
      dsl_class = Class.new(DSL::Maker)
      dsl_class.add_helper(:x) {}

      expect {
        dsl_class.add_helper(:x) {}
      }.to raise_error("'x' is already a helper")
    end
  end

  describe "for type coercions" do
    it "rejects a type coercion without a block" do
      dsl_class = Class.new(DSL::Maker)

      expect {
        dsl_class.add_type(:x)
      }.to raise_error('Block required for add_type')
    end

    it "rejects a type coercion type already in use" do
      dsl_class = Class.new(DSL::Maker)

      expect {
        dsl_class.add_type(String) {}
      }.to raise_error("'String' is already a type coercion")
    end
  end
end
