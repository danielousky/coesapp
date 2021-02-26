class CreateInscripcionescuelaperiodos < ActiveRecord::Migration[5.2]
  def change

    create_table :inscripcionescuelaperiodos, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :estudiante, type: :string, null: false
      t.references :escuelaperiodo, null: false
      t.references :tipo_estado_inscripcion, type: :string
      t.references :reportepago, foreign_key: {on_delete: :nullify, on_update: :cascade}
      t.index [:estudiante_id, :escuelaperiodo_id], unique: true, name: 'index_inscripciones_on_estudiante_id_and_escuelaperiodo_id'
      t.timestamps
 
    end
    add_foreign_key :inscripcionescuelaperiodos, :estudiantes, primary_key: :usuario_id, on_delete: :cascade,  on_update: :cascade
    add_foreign_key :inscripcionescuelaperiodos, :tipo_estado_inscripciones, on_delete: :cascade,  on_update: :cascade
    add_foreign_key :inscripcionescuelaperiodos, :escuelaperiodos, on_delete: :cascade,  on_update: :cascade
  end
end
