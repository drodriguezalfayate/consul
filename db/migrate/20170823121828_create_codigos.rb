class CreateCodigos < ActiveRecord::Migration
  def change
    create_table :codigos do |t|
      t.string :clave
      t.string :valor

    end
    add_index :codigos, :clave
  end
end
