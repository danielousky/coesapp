class Inscripcionescuelaperiodo < ApplicationRecord

	has_many :inscripcionsecciones
	accepts_nested_attributes_for :inscripcionsecciones

	belongs_to :estudiante, primary_key: 'usuario_id'
	belongs_to :escuelaperiodo
	belongs_to :tipo_estado_inscripcion

	has_one :escuela, through: :escuelaperiodo
	has_one :periodo, through: :escuelaperiodo

	validates_uniqueness_of :estudiante_id, scope: [:escuelaperiodo_id], message: 'El estudiante ya posee una inscripción en el período actual', field_name: false

	has_one :reportepago
	
	scope :del_periodo, -> (periodo_id) {joins(:periodo).where('periodos.id = ?', periodo_id)}
	scope :de_la_escuela, -> (escuela_id) {joins(:escuela).where('escuelas.id = ?', escuela_id)}
	
	scope :preinscritos, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::PREINSCRITO)}
	scope :inscritos, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::INSCRITO)}
end
