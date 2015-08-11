# This will use a DSL that parses a family tree.
#
# Notes:
# 1. Because we're creating classes on the fly, we must fully-qualify the Boolean
# class name. If we created real classes, the context would be provided for us.
describe 'A multi-level DSL making family-trees' do
  it "can handle a simple single-level parse of a two-level DSL" do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:person, {
        :name => String,
        :child => generate_dsl({
          :name => String,
        }) {
          Structs::Person.new(name)
        },
      }) do
        Structs::Person.new(name, child)
      end
    end

    person = dsl_class.parse_dsl('person { name "Tom" }')[0]
    expect(person).to be_instance_of(Structs::Person)
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
          Structs::Person.new(name, nil)
        },
      }) do
        Structs::Person.new(name, child)
      end
    end

    person = dsl_class.parse_dsl("
      person {
        name 'Tom'
        child {
          name 'Bill'
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_instance_of(Structs::Person)
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
            Structs::Person.new(name, nil)
          },
        }) {
          Structs::Person.new(name, child)
        },
      }) do
        Structs::Person.new(name, child)
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
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Bill')
    expect(person.child.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Judith')
  end

  describe "with recursion" do
    it "can handle a single axis of recursion" do
      dsl_class = Class.new(DSL::Maker) do
        person_dsl = add_entrypoint(:person, {
          :name => String,
        }) do
          Structs::Person.new(name, child)
        end
        build_dsl_element(person_dsl, :child, person_dsl)
      end

      # This list of names is taken from
      # https://en.wikipedia.org/wiki/Family_tree_of_the_Bible
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
      ")[0]

      [
        'Adam', 'Seth', 'Enos', 'Cainan', 'Mahalaleel', 'Jared',
        'Enoch', 'Methuselah', 'Lamech', 'Noah', 'Shem',
      ].each do |name|
        expect(person).to be_instance_of(Structs::Person)
        expect(person.name).to eq(name)
        person = person.child
      end
    end

    it "can handle two axes of recursion" do
      dsl_class = Class.new(DSL::Maker) do
        person_dsl = add_entrypoint(:person, {
          :name => String,
        }) do
          Structs::OtherPerson.new(name, mother, father)
        end
        build_dsl_element(person_dsl, :mother, person_dsl)
        build_dsl_element(person_dsl, :father, person_dsl)
      end

      person = dsl_class.parse_dsl("
        person {
          name 'John Smith'
          mother {
            name 'Mary Smith'
          }
          father {
            name 'Tom Smith'
          }
        }
      ")[0]

      expect(person).to be_instance_of(Structs::OtherPerson)
      expect(person.name).to eq('John Smith')

      mother = person.mother
      expect(mother).to be_instance_of(Structs::OtherPerson)
      expect(mother.name).to eq('Mary Smith')

      father = person.father
      expect(father).to be_instance_of(Structs::OtherPerson)
      expect(father.name).to eq('Tom Smith')
    end
  end
end
