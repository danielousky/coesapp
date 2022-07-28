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


  scope :inscripciones_de_la_escuela, -> (escuela_id) {joins({inscripcionescuelaperiodo: :escuela}).where('escuelas.id = ?', escuela_id)}
  scope :grados_de_la_escuela, -> (escuela_id) {joins({grado: :escuela}).where('escuelas.id = ?', escuela_id)}

  scope :inscripciones_del_periodo, -> (periodo_id) {joins({inscripcionescuelaperiodo: {escuelaperiodo: :periodo}}).where('periodos.id = ?', periodo_id)} 


  def toDataTable
    {descripcion: objeto.descripcion}
  end

  def monto_con_formato
    ActionController::Base.helpers.number_to_currency(self.monto, unit: 'Bs.', separator: ",", delimiter: ".")
  end

  def descripcion
  	"#{self.numero} x (#{monto_con_formato}) del #{self.banco_origen.nombre}"
  end

  def descripcion_con_ci
    
    aux = self.objeto.nil? ? '' : "#{self.objeto.estudiante.ci} - "
    aux += self.descripcion

    return aux
      
  end

  def objeto
    if grado
      grado
    else
      inscripcionescuelaperiodo
    end
  end

end
