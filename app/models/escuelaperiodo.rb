class Escuelaperiodo < ApplicationRecord

	# ASOCIACIONES: 
	belongs_to :periodo
	belongs_to :escuela

	has_many :inscripcionescuelaperiodos
	accepts_nested_attributes_for :inscripcionescuelaperiodos
	# VALIDACIONES:
	# validates :id, presence: true, uniqueness: true
	validates_uniqueness_of :periodo_id, scope: [:escuela_id], message: 'La escuela ya está en este período', field_name: false

end
