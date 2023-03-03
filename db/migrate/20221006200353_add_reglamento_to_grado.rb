class AddReglamentoToGrado < ActiveRecord::Migration[5.2]
  def change
    add_column :grados, :reglamento, :integer, default: 0, null: false
  end
end
