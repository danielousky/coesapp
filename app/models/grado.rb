class Grado < ApplicationRecord
	#CONSTANTES:
	TIPO_INGRESOS = ['OPSU', 'OPSU/COLA', 'SIMADI', 'ACTA CONVENIO (DOCENTE)', 'ACTA CONVENIO (ADMIN)', 'ACTA CONVENIO (OBRERO)', 'DISCAPACIDAD', 'DIPLOMATICO', 'COMPONENTE DOCENTE', 'EQUIVALENCIA', 'ART. 25 (CULTURA)', 'ART. 25 (DEPORTE)', 'CAMBIO: 158', 'ART. 6', 'EGRESADO', 'SAMUEL ROBINSON', 'DELTA AMACURO', 'AMAZONAS', 'PRODES', 'CREDENCIALES', 'SIMULTANEOS']

	# ASOCIACIONES:
	belongs_to :escuela
	belongs_to :estudiante
	belongs_to :plan, optional: true
	belongs_to :periodo_ingreso, optional: true, class_name: 'Periodo', foreign_key: :iniciado_periodo_id
	belongs_to :reportepago, optional: true, dependent: :destroy
	belongs_to :autorizar_inscripcion_en_periodo, optional: true, class_name: 'Periodo', foreign_key: :autorizar_inscripcion_en_periodo_id

	has_many :historialplanes
	has_many :inscripciones, class_name: 'Inscripcionseccion'
	has_many :inscripcionescuelaperiodos
	has_many :secciones, through: :inscripciones, source: :seccion

	# CALLBACKS
	before_validation :set_default
	before_save :set_autorizar_inscripcion_en_periodo_id
	after_destroy :destroy_all

	# VALIDACIONES
	validates :tipo_ingreso, presence: true 
	validates :estado_inscripcion, presence: true
	validates_uniqueness_of :estudiante_id, scope: [:escuela_id], message: 'Estudiante ya inscrito en la escuela', field_name: false

	# validates :inscrito_ucv, presence: true 
	# has_many :inscripcionsecciones, foreign_key: [:escuela_id, :estudiante_id]


	# SCOPES
	scope :no_retirados, -> {where "estado != 3"}
	scope :cursadas, -> {where "estado != 3"}
	scope :aprobadas, -> {where "estado = 1"}
	scope :sin_equivalencias, -> {joins(:seccion).where "secciones.tipo_seccion_id != 'EI' and secciones.tipo_seccion_id != 'EE'"} 
	scope :por_equivalencia, -> {joins(:seccion).where "secciones.tipo_seccion_id = 'EI' or secciones.tipo_seccion_id = 'EE'"}
	scope :por_equivalencia_interna, -> {joins(:seccion).where "secciones.tipo_seccion_id = 'EI'"}
	scope :por_equivalencia_externa, -> {joins(:seccion).where "secciones.tipo_seccion_id = 'EE'"}
	scope :total_creditos_inscritos, -> {joins(:asignatura).sum('asignaturas.creditos')}
	scope :inscritos_ucv, -> {where(inscrito_ucv: true)}
	scope :no_inscritos_ucv, -> {where(inscrito_ucv: false)}

	scope :no_preinscrito, -> {where('estado_inscripcion != 0')}

	scope :culminado_en_periodo, -> (periodo_id) {where "culminacion_periodo_id = ?", periodo_id}
	scope :iniciados_en_periodo, -> (periodo_id) {where "iniciado_periodo_id = ?", periodo_id}
	scope :iniciados_en_periodos, -> (periodo_ids) {where "iniciado_periodo_id IN (?)", periodo_ids}

	scope :de_las_escuelas, lambda {|escuelas_ids| where("escuela_id IN (?)", escuelas_ids)}


	scope :con_inscripciones, -> { where('(SELECT COUNT(*) FROM inscripcionsecciones WHERE inscripcionsecciones.estudiante_id = grados.estudiante_id) > 0') }
	

	# scope :con_cita_horarias, -> { where('(SELECT COUNT(*) FROM citahorarias WHERE citahorarias.estudiante_id = grados.estudiante_id) > 0') }
	scope :con_cita_horarias, -> { where("citahoraria IS NOT NULL")}
	scope :con_cita_horaria_igual_a, -> (dia){ where("citahoraria LIKE '%#{dia}%'")}
	scope :sin_cita_horarias, -> { where(citahoraria: nil)}


	scope :con_inscripciones_en_periodo, -> (periodo_id) { joins(inscripciones: :seccion).where('(SELECT COUNT(*) FROM inscripcionsecciones WHERE inscripcionsecciones.estudiante_id = grados.estudiante_id) > 0 and secciones.periodo_id = ?', periodo_id) }
	
	# scope :con_inscripcionescuelaperiodos, -> (escuelaperiodo_id) { joins(:inscripcionescuelaperiodos).where('inscripcionescuelaperiodos.escuelaperiodo_id = ?', escuelaperiodo_id) }

	scope :sin_inscripciones, ->{ where('(SELECT COUNT(*) FROM inscripcionsecciones WHERE inscripcionsecciones.estudiante_id = grados.estudiante_id) = 0') }

	scope :sin_plan, -> {where(plan_id: nil)}


	# VARIABLES TIPOS
	enum estado: [:pregrado, :tesista, :posible_graduando, :graduando, :graduado, :postgrado]

	enum estado_inscripcion: [:preinscrito, :confirmado, :reincorporado, :asignado]
	enum region: [:no_aplica, :amazonas, :barcelona, :barquisimeto, :bolivar, :capital]

	enum tipo_ingreso: TIPO_INGRESOS

	# after_create :enviar_correo_bienvenida

	# def inscripciones
	# 	Inscripcionseccion.joins(:escuela).where("estudiante_id = ? and escuelas.id = ?", estudiante_id, escuela_id)
	# end

	# Así debe ser inscripciones
	# def inscripciones
	# 	Inscripcionseccion.where("estudiante_id = ? and escuelas_id = ?", estudiante_id, escuela_id)
	# end


	def inscripciones_en_periodo_activo
		escupe_activo = escuela.escuelaperiodos.where(periodo_id: escuela.periodo_activo_id).first
		estudiante.inscripcionescuelaperiodos.where(escuelaperiodo_id: escupe_activo.id)
	end

	def inscripto_en_periodo_activo?
		inscripciones_en_periodo_activo.any?
	end

	def autorizar_inscripcion_en_periodo_decrip
		autorizar_inscripcion_en_periodo_id ? autorizar_inscripcion_en_periodo_id : 'Sin Autorización Especial'
	end
	def autorizar_inscripcion_en_periodo_decrip_badge
		"<span class='badge badge-info'>#{autorizar_inscripcion_en_periodo_decrip}</span>".html_safe
	end

	def inscrito_ucv_label
		valor = 'No'
		tipo = 'danger'
		if self.inscrito_ucv
			valor = 'Si'
			tipo = 'success'
		end
		"<span class='badge badge-#{tipo}'>#{valor}</span>".html_safe
	end


	def printHorario periodo_id
	data = Bloquehorario::DIAS
	data.unshift("")
	data.map!{|a| "<b>"+a[0..2]+"</b>"}
	data = [data]

	secciones_ids = secciones.where(periodo_id: periodo_id).ids 
	# bloques = Bloquehorario.where(horario_id: secciones_ids).group(entrada).having('HOUR(entrada)')# intento con Group

	# bloques = Bloquehorario.where(horario_id: secciones_ids).select("HOUR(entrada) AS hora", "bloquehorarios.id AS id").group('hora')# intento con Group
	bloques = Bloquehorario.where(horario_id: secciones_ids).collect{|bh| {horario: bh.dia_con_entrada, id: bh.id}}.uniq{|e| e[:horario] }
	p bloques	

	for i in 7..14 do
		for j in 0..3 do
			# aux = ["#{i.to_s}:#{sprintf("%02i", (j*15))}"]

			# Bloquehorario::DIAS.each do |dia|
			# 	aciertos = bloques.map{|b| b[:id] if b[:horario] == "#{dia} #{Bloquehorario.hora_descripcion "07:00".to_time}"}.compact
				
			# 	aciertos.each do |acierto|

			# 	end
			# 	aux << ""

			# end
			data << ["#{i.to_s}:#{sprintf("%02i", (j*15))}","","","","",""] # En blanco
		end
	end
	return data #bloques
	end

	def descripcion
		"#{estudiante.id}-#{escuela.id}"
	end


	def plan_descripcion_corta
		plan ? plan.descripcion_completa : '--'
	end

	def plan_descripcion
		plan ? plan.descripcion_completa : 'Sin plan asociado'
	end

	def total_creditos_cursados periodos_ids = nil
		if periodos_ids
			inscripciones.total_creditos_cursados_en_periodos periodos_ids
		else
			inscripciones.total_creditos_cursados
		end
	end

	def total_creditos_aprobados periodos_ids = nil
		if periodos_ids
 			inscripciones.total_creditos_aprobados_en_periodos periodos_ids
 		else
 			inscripciones.total_creditos_aprobados
 		end
	end

	def calcular_eficiencia periodos_ids = nil 
        cursados = self.total_creditos_cursados periodos_ids
        aprobados = self.total_creditos_aprobados periodos_ids
		(cursados and cursados > 0) ? (aprobados.to_f/cursados.to_f).round(4) : 0.0
	end

	def calcular_promedio_simple periodos_ids = nil
		if periodos_ids
			aux = inscripciones.de_los_periodos(periodos_ids).cursadas
		else
			aux = inscripciones.cursadas
		end

        (aux and aux.count > 0 and !aux.average('calificacion_final').nil?) ? aux.average('calificacion_final').round(4) : 0.0

	end

	def calcular_promedio_ponderado periodos_ids = nil
		if periodos_ids
			aux = inscripciones.de_los_periodos(periodos_ids).ponderado
		else
			aux = inscripciones.ponderado
		end
		cursados = self.total_creditos_cursados periodos_ids

		cursados > 0 ? (aux.to_f/cursados.to_f).round(4) : 0.0
	end


	def inscrito_en_periodos? periodo_ids
		(inscripciones.de_los_periodos(periodo_ids)).count > 0
	end



	def inscrito_en_periodo? periodo_id
		(inscripciones.del_periodo(periodo_id)).count > 0
	end

	def ultimo_plan
		aux = plan
		if plan.nil?
			hp = self.historialplanes.por_escuela(escuela_id).order('periodo_id DESC').first	
			aux = hp ? hp.plan : nil
		else
			aux = plan
		end
		return aux 
		# hp = self.historialplanes.por_escuela(escuela_id).order('periodo_id DESC').first
		# hp ? hp.plan : nil
	end

	def descripcion_ultimo_plan
		plan = ultimo_plan
		if plan
			plan.descripcion_completa_con_escuela
		else
			'Sin Plan Asignado'
		end
	end

	def enviar_correo_asignados_opsu_2020(usuario_id, ip)
		# ) if EstudianteMailer.delay.asignados_opsu_2020(self).deliver
		Bitacora.create!(
			descripcion: "Correo de registro de carrera de estudiante: #{self.estudiante_id} enviado.", 
			tipo: Bitacora::CREACION,
			usuario_id: usuario_id,
			comentario: nil,
			id_objeto: self.id,
			tipo_objeto: self.class.name,
			ip_origen: ip
		) if EstudianteMailer.asignados_opsu_2020(self).deliver
	end
	def enviar_correo_bienvenida(usuario_id, ip)
		Bitacora.create!(
			descripcion: "Correo de registro de carrera de estudiante: #{self.estudiante_id} enviado.", 
			tipo: Bitacora::CREACION,
			usuario_id: usuario_id,
			comentario: nil,
			id_objeto: self.id,
			tipo_objeto: self.class.name,
			ip_origen: ip
		) if EstudianteMailer.bienvenida(self).deliver
	end

	private

	def set_default
		self.region ||= :no_aplica
		self.estado_inscripcion ||= :asignado
	end
	def set_autorizar_inscripcion_en_periodo_id
		self.autorizar_inscripcion_en_periodo_id = nil if self.autorizar_inscripcion_en_periodo_id.eql? ''
	end

	def destroy_all
		destroy_estudiante
		destroy_inscripciones
	end

	def destroy_estudiante
		self.estudiante.destroy unless self.estudiante.grados.any?
	end

	def destroy_inscripciones
		inscripciones.destroy_all
	end
	# def actualizar_estado_inscripciones
	# 	if asignatura.tipoasignatura_id.eql? Tipoasignatura::PROYECTO
	# 		if self.sin_calificar?
	# 			grado.update(estado :tesista)
	# 		elsif self.retirado? or self.aplazado
	# 			grado.update(estado :pregrado)
	# 		elsif self.aprobado?
	# 			grado.update(estado 'posible_graduando')
	# 		end
	# 	end
	# end	


end
