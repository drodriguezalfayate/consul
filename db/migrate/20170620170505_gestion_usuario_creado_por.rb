class GestionUsuarioCreadoPor < ActiveRecord::Migration
  def change
    add_column :users, :created_by, :integer, :default => nil, :null => true
  end
end
