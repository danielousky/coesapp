class AddVirtualToBloquehorario < ActiveRecord::Migration[5.2]
  def change
    add_column :bloquehorarios, :modalidad, :integer, default: 0
  end
end
