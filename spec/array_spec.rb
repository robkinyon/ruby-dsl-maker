# This will use a DSL that creates a list of tasks

describe "A DSL with an array" do
  TaskList = Struct.new(:tasks)

  dsl_class = Class.new(DSL::Maker) do
    add_entrypoint(:tasklist, {
      :item => Array,
    }) do
      TaskList.new(item)
    end
  end

  it 'can take a single item' do
    tasklist = dsl_class.parse_dsl("tasklist { item 'step 1' }")
    expect(tasklist).to be_instance_of(TaskList)
    expect(tasklist.tasks).to eq(['step 1'])
  end

  it 'can take entries from multiple items in order' do
    tasklist = dsl_class.parse_dsl("
      tasklist {
        item 'step 1'
        item 'step 2'
      }
    ")
    expect(tasklist).to be_instance_of(TaskList)
    expect(tasklist.tasks).to eq(['step 1', 'step 2'])
  end

  it 'can take multiple entries from the same item' do
    tasklist = dsl_class.parse_dsl("
      tasklist {
        item 'step 1', 'step 2'
      }
    ")
    expect(tasklist).to be_instance_of(TaskList)
    expect(tasklist.tasks).to eq(['step 1', 'step 2'])
  end
end
