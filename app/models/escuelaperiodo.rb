class Escuelaperiodo < ApplicationRecord

	# ASOCIACIONES: 
	belongs_to :periodo
	belongs_to :escuela

	has_many :inscripcionescuelaperiodos
	accepts_nested_attributes_for :inscripcionescuelaperiodos
	# VALIDACIONES:
	# validates :id, presence: true, uniqueness: true
	validates_uniqueness_of :periodo_id, scope: [:escuela_id], message: 'La escuela ya está en este período', field_name: false

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
		self.periodo.anual? ? 49 : 25
	end

end
