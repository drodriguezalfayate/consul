class AddLongDescriptionHeadings < ActiveRecord::Migration
  def change
    add_column :budget_headings, :long_name, :string, :limit => 1000
  end
end
