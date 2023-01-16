class AddForzarAbsolutaToAsignatura < ActiveRecord::Migration[5.2]
  def change
    add_column :asignaturas, :forzar_absoluta, :boolean, default: false
  end
end
