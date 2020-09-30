class AddPerfilToAdministrador < ActiveRecord::Migration[5.2]
  def change
  	add_reference :administradores, :perfil, foreign_key: true
  end
end
