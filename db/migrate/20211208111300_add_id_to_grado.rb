class AddIdToGrado < ActiveRecord::Migration[5.2]
  def change
    add_column :grados, :id, :bigint, null: false, primary_key: true, auto_increment: true, unique: true

  end
end
