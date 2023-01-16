class ChangeMontoToReportepago < ActiveRecord::Migration[5.2]
  def change
    change_column :reportepagos, :monto, :float, precision: 8, scale: 2
  end
end
