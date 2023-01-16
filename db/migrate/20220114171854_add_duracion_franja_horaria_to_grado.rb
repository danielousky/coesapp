class AddDuracionFranjaHorariaToGrado < ActiveRecord::Migration[5.2]
  def change
    add_column :grados, :duracion_franja_horaria, :integer    
  end
end
