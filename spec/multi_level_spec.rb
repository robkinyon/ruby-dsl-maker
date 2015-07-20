# This will use a DSL that parses a family tree.
#
# Notes:
# 1. Because we're creating classes on the fly, we must fully-qualify the Boolean
# class name. If we created real classes, the context would be provided for us.
describe 'A multi-level DSL making family-trees' do
  Person = Struct.new(:name, :child)

  it "can handle a simple single-level parse of a two-level DSL" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:person, {
        :name => String,
        :child => generate_dsl({
          :name => String,
        }) {
          Person.new(name)
        },
      }) do
        Person.new(name, child)
      end
    end

    person = dsl_class.parse_dsl('person { name "Tom" }')
    expect(person).to be_instance_of(Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it "can handle a two-level parse of a two-level DSL" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:person, {
        :name => String,
        :child => generate_dsl({
          :name => String,
        }) {
          Person.new(name, nil)
        },
      }) do
        Person.new(name, child)
      end
    end

    person = dsl_class.parse_dsl("
      person {
        name 'Tom'
        child {
          name 'Bill'
        }
      }
    ")
    expect(person).to be_instance_of(Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_instance_of(Person)
    expect(person.child.name).to eq('Bill')
  end

  it "can handle a three-level parse of a three-level DSL" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:person, {
        :name => String,
        :child => generate_dsl({
          :name => String,
          :child => generate_dsl({
            :name => String,
          }) {
            Person.new(name, nil)
          },
        }) {
          Person.new(name, child)
        },
      }) do
        Person.new(name, child)
      end
    end

    person = dsl_class.parse_dsl("
      person {
        name 'Tom'
        child {
          name 'Bill'
          child {
            name 'Judith'
          }
        }
      }
    ")
    expect(person).to be_instance_of(Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_instance_of(Person)
    expect(person.child.name).to eq('Bill')
    expect(person.child.child).to be_instance_of(Person)
    expect(person.child.child.name).to eq('Judith')
  end
end
