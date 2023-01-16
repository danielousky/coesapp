class AddActivarDependenciasToEscuela < ActiveRecord::Migration[5.2]
  def change
    add_column :escuelas, :habilitar_dependencias, :boolean, default: false
  end
end
