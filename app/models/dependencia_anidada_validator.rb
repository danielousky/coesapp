class DependenciaAnidadaValidator < ActiveModel::Validator
  def validate(record)
    if dependencia_anidada(record)
      record.errors.add "Prelación #{record.id}", 'anidada.'
    end
  end

  private
    def dependencia_anidada(record)
      record.asignatura.arbol_completo_dependencias.include? record.asignatura_dependiente_id      
    end
end