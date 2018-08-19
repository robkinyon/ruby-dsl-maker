# All of the functions and methods in this spec have to be named differently
# because all of these DSLs are being parsed into the same global namespace.

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
        def my_name1
          'Tom'
        end
        name my_name1
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it 'can call a function outside the DSL' do
    person = dsl_class.parse_dsl("
      def my_name2
        'Tom'
      end
      person {
        name my_name2
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it 'can call a function in a parent block' do
    person = dsl_class.parse_dsl("
      person {
        def my_name3
          'Tom'
        end
        name 'Bill'
        child {
          name my_name3
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Tom')
  end

  it 'can call a function from a child outside the DSL' do
    person = dsl_class.parse_dsl("
      def my_name4
        'Tom'
      end
      person {
        name 'Bill'
        child {
          name my_name4
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
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
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('TOM')
  end
end

describe 'Methods in the DSL' do
  dsl_class = Class.new(DSL::Maker) do
    add_entrypoint(:person, {
      :name => String,
      :child => generate_dsl({
        :name => String,
        :child => generate_dsl({
          :name => String,
          :child => generate_dsl({
            :name => String,
          }) {
            Structs::Person.new(name)
          },
        }) {
          Structs::Person.new(name, child)
        },
      }) {
        Structs::Person.new(name, child)
      },
    }) do
      Structs::Person.new(name, child)
    end
  end

  it 'can call a method in the block' do
    person = dsl_class.parse_dsl("
      person {
        def foo1
          name 'Tom'
        end
        foo1
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it 'can call a method outside the DSL' do
    person = dsl_class.parse_dsl("
      def foo2
        name 'Tom'
      end
      person {
        foo2
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Tom')
    expect(person.child).to be_nil
  end

  it 'can call a method in a parent block' do
    person = dsl_class.parse_dsl("
      person {
        def foo3
          name 'Tom'
        end
        name 'Bill'
        child {
          foo3
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Tom')
  end

  it 'can call a method from a child outside the DSL' do
    person = dsl_class.parse_dsl("
      def foo4
        name 'Tom'
      name end
      person {
        name 'Bill'
        child {
          foo4
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Tom')
  end

  xit 'can call a method in a grandparent block (base)' do
    person = dsl_class.parse_dsl("
      person {
        puts \"B1: \#{self} '\#{self.name}'\"
        def foo5
          puts \"F1: \#{self} '\#{self.name}'\"
          name 'Tom'
          puts \"F2: \#{self} '\#{self.name}'\"
        end
        puts \"B2: \#{self} '\#{self.name}'\"
        name 'Bill'
        puts \"B3: \#{self} '\#{self.name}'\"
        child {
          puts \"S1: \#{self} '\#{self.name}'\"
          name 'Sarah'
          puts \"S2: \#{self} '\#{self.name}'\"
          child {
            puts \"T1: \#{self} '\#{self.name}'\"
            foo5
            #self.class.instance_method(:foo5).bind(self).call()
            puts \"T2: \#{self} '\#{self.name}'\"
          }
          puts \"S3: \#{self} '\#{self.name}'\"
        }
        puts \"B4: \#{self} '\#{self.name}'\"
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Sarah')
    expect(person.child.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Tom')
  end

  xit 'can call a method in a grandparent block (non-base)' do
    person = dsl_class.parse_dsl("
      person {
        puts \"B1: \#{self} '\#{self.name}'\"
        name 'Bill'
        puts \"B2: \#{self} '\#{self.name}'\"
        child {
          puts \"S1: \#{self} '\#{self.name}'\"
          def foo5
            puts \"F1: \#{self} '\#{self.name}'\"
            name 'Tom'
            puts \"F2: \#{self} '\#{self.name}'\"
          end
          puts \"S2: \#{self} '\#{self.name}'\"
          name 'Sarah'
          puts \"S3: \#{self} '\#{self.name}'\"
          child {
            puts \"J1: \#{self} '\#{self.name}'\"
            name 'Jill'
            puts \"J2: \#{self} '\#{self.name}'\"
            child {
              puts \"T1: \#{self} '\#{self.name}'\"
              foo5
              puts \"T2: \#{self} '\#{self.name}'\"
            }
            puts \"J3: \#{self} '\#{self.name}'\"
          }
          puts \"S4: \#{self} '\#{self.name}'\"
        }
        puts \"B3: \#{self} '\#{self.name}'\"
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Sarah')
    expect(person.child.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Jill')
    expect(person.child.child.child).to be_instance_of(Structs::Person)
    expect(person.child.child.child.name).to eq('Tom')
  end

  it 'can call a method from a grandchild outside the DSL' do
    person = dsl_class.parse_dsl("
      def foo6
        name 'Tom'
      end
      person {
        name 'Bill'
        child {
          name 'Sarah'
          child {
            foo6
          }
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Sarah')
    expect(person.child.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Tom')
  end

  # This is also failing because of https://github.com/ms-ati/docile/issues/31
  xit 'can call a method from a grandchild outside the DSL (name after)' do
    person = dsl_class.parse_dsl("
      def foo6
        name 'Tom'
      end
      person {
        name 'Bill'
        child {
          child {
            foo6
          }
          name 'Sarah'
        }
      }
    ")[0]
    expect(person).to be_instance_of(Structs::Person)
    expect(person.name).to eq('Bill')
    expect(person.child).to be_instance_of(Structs::Person)
    expect(person.child.name).to eq('Sarah')
    expect(person.child.child).to be_instance_of(Structs::Person)
    expect(person.child.child.name).to eq('Tom')
  end
end
