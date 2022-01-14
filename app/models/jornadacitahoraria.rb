class Jornadacitahoraria < ApplicationRecord
  
  #RELACIONES
  belongs_to :escuelaperiodo
  has_one :escuela, through: :escuelaperiodo 
  has_one :periodo, through: :escuelaperiodo 
  
  # VALIDACIONES
  validates :escuelaperiodo_id, presence: true
  validates :inicio, presence: true
  validates :duracion_total_horas, presence: true
  validates :max_grados, presence: true
  validates :duracion_franja_minutos, presence: true

  validates_with UnicoDiaCitaHorariaValidator, field_name: false, if: :new_record?

  #CALLBACK
  after_destroy :limpiar_grados_cita_horaria

  #SCOPE
  scope :actual, -> (escuelaperiodo_id) { where("escuelaperiodo_id = '#{escuelaperiodo_id}' and inicio LIKE '%#{Date.today}%'")}
  
  #MÉTODOS
  def puede_inscribir? citahoraria
    Time.now > citahoraria and Time.now < citahoraria+self.duracion_franja_minutos.minutes 
  end

  def total_franjas
    (duracion_franja_minutos.eql? 0) ? 0 : (self.duracion_total_horas/self.duracion_franja_minutos.to_f*60).to_i
  end

  def grado_x_franja
    if total_franjas > max_grados 
      return 1
    else
      self.total_franjas > 0 ? (self.max_grados/self.total_franjas) : 0
    end
  end

  def grados_propios_ordenados
    self.escuela.grados.con_cita_horaria_igual_a(self.inicio.strftime "%Y-%m-%d").order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc])
  end

  def limpiar_grados_cita_horaria
    self.grados_propios_ordenados.update_all(citahoraria: nil)
  end

end