class AddGradoToInscripcionseccion < ActiveRecord::Migration[5.2]
  def change
    add_column :inscripcionsecciones, :grado_id, :bigint
    add_foreign_key :inscripcionsecciones, :grados, on_delete: :cascade,  on_update: :cascade
    Inscripcionseccion.update_all("inscripcionsecciones.grado_id = (SELECT grados.id FROM grados WHERE escuela_id = inscripcionsecciones.escuela_id AND estudiante_id = inscripcionsecciones.estudiante_id LIMIT 1)")

  end
end
