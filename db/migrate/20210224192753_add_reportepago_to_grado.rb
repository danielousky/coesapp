class AddReportepagoToGrado < ActiveRecord::Migration[5.2]
  def change
  	add_reference :grados, :reportepago, index: true
	add_foreign_key :grados, :reportepagos, on_delete: :nullify,  on_update: :cascade 
  end
end
