class Reportepago < ApplicationRecord

  has_one :inscripcionescuelaperiodo
  has_one :grado 

  has_one :periodo, through: :inscripcionescuelaperiodo

  belongs_to :banco_origen, foreign_key: 'banco_origen_id', class_name: 'Banco'
  
  validates :numero, presence: true
  # La validación debajo no aplica ya que primero se guarda el reporte y luego se asocia al objeto has_one, en este caso el inscripcionescuelaperiodo 
  # validates_with UnicoNumeroTransPorPeriodoValidator
  validates :monto, presence: true
  validates :tipo_transaccion, presence: true
  validates :fecha_transaccion, presence: true
  validates :banco_origen_id, presence: true

  enum tipo_transaccion: ['transferencia', 'deposito']

  has_one_attached :respaldo

  def monto_con_formato
    ActionController::Base.helpers.number_to_currency(self.monto, unit: 'Bs.', separator: ",", delimiter: ".")
  end

  def descripcion

  	aux = "#{self.numero} x (#{monto_con_formato}) del #{self.banco_origen.nombre}"
  end

end
