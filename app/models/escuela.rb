class Escuela < ApplicationRecord

	# ASOCIACIONES
	belongs_to :periodo_inscripcion, foreign_key: 'periodo_inscripcion_id', class_name: 'Periodo', optional: true
	belongs_to :periodo_activo, foreign_key: 'periodo_activo_id', class_name: 'Periodo'#, optional: true

	validates :periodo_activo_id, presence: true

	has_many :grados
	has_many :estudiantes, through: :grados

	has_many :departamentos
	accepts_nested_attributes_for :departamentos
	
	# has_many :inscripciones_pci, class_name: 'Inscripcionseccion', foreign_key: 'pci_escuela_id'
	has_many :asignaturas, through: :departamentos
	
	has_many :profesores, through: :departamentos

	has_many :secciones, through: :asignaturas
	
	has_many :programaciones, through: :asignaturas

	has_many :inscripcionsecciones, through: :secciones

	has_many :escuelaperiodos
	accepts_nested_attributes_for :escuelaperiodos
	
	has_many :inscripcionescuelaperiodos, through: :escuelaperiodos
	has_many :periodos, through: :escuelaperiodos

	has_many :planes
	accepts_nested_attributes_for :planes

	has_many :administradores
	accepts_nested_attributes_for :administradores

	#SCOPE
	scope :descripcion, -> {map{|es| es.descripcion}}
	# TRIGGERS
	before_save :set_to_upcase

	#FUNCTIONS

	def desc_actas
		"Actas de #{self.descripcion} (#{self.secciones.count})"
	end
	def inscripciones
		inscripcionsecciones
	end

	def limpiar_todas_las_citashorarias
		grados.update_all(citahoraria: nil, duracion_franja_horaria: nil)
	end

	def self.actualizar_numeros_grados_idiomas_201902A
		e = Escuela.find 'IDIO'
		periodos_ids = e.periodos.ids-["2019-02A", "2020-02A"]
		e.grados.con_inscripciones_en_periodo('2019-02A').con_inscripciones_en_periodos(periodos_ids).group(:id).having('count(*) > 0').each{|gr|
			gr.update(eficiencia: gr.calcular_eficiencia(periodos_ids), promedio_simple: gr.calcular_promedio_simple(periodos_ids), promedio_ponderado: gr.calcular_promedio_ponderado(periodos_ids))
		} 

	end

	def dependencias_habilitadas?
		self.habilitar_dependencias
	end

	def self.actualizar_parciales_201802A
		e = Escuela.find 'IDIO'
		ss = e.secciones.calificadas.del_periodo ('2018-02A')
		p ss.count

		ss.each do |s|
			s.inscripcionsecciones.where("(estado = 1 || estado = 2) && tipo_calificacion_id != 'PI'").each do |i|
				i.segunda_calificacion = nil
				i.tercera_calificacion = nil
				i.calificacion_final = nil
				i.estado = :trimestre1
				i.tipo_calificacion_id = TipoCalificacion::PARCIAL
				i.save
			end
			s.calificada = false
			s.abierta = true
			s.save
		end
	end

	# def inscripcion_abierta?
	# 	(escuelaperiodos.last.permitir_inscripcion.eql? true) ? true : false
	# end

	def retiro_asignaturas_habilitado?
		self.habilitar_retiro_asignaturas
	end

	def cambio_seccion_habilitado?
		self.habilitar_cambio_seccion
	end

	def inscripcion_cerrada?
		periodo_inscripcion.nil? ? true : false
	end

	def periodo_anterior periodo_id
		periodo_aux = Periodo.find periodo_id
		
		letra = periodo_aux.letra_final_de_id

		if letra.eql? 'C'
			todos = periodos.where("periodos.id LIKE '%C'")
		elsif periodo_aux.semestral?
			todos = periodos.semestral.where("periodos.id NOT LIKE '%C'")
		else
			todos = periodos.anual
		end

		todos = todos.order(inicia: :asc).ids
		indice = todos.index periodo_id
		indice -= 1 if indice
		indice = 0 if indice.nil? or indice < 0
		
		return Periodo.find todos[indice]

	end

	def periodos_anteriores periodo_id
		periodo_aux = Periodo.find periodo_id
		if periodo_aux.anual?
			todos = periodos.anual
		else
			todos = periodos.semestral
		end
		todos = todos.order(inicia: :asc).ids
		todos = todos.split periodo_id
		todos = todos.first

		return Periodo.where(id: todos)
		
	end

	def descripcion_filtro
		self.descripcion.titleize
	end

	def inscripciones_en_periodo? periodo_id
		self.inscripcionsecciones.where("secciones.periodo_id = ?", periodo_id).count > 0
	end

	def secciones_en_periodo? periodo_id
		self.secciones.where("periodo_id = ?", periodo_id).count > 0
	end

	# def inscripciones_en_periodo_actual?
	# 	self.inscripcionsecciones.where("secciones.periodo_id = ?", ParametroGeneral.periodo_actual_id).count > 0
	# end

	# def inscripciones_en_periodo_actual
	# 	self.inscripcionsecciones.where("secciones.periodo_id = ?", ParametroGeneral.periodo_actual_id)
	# end

	protected

	def set_to_upcase
		self.descripcion = self.descripcion.upcase
	end

end
