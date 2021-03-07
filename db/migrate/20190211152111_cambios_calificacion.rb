class CambiosCalificacion < ActiveRecord::Migration[5.2]
  def change
    add_column :secciones, :abierta, :boolean, default: true

    # change_column :secciones, :calificada, :boolean, default: false
	change_column_default :secciones, :calificada, from: nil, to: false
    
    add_column :inscripcionsecciones, :calificacion_posterior, :float
    add_column :inscripcionsecciones, :estado, :integer, default: 0, null: false
    
    add_column :inscripcionsecciones, :tipo_calificacion_id, :string, index: true

    # FALSO: Cuando se añade add_reference hace on_update: restrint. Aun cuando pasemos por parámetro on_update:nullify. En ese caso, se agrega add_column y add_foreign_key como se ve en este archivo
    # ACTUALIZACION DE COMENTARIO ARRIBA: El tema es que la referencia (add_reference) no crea la clave foránea. la Clave foránea se crea con add_foreign_key y es quien hace up_dated or on_delete por lo que el comentario anterior no es valido
    # add_reference :grados, :reportepago, index: true
    # add_foreign_key :grados, :reportepagos, on_delete: :nullify,  on_update: :cascade 
    # add_reference :inscripcionsecciones, :tipo_calificacion, foreign_key: true, type: :string, index: true, on_delete: :nullify,  on_update: :cascade
    add_foreign_key :inscripcionsecciones, :tipo_calificaciones, type: :string, on_delete: :nullify,  on_update: :cascade, index: true, foreign_key: :tipo_calificacion_id

  end
end
