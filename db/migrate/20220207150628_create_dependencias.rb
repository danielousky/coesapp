class CreateDependencias < ActiveRecord::Migration[5.2]
  def change
    create_table :dependencias, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
      t.references :asignatura, index: true, type: :string, null: false
      t.string :asignatura_dependiente_id, index: true, null: false
      t.timestamps
    end
    add_foreign_key :dependencias, :asignaturas, index: true
    add_foreign_key :dependencias, :asignaturas, index: true, column: :asignatura_dependiente_id
  end
end
