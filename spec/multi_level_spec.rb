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

  it "can define things recursively" do
    # This really should be:
    #dsl_class = Class.new(DSL::Maker) do
    #  person_dsl = add_entrypoint(:person, {
    #    :name => String,
    #  }) do
    #    Person.new(name, child)
    #  end
    #  build_dsl_element(person_dsl, :child, person_dsl)
    #end
    # But, :child doesn't have access to &defn_block that was passed to
    # add_entrypoint().

    dsl_class = Class.new(DSL::Maker) do
      person = generate_dsl({
        :name => String,
      }) {
        Person.new(name, child)
      }
      build_dsl_element(person, :child, person)

      add_entrypoint(:person, person) do
        Person.new(name, child)
      end
    end

    # This is taken from https://en.wikipedia.org/wiki/Family_tree_of_the_Bible
    person = dsl_class.parse_dsl("
      person {
        name 'Adam'
        child {
          name 'Seth'
          child {
            name 'Enos'
            child {
              name 'Cainan'
              child {
                name 'Mahalaleel'
                child {
                  name 'Jared'
                  child {
                    name 'Enoch'
                    child {
                      name 'Methuselah'
                      child {
                        name 'Lamech'
                        child {
                          name 'Noah'
                          child {
                            name 'Shem'
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    ")

    [
      'Adam', 'Seth', 'Enos', 'Cainan', 'Mahalaleel', 'Jared',
      'Enoch', 'Methuselah', 'Lamech', 'Noah', 'Shem',
    ].each do |name|
      expect(person).to be_instance_of(Person)
      expect(person.name).to eq(name)
      person = person.child
    end
  end
end
