class TipoEstadoInscripcion < ApplicationRecord

	PREINSCRITO = 'PRE'
	INSCRITO = 'INS'
	REINCORPODADO = 'REINC'
	RETIRADA = 'RET'
	# ASOCIACIONES:
	has_many :inscripcionsecciones
	accepts_nested_attributes_for :inscripcionsecciones

	# VALIDACIONES:
    validates :id, presence: true, uniqueness: true

	def inscrito?
		id.eql? INSCRITO
	end

	def preinscrito?
		id.eql? PREINSCRITO
	end

end
