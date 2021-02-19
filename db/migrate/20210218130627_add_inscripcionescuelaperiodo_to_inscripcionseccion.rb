class AddInscripcionescuelaperiodoToInscripcionseccion < ActiveRecord::Migration[5.2]
  def change
    add_reference :inscripcionsecciones, :inscripcionescuelaperiodo, index: true
    add_foreign_key :inscripcionsecciones, :inscripcionescuelaperiodos, on_update: :cascade, on_delete: :cascade
  end
end
