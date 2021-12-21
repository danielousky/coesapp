class UnicoDiaCitaHorariaValidator < ActiveModel::Validator
  def validate(record)
    if record.escuelaperiodo.jornadacitahorarias.where("inicio LIKE '%#{record.inicio.strftime "%Y-%m-%d"}%'").any?
      record.errors.add 'Ya tiene una jornada horaria para el día especificado', ''
    end
  end

end