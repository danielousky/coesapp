class AddAutorizadaInscripcionToGrado < ActiveRecord::Migration[5.2]
  def change
  	add_column :grados, :autorizar_inscripcion_en_periodo_id, :string
  end
end
