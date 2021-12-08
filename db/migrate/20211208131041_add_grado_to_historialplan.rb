class AddGradoToHistorialplan < ActiveRecord::Migration[5.2]
  def change
    add_column :historialplanes, :grado_id, :bigint
    add_foreign_key :historialplanes, :grados, on_delete: :cascade,  on_update: :cascade
    Historialplan.update_all("historialplanes.grado_id = (SELECT grados.id FROM grados WHERE escuela_id = historialplanes.escuela_id AND estudiante_id = historialplanes.estudiante_id LIMIT 1)")
  end
end
