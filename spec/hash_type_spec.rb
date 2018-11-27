# This is to test the Hash type.

describe 'Hash type' do
  context 'as an element' do
    let (:dsl_class) {
      Class.new(DSL::Maker) do
        add_entrypoint(:person, {
          :name => String,
          :tags => Hash,
        }) do
          Structs::Taggable.new(name, tags)
        end
      end
    }

    it "can handle an empty hash" do
      person = dsl_class.parse_dsl('person { name "Tom" }')[0]
      expect(person).to be_instance_of(Structs::Taggable)
      expect(person.name).to eq('Tom')
      expect(person.tags).to eq(nil)
    end

    it "can handle a single item" do
      person = dsl_class.parse_dsl('
        person {
          name "Tom"
          tags {
            foo "bar"
          }
        }
      ')[0]
      expect(person).to be_instance_of(Structs::Taggable)
      expect(person.name).to eq('Tom')
      expect(person.tags).to eq({ 'foo' => 'bar' })
    end

    it "can handle multiple item" do
      person = dsl_class.parse_dsl('
        person {
          name "Tom"
          tags {
            foo "item1"
            bar "item2"
          }
        }
      ')[0]
      expect(person).to be_instance_of(Structs::Taggable)
      expect(person.name).to eq('Tom')
      expect(person.tags).to eq({ 'foo' => 'item1', 'bar' => 'item2' })
    end
  end
end
