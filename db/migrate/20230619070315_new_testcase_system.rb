class NewTestcaseSystem < ActiveRecord::Migration[7.0]
  def change
    create_table :data_sets do |t|
      t.references :problem
      t.string  :name
      t.decimal :time_limit, default: 1, precision: 10, scale: 2
      t.integer :memory_limit
      t.integer :task_type, limit: 1
      t.integer :score_type, limit: 1
      t.integer :compilation_type, limit: 1
      t.integer :evaluation_type, limit: 1
      t.string  :score_param
    end

    create_table :evaluations do |t|
      t.references :submission
      t.references :testcase
      t.integer :result
      t.integer :time
      t.integer :memory
      t.decimal :score, precision: 10, scale: 2
    end

    add_reference :testcases, :data_set
    add_column :testcases, :group_name, :string
    add_column :testcases, :code_name, :string
    add_reference :problems, :live_data_set
    add_reference :submissions, :data_set, index: false
    add_column :submissions, :status, :integer, limit: 1, default: 0

  end
end