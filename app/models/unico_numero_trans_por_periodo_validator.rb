class UnicoNumeroTransPorPeriodoValidator < ActiveModel::Validator
  def validate(record)
    if record.periodo and (record.periodo.reportepagos.map{|rp| rp.numero}.include? record.numero)
      record.errors.add 'El número', 'de transacción debe ser único para la inscripción'
    end
  end

  # private
  #   def numero_transaccion_duplicado(record)
  #     record.periodo and (record.periodo.reportepagos.map{|rp| rp.numero}.include? record.numero) ? true : false
  #   end
end