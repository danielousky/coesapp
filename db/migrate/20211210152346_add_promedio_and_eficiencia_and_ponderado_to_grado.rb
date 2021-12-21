class AddPromedioAndEficienciaAndPonderadoToGrado < ActiveRecord::Migration[5.2]
  def change
    add_column :grados, :eficiencia, :decimal, precision: 4, scale: 2, default: 0.0, null: false
    add_column :grados, :promedio_simple, :decimal, precision: 4, scale: 2, default: 0.0, null: false
    add_column :grados, :promedio_ponderado, :decimal, precision: 4, scale: 2, default: 0.0, null: false
    add_column :grados, :citahoraria, :datetime

    Grado.all.map{|gr| gr.update(eficiencia: gr.calcular_eficiencia, promedio_simple: gr.calcular_promedio_simple, promedio_ponderado: gr.calcular_promedio_ponderado)}

    # esc.grados.where(eficiencia: 0.0, promedio_simple: 0.0, promedio_ponderado: 0.0).map{|gr| gr.update(eficiencia: gr.calcular_eficiencia, promedio_simple: gr.calcular_promedio_simple, promedio_ponderado: gr.calcular_promedio_ponderado)}
    
    # add_column :grados, :jornadacitahoraria_id, :bigint
    # add_foreign_key :grados, :jornadacitahorarias, on_delete: :nullify,  on_update: :cascade
  end
end
