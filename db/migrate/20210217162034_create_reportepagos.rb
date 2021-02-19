class CreateReportepagos < ActiveRecord::Migration[5.2]
  def change
    create_table :reportepagos do |t|
      t.references :inscripcionescuelaperiodo, null: false, foreign_key: {on_delete: :cascade, on_update: :cascade}
      
      t.string :numero
      t.integer :tipo_transaccion
      t.date :fecha_transaccion

      t.timestamps
    end
  end
end
