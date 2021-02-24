class AddBancoToReportepago < ActiveRecord::Migration[5.2]
  def change
    add_column :reportepagos, :banco_origen_id, :string, index: true
    add_foreign_key :reportepagos, :bancos, on_delete: :cascade,  on_update: :cascade, column: :banco_origen_id

  end
end
