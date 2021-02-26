class CreateReportepagos < ActiveRecord::Migration[5.2]
  def change
    create_table :reportepagos, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8"  do |t|      
      t.string :numero
      t.decimal :monto
      t.integer :tipo_transaccion
      t.date :fecha_transaccion

      t.timestamps
    end
  end
end
