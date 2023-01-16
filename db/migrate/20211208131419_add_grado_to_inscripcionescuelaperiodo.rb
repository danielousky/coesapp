class AddGradoToInscripcionescuelaperiodo < ActiveRecord::Migration[5.2]
  def change
    add_column :inscripcionescuelaperiodos, :grado_id, :bigint
    add_foreign_key :inscripcionescuelaperiodos, :grados, on_delete: :cascade,  on_update: :cascade
    Inscripcionescuelaperiodo.joins(:escuela).update_all("inscripcionescuelaperiodos.grado_id = (SELECT grados.id FROM grados WHERE escuela_id = escuelas.id AND estudiante_id = inscripcionescuelaperiodos.estudiante_id LIMIT 1)")

  end
end
