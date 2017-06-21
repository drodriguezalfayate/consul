class GestionUsuarioCreadoPor < ActiveRecord::Migration
  def change
    add_column :users, :created_by, :integer, :default => null, :null => true
  end
end
