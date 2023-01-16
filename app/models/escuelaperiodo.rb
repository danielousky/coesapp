class Escuelaperiodo < ApplicationRecord

	# ASOCIACIONES: 
	belongs_to :periodo
	belongs_to :escuela

	has_many :jornadacitahorarias, dependent: :destroy

	has_many :inscripcionescuelaperiodos
	accepts_nested_attributes_for :inscripcionescuelaperiodos
	# VALIDACIONES:
	# validates :id, presence: true, uniqueness: true
	validates_uniqueness_of :periodo_id, scope: [:escuela_id], message: 'La escuela ya está en este período', field_name: false

	
	# def grados_sin_cita_horaria

	# end

	# def grados_sin_cita_horaria_ordenados
	# 	self.escuela.grados.no_preinscrito.sin_cita_horarias.order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc])
	# end

	def escuelaperiodo_anterior
		periodo_anterior = escuela.periodo_anterior periodo_id
		Escuelaperiodo.where(periodo_id: periodo_anterior.id, escuela_id: escuela_id).first
	end

	def total_secciones
		secciones.count
	end

	def secciones
		Seccion.de_la_escuela(self.escuela_id).del_periodo(self.periodo_id)
	end

	def descripcion_id
		"#{escuela_id}-#{periodo_id}"
	end

	def limite_creditos_permitidos
		self.max_creditos
	end
	
	def limite_asignaturas_permitidas
		self.max_asignaturas
	end

end
