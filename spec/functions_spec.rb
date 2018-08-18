describe 'Functions in the DSL' do
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

  it 'can call a function in the block' do
    person = dsl_class.parse_dsl("
      person {
        def my_name
          'Tom'
        end
        name my_name
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it 'can call a function outside the DSL' do
    person = dsl_class.parse_dsl("
      def my_name
        'Tom'
      end
      person {
        name my_name
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it 'can call a function in a parent block' do
    person = dsl_class.parse_dsl("
      person {
        def my_name
          'Tom'
        end
        name 'Bill'
        child {
          name my_name
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Tom')
  end

  it 'can call a function from a child outside the DSL' do
    person = dsl_class.parse_dsl("
      def my_name
        'Tom'
      end
      person {
        name 'Bill'
        child {
          name my_name
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Tom')
  end
end

describe 'Including a module in the DSL' do
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

  it 'can call a module function in the block' do
    person = dsl_class.parse_dsl("
      require 'module1'
      person {
        name Mod1.up('tom')
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('TOM')
    expect(person.child).to be_nil
  end

  it 'can call a module function from the child' do
    person = dsl_class.parse_dsl("
      require 'module1'
      person {
        name 'Bill'
        child {
          name Mod1.up('tom')
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('TOM')
  end
end
