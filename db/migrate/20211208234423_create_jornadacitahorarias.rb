class CreateJornadacitahorarias < ActiveRecord::Migration[5.2]
  def change
    create_table :jornadacitahorarias do |t|
      t.references :escuelaperiodo, foreign_key: true
      t.datetime :inicio
      t.integer :duracion_total_horas, limit: 1
      t.integer :max_grados, limit: 2
      t.integer :duracion_franja_minutos, limit: 1

      t.timestamps
    end
  end
end
