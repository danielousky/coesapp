<<<<<<< HEAD
class Dependencia < ApplicationRecord
  belongs_to :asignatura
  belongs_to :asignatura_dependiente, class_name: 'Asignatura', foreign_key: 'asignatura_dependiente_id'

  before_destroy :destroy_dependientes

  validates_uniqueness_of :asignatura_id, scope: [:asignatura_dependiente_id], message: 'la relación ya existe', field_name: false

  def destroy_dependientes
    asignatura_dependiente.dependencias.destroy_all
  end

end
=======
class Dependencia < ApplicationRecord
  belongs_to :asignatura
  belongs_to :asignatura_dependiente, class_name: 'Asignatura', foreign_key: 'asignatura_dependiente_id'

  # before_destroy :destroy_dependientes

  validates_uniqueness_of :asignatura_id, scope: [:asignatura_dependiente_id], message: 'la relación ya existe', field_name: false

  validates_with DependenciaAnidadaValidator, field_name: false

  # OJO: NO HACE FALTA PODAR TODO EL ARBOL DERIVADO DE DEPENDENCIAS, SOLO SE NECESITA ELIMINAR LA DEPENDENCIA DIRECTA.
  # def destroy_dependientes
  #   asignatura_dependiente.dependencias.destroy_all
  # end

end
>>>>>>> 7050be81cac4498c00dca402ed6e2dcdaed2406e
