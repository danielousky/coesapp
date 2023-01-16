class Dependencia < ApplicationRecord
  belongs_to :asignatura
  belongs_to :asignatura_dependiente, class_name: 'Asignatura', foreign_key: 'asignatura_dependiente_id'

  before_destroy :destroy_dependientes

  validates_uniqueness_of :asignatura_id, scope: [:asignatura_dependiente_id], message: 'la relación ya existe', field_name: false

  def destroy_dependientes
    asignatura_dependiente.dependencias.destroy_all
  end

end
