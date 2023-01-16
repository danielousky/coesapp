class AddMaxCreditosAndMaxAsignaturasToEscuelaperiodo < ActiveRecord::Migration[5.2]
  def change
    add_column :escuelaperiodos, :max_creditos, :integer, default: 24
    add_column :escuelaperiodos, :max_asignaturas, :integer, default: 3
  end
end
