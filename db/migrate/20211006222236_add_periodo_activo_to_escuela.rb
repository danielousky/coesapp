class AddPeriodoActivoToEscuela < ActiveRecord::Migration[5.2]
  def change
    add_column :escuelas, :periodo_activo_id, :string, index: true
    add_foreign_key :escuelas, :periodos, on_delete: :nullify,  on_update: :cascade, column: "periodo_activo_id"

  end
end
