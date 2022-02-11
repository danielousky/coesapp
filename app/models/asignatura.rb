class Asignatura < ApplicationRecord

	# ASOCIACIONES:
	belongs_to :catedra
	belongs_to :departamento
	belongs_to :tipoasignatura

	has_many :dependencias

	def dependencia_hacia_atras
		Dependencia.where(asignatura_dependiente_id: self.id)
	end
	# has_many :dependientes, class_name: 'Dependencia', foreign_key: 'asignatura_dependiente_id'

	# has_many :asignaturas, through: :dependientes, class_name: 'Dependencia'

	has_many :programaciones, dependent: :destroy
	has_many :periodos, through: :programaciones

	# belongs_to :catedra_departamento, class_name: 'CatedraDepartamento', foreign_key: [:catedra_id, :departamento_id], primary_key: [:catedra_id, :departamento_id]

	# ENUMERADAS CONSTANTES
	enum calificacion: [:numerica, :absoluta, :numerica3]

	has_one :escuela, through: :departamento
	has_many :secciones
	accepts_nested_attributes_for :secciones

	# VALIDACIONES:
	validates :id, presence: true, uniqueness: true
	validates_uniqueness_of :id_uxxi, message: 'Código UXXI ya está en uso', field_name: false	
	validates_presence_of :id_uxxi, message: 'Código UXXI requerido'	
	validates :descripcion, presence: true
	validates :calificacion, presence: true
	# validates :anno, presence: true
	# validates :orden, presence: true
	validates :catedra_id, presence: true
	validates :departamento_id, presence: true
	validates :tipoasignatura_id, presence: true

	# SCOPE
	scope :del_departamento, lambda {|dpto_id| where(departamento_id: dpto_id)}

	scope :activas, lambda { |periodo_id| joins(:programaciones).where('programaciones.periodo_id = ?', periodo_id) }

	scope :pcis, lambda { |periodo_id| joins(:programaciones).where('programaciones.periodo_id = ? and programaciones.pci IS TRUE', periodo_id) }

	scope :no_pcis, lambda { |periodo_id| joins(:programaciones).where('programaciones.periodo_id = ? and programaciones.pci IS FALSE', periodo_id) }

	scope :de_escuela, lambda {|escuela_id| joins(:escuela).where('escuelas.id': escuela_id)}
	scope :sin_la_escuela, -> (escuela_id){joins(:escuela).where("escuelas.id != '#{escuela_id}'")}

	# scope :pcis, -> {where('pci IS TRUE')}
	# scope :no_pcis, -> {where('pci IS FALSE')}


	# TRIGGGERS:
	before_save :set_uxxi_how_id
	before_save :set_to_upcase, :if => :new_record?

	# FUNCIONES:
	def proyecto?
		self.tipoasignatura_id.eql? Tipoasignatura::PROYECTO
	end

	def pci? periodo_id
		programaciones.pcis.del_periodo(periodo_id).any?
	end

	def tiene_programaciones? periodo_id
		programaciones.where(periodo_id: periodo_id).count > 0
	end

	def desc_confirm_inscripcion
		"- #{self.descripcion} - #{self.creditos}"
	end

	def descripcion_id
		"#{id}: #{descripcion}"
	end

	def descripcion_id_con_creditos
		"#{descripcion_id} (#{creditos} Unidades de Créditos)"
	end

	def descripcion_pci periodo_id

		if self.pci? periodo_id
			return "#{self.descripcion} (PCI)"
		else
			self.descripcion
		end
	end
	def activa? periodo_id
		# return self.activa #self.activa.eql? true ? true : false
		self.programaciones.del_periodo(periodo_id).any?
	end

	def descripcion_id_con_escuela
		"#{descripcion_id} <span class='badge badge-success'>#{self.escuela.descripcion}</span>".html_safe
	end
	def descripcion_con_id_pci? periodo_id = nil

		aux = "#{id}: #{descripcion_completa}"
		aux += " (PCI) " if periodo_id and self.pci?(periodo_id)
		return aux
	end
	def descripcion_completa
		"#{descripcion_id} - #{catedra.descripcion_completa} - #{departamento.descripcion_completa}"
	end

	def descripcion_reversa
		desc = cal_departamento.descripcion if cal_departamento
		desc += "| #{catedra.descripcion.titleize}" if catedra		
		return desc
	end

	# FUNCIONES PROTEGIDAS:
	protected
	
	def set_uxxi_how_id
		self.id_uxxi.strip!
		self.id = self.id_uxxi if self.id != self.id_uxxi
	end

	def set_to_upcase
		self.descripcion.strip.upcase.strip!
	end
end
