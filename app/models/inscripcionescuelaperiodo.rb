class Inscripcionescuelaperiodo < ApplicationRecord

	has_many :inscripcionsecciones, dependent: :destroy
	accepts_nested_attributes_for :inscripcionsecciones

	belongs_to :estudiante, primary_key: 'usuario_id'
	belongs_to :escuelaperiodo
	belongs_to :tipo_estado_inscripcion

	has_one :escuela, through: :escuelaperiodo
	has_one :periodo, through: :escuelaperiodo

	validates_uniqueness_of :estudiante_id, scope: [:escuelaperiodo_id], message: 'El estudiante ya posee una inscripción en el período actual', field_name: false

	belongs_to :reportepago, optional: true
	
	scope :del_periodo, -> (periodo_id) {joins(:periodo).where('periodos.id = ?', periodo_id)}
	scope :de_la_escuela, -> (escuela_id) {joins(:escuela).where('escuelas.id = ?', escuela_id)}
	scope :de_la_escuela_y_periodo, -> (escuelaperiodo_id) {where('escuelaperiodo_id = ?', escuelaperiodo_id)}
	scope :del_estudiante, -> (estudiante_id) {where('usuario_id = ?', estudiante_id)}
	scope :preinscritos, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::PREINSCRITO)}
	scope :inscritos, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::INSCRITO)}



	def self.find_or_new(escuela_id, periodo_id, estudiante_id)

		escupe = Escuelaperiodo.where(periodo_id: periodo_id, escuela_id: escuela_id).first
		# ins_periodo = estudiante.inscripcionescuelaperiodos.de_la_escuela_y_periodo(escupe.id).first

		ins_escuelaperiodo = Inscripcionescuelaperiodo.where(estudiante_id: estudiante_id, escuelaperiodo_id: escupe.id).first

		if ins_escuelaperiodo.nil?
			ins_escuelaperiodo = Inscripcionescuelaperiodo.new
			ins_escuelaperiodo.estudiante_id = estudiante_id
			ins_escuelaperiodo.escuelaperiodo_id = escupe.id
		end

		return ins_escuelaperiodo

	end
end
