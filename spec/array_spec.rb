# This will use a DSL that creates a list of tasks

describe "A DSL with an array" do
  TaskList = Struct.new(:tasks)

  it 'can take an array' do
    dsl_class = Class.new(DSL::Maker) do
      add_entrypoint(:tasklist, {
        :item => Array,
      }) do
        TaskList.new(item)
      end
    end

    tasklist = dsl_class.parse_dsl("tasklist { item 'step 1' }")
    expect(tasklist).to be_instance_of(TaskList)
    expect(tasklist.tasks).to eq(['step 1'])
  end
end
