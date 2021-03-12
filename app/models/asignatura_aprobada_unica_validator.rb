class AsignaturaAprobadaUnicaValidator < ActiveModel::Validator
  def validate(record)
    if asignatura_aprobada(record)
      record.errors.add 'La asignatura', 'ya fue aprobada.'
    end
  end

  private
    def asignatura_aprobada(record)
      record.grado.inscripciones.joins(:asignatura).del_estudiante(record.estudiante_id).aprobadas.where("asignaturas.id = #{record.asignatura.id}").any?      
    end
end