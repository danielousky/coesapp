class CreateBancos < ActiveRecord::Migration[5.2]
  def change
    create_table :bancos, id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8"  do |t|
      t.string :id, null: false, primary_key: true, index: true  
      t.string :nombre

      t.timestamps
    end

  end


end
