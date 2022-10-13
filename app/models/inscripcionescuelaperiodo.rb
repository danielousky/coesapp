class Inscripcionescuelaperiodo < ApplicationRecord

	# Tipo Estado Inscripciones
	# ["CO", "INS", "NUEVO", "PRE", "REINC", "RES", "RET", "VAL"] 

	# ASOCIACIONES:
	has_many :inscripcionsecciones, dependent: :destroy
	accepts_nested_attributes_for :inscripcionsecciones

	has_many :secciones, through: :inscripcionsecciones, source: :seccion
	has_many :asignaturas, through: :secciones

	belongs_to :estudiante, primary_key: 'usuario_id'
	belongs_to :escuelaperiodo
	belongs_to :tipo_estado_inscripcion
	belongs_to :grado

	has_one :escuela, through: :escuelaperiodo
	has_one :periodo, through: :escuelaperiodo

	belongs_to :reportepago, optional: true

	#CALLBACKS:
	after_save :bitacora_confirmacion_inscripcion

	# VALIDACIONES:
	validates_uniqueness_of :estudiante_id, scope: [:escuelaperiodo_id], message: 'El estudiante ya posee una inscripción en el período actual', field_name: false

	# SCOPES:
	scope :del_periodo, -> (periodo_id) {joins(:periodo).where('periodos.id = ?', periodo_id)}
	scope :de_la_escuela, -> (escuela_id) {joins(:escuela).where('escuelas.id = ?', escuela_id)}
	scope :de_la_escuela_y_periodo, -> (escuelaperiodo_id) {where('escuelaperiodo_id = ?', escuelaperiodo_id)}
	scope :del_estudiante, -> (estudiante_id) {where('usuario_id = ?', estudiante_id)}
	scope :preinscritos, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::PREINSCRITO)}
	scope :inscritos, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::INSCRITO)}
	scope :reservados, -> {where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::RESERVADO)}
	# scope :con_reportepago, -> {joins(:reportepago)}
	scope :con_reportepago, -> {where('reportepago_id IS NOT NULL')}
	scope :sin_reportepago, -> {where(reportepago_id: nil)}

	scope :total_inscripciones, -> {inscripcionsecciones.count}
	scope :total_inscripciones_calificadas, -> {joins(:inscripcionsecciones).where('inscripcionsecciones.estado = 1 or inscripcionsecciones.estado = 2')}

	# FUNCIONES: 
	def revisar_reglamento
		reglamento_aux = :regular
		if inscribio_pero_no_aprobo_ninguna?
			reglamento_aux = :articulo_3
			iep_anterior = self.anterior_iep
			if iep_anterior and iep_anterior.inscribio_pero_no_aprobo_ninguna?
				reglamento_aux = :articulo_6
				iep_anterior2 = iep_anterior.anterior_iep
				if iep_anterior2 and iep_anterior2.inscribio_pero_no_aprobo_ninguna?
					reglamento_aux = :articulo_7
				end
			end
		end
		return reglamento_aux
	end

	def inscribio_pero_no_aprobo_ninguna?
		self.inscripcionsecciones.any? and !(self.inscripcionsecciones.aprobado.any?)
	end

	def anterior_iep
		escu_per_ant = self.escuelaperiodo.escuelaperiodo_anterior
		Inscripcionescuelaperiodo.where(grado_id: self.grado_id, escuelaperiodo_id: escu_per_ant.id).first
	end


	def label_estado_inscripcion
		# ["CO", "INS", "NUEVO", "PRE", "REINC", "RES", "RET", "VAL"] 

		if self.tipo_estado_inscripcion
			case self.tipo_estado_inscripcion_id
			when TipoEstadoInscripcion::INSCRITO
				label_color = 'success'
			when TipoEstadoInscripcion::PREINSCRITO
				label_color = 'info'
			when TipoEstadoInscripcion::RETIRADA
				label_color = 'danger'
			else
				label_color = 'secondary'
			end
			return " <span class='badge badge-#{label_color} text-center'>#{self.tipo_estado_inscripcion.descripcion.titleize}</span>".html_safe
		else
			return ''
		end
	end

	def limite_creditos_permitidos
		self.escuelaperiodo.limite_creditos_permitidos
	end


	def total_asignaturas
		asignaturas.count
	end

	def total_creditos
		asignaturas.sum(:creditos)
	end

	def decripcion_amplia
		"#{escuela.descripcion} #{periodo.id} #{estudiante.descripcion}"
	end

	def descripcion
		"#{escuela.id}-#{periodo.id}-#{estudiante.id}"
	end

	def inscrito?
		self.tipo_estado_inscripcion.inscrito?
	end

	def preinscrito?
		tipo_estado_inscripcion.preinscrito?
	end

	def reservado?
		tipo_estado_inscripcion.reservado?
	end


	def self.find_or_new(grado_id, periodo_id)

		grado = Grado.find grado_id
		escuela_id = grado.escuela_id
		estudiante_id = grado.estudiante_id
		escupe = Escuelaperiodo.where(periodo_id: periodo_id, escuela_id: escuela_id).first
		# ins_periodo = estudiante.inscripcionescuelaperiodos.de_la_escuela_y_periodo(escupe.id).first

		ins_escuelaperiodo = Inscripcionescuelaperiodo.where(grado_id: grado_id, escuelaperiodo_id: escupe.id).first

		if ins_escuelaperiodo.nil?
			ins_escuelaperiodo = Inscripcionescuelaperiodo.new
			ins_escuelaperiodo.estudiante_id = estudiante_id
			ins_escuelaperiodo.escuelaperiodo_id = escupe.id
			ins_escuelaperiodo.grado_id = grado_id
		end

		return ins_escuelaperiodo

	end

	def confirmar_con_correo
		if self.update(tipo_estado_inscripcion_id: TipoEstadoInscripcion::INSCRITO)
			if EstudianteMailer.confirmado(estudiante, self).delay.deliver
				Bitacora.create!(
				descripcion: "Se envió correo de confirmacion de inscripción estudiante #{self.estudiante_id} en periodo #{self.periodo.id} en #{self.escuela.descripcion}.", 
				tipo: Bitacora::CREACION,
				usuario_id: nil,
				comentario: nil,
				id_objeto: self.id,
				tipo_objeto: self.class.name,
				ip_origen: 'localhost'
				)

			end
		end		
	end

	def bitacora_confirmacion_inscripcion
		if self.tipo_estado_inscripcion_id.eql? TipoEstadoInscripcion::INSCRITO

			Bitacora.create!(
			descripcion: "Confirmada inscripción del estudiante #{self.estudiante_id} en periodo #{self.periodo.id} en #{self.escuela.descripcion}.", 
			tipo: Bitacora::CREACION,
			usuario_id: nil,
			comentario: nil,
			id_objeto: self.id,
			tipo_objeto: self.class.name,
			ip_origen: 'localhost'
			)

		end
		
	end
end
