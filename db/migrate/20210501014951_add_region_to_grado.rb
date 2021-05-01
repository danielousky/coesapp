class AddRegionToGrado < ActiveRecord::Migration[5.2]
  def change
    add_column :grados, :region, :integer, default: 0, null: false
  end
end
