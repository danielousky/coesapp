class Estudiante < ApplicationRecord
	# ASOCIACIONES:
	belongs_to :usuario, foreign_key: :usuario_id 
	# belongs_to :tipo_estado_inscripcion

	# belongs_to :citahoraria, optional: true

	has_one :direccion#, foreign_key: :estudiante_id

	has_many :grados, dependent: :destroy
	has_many :escuelas, through: :grados

	has_many :bitacoras
	accepts_nested_attributes_for :bitacoras
	
	has_many :inscripcionsecciones
	accepts_nested_attributes_for :inscripcionsecciones

	has_many :inscripcionescuelaperiodos
	accepts_nested_attributes_for :inscripcionescuelaperiodos

	has_many :secciones, through: :inscripcionsecciones, source: :seccion

	has_many :combinaciones, dependent: :delete_all
	accepts_nested_attributes_for :combinaciones

	# TRIGGERS
	# after_initialize :set_default, :if => :new_record?
	after_destroy :destroy_all

	# VALIDACIONES:
	validates :usuario_id, presence: true, uniqueness: true

	# SCOPES:
	# scope :con_cita_horaria, -> {where "citahoraria_id IS NOT NULL"}

	scope :con_inscripcion_en_periodo, lambda{|periodo_id| joins(:inscripcionsecciones).joins(:secciones).where("secciones.periodo_id = ?", periodo_id)} 

	# FUNCIONES:

	# def self.estudiantes_a_escuela_estudiantes
	# 	self.all.each do |es|
	# 		if es.escuela_id
	# 			print '.' if es.escuelas_estudiantes.create!(escuela_id: es.escuela_id)
	# 		end
	# 	end
	# end

	def datos_incompletos?
		self.direccion.nil? ? true : false
	end


	def ci
		self.usuario_id
	end

	def inscripciones
		inscripcionsecciones
	end

	def tiene_alguna_inscripcion?
		inscripcionsecciones.count > 0
	end

	def total_creditos_cursados_en_periodos periodos_ids
		inscripciones.de_la_escuela(escuela_id).total_creditos_cursados_en_periodos periodos_ids
	end

	def total_creditos_aprobados_en_periodos periodos_ids
		inscripciones.de_la_escuela(escuela_id).total_creditos_aprobados_en_periodos periodos_ids
	end

	# def any_asign_inscrita_numerica3?
	# 	self.inscripcionsecciones.joins(:asignatura).group("asignaturas.calificacion").count[2] > 0
	# end

	def inactivo? periodo_id
	# OJO: ESTA FUNCION DEBE CAMBIAR AL AGREGAR LA TABLA INSCRIPCION PERIDO!!!
		total_asignaturas = (self.inscripcionsecciones.del_periodo periodo_id).count
		total_retiradas = (self.inscripcionsecciones.del_periodo periodo_id).where(tipo_estado_inscripcion_id: TipoEstadoInscripcion::RETIRADA).count
		(total_asignaturas > 0 and total_asignaturas == total_retiradas)
	end

	def ultimo_periodo_inscrito_en escuela_id
		de_la_escuela = inscripcionsecciones.de_la_escuela(escuela_id)
		if de_la_escuela.any? 
			de_la_escuela.joins(:seccion).order("secciones.periodo_id").last.seccion.periodo_id
		else
			nil
		end
	end

	def descripcion_otro_titulo
		if titulo_universitario
			return "#{titulo_universitario} - #{titulo_universidad} (#{titulo_anno})" 
		else
			return ''
		end
	end
	# def inscrito? periodo_id, escuela_id = nil
	# 	if escuela_id
	# 		(inscripcionsecciones.del_periodo(periodo_id)).reject{|is| !is.escuela.id.eql? escuela_id}.count > 0
	# 	else
	# 		(inscripcionsecciones.del_periodo(periodo_id)).count > 0
	# 	end
	# end

	def inscrito? periodo_id, escuela_id = nil
		if escuela_id
			(inscripcionsecciones.del_periodo(periodo_id)).de_la_escuela(escuela_id).count > 0
		else
			(inscripcionsecciones.del_periodo(periodo_id)).count > 0
		end

	end

	def con_registro_en_escuela escuela_id
		inscripcionsecciones.reject{|is| !is.escuela.id.eql? escuela_id}.count > 0
	end

	def valido_para_inscribir? periodo_id, escuela_id
		escuela = escuelas.where(id: escuela_id).first
		return false unless escuela
		aux_periodo_anterior = Periodo.find periodo_id
		aux_periodo_anterior = escuela.periodo_anterior aux_periodo_anterior.id

		if aux_periodo_anterior.nil?
			return true
		else
			return (inscrito? aux_periodo_anterior.id, escuela_id)
		end
	end

	def ultimo_plan_de_escuela escuela_id
		grados.where(escuela_id: escuela_id).first.ultimo_plan
	end

	def ultimo_plan
		hp = historialplanes.order("periodo_id DESC").first
		hp ? hp.plan_id : "--"
	end

	def annos
		self.secciones.collect{|s| s.asignatura.anno}.uniq
	end
	def annos_del_semestre_actual
		inscripcionsecciones.del_semestre_actual.collect{|s| s.seccion.asignatura.anno}.uniq
	end

	def combo_idiomas
		aux = ""
		aux += "#{idioma1.descripcion}" if idioma1
		aux += " - #{idioma2.descripcion}" if idioma2

		aux = "Sin Idiomas Registrados" if aux.eql? ""

		return aux 
	end

	def descripcion 
		usuario.descripcion
	end


	def archivos_disponibles_para_descarga
		secciones_aux = secciones.where(periodo_id: ParametroGeneral.periodo_actual.periodo_anterior.id)

		archivos = []
		annos = []
		if secciones_aux.all.count > 0

			# Selecciono los posibles niveles

			reprobadas = 0

			# joins_seccion_materia = secciones_aux.select("seccion.*, asignatura.*").joins(:asignatura)
			secciones_aux.select("seccion.*, asignatura.*").joins(:asignatura).group("asignatura.anno").each{|x| annos << x.anno if x.anno > 0}


			inscripcionsecciones.reject{|in_se| in_se.seccion.numero.eql? 'R'}.each do |est_sec|
				
				if est_sec.calificacion_final and est_sec.calificacion_final < 10
					reparacion = inscripcionsecciones.en_reparacion.first

					if reparacion
						reprobadas = reprobadas + 1 if reparacion.calificacion_final < 10
					else
						reprobadas = reprobadas + 1
					end 
				end
				# break if reprobadas > 1	
			end
			begin
				
				if annos.count.eql? 1
					if reprobadas.eql? 0 
						annos[0] = annos[0]+1 if annos.first < 5 
					else
						annos << annos.first+1 if annos.first < 5
					end
				else

					aux = secciones_aux.where('calificacion_final < ? ', 10)
					menor_anno = aux.select("seccion.*, asignatura.*").joins(:asignatura).where(' asignatura.anno = ?', annos.min).all
					annos.delete annos.min if menor_anno.count.eql? 0
					
					mayor_anno = aux.select("seccion.*, asignatura.*").joins(:asignatura).where(' asignatura.anno = ?', annos.max).all.count
					if mayor_anno.eql? 0
						total_materias = CalMateria.where(:anno => annos.max).count
						if total_materias.eql? secciones_aux.joins(:asignatura).where('asignatura.anno = ?', annos.max).all.count
							if annos.max<5
								annos << annos.max+1
								# annos.delete annos.max
							end
						end

					end
					
					annos << annos.last+1 if (reprobadas < 2 and annos.max<5)

				end

			rescue Exception => e
				annos << 1 << 2 << 3 << 4 << 5
			end

		else

			if cal_tipo_estado_inscripcion_id.eql? 'NUEVO'
				annos << 1
			else
				annos << 1 << 2 << 3 << 4 << 5
			end
		end

		# Selecciono los posibles idiomas

		if idioma1.nil? and idioma2.nil?
			annos.each do |anno|
				archivos << "FRA-ALE-#{anno}"
				archivos << "FRA-ITA-#{anno}"
				archivos << "FRA-POR-#{anno}"
				archivos << "ING-ALE-#{anno}"
				archivos << "ING-FRA-#{anno}"
				archivos << "ING-ITA-#{anno}"
				archivos << "ING-POR-#{anno}"
			end
		else 
			ni_ingles_ni_frances = false

			unless (idioma1.id.eql? 'ING' or idioma1.id.eql? 'FRA') or (idioma2.id.eql? 'ING' or idioma2.id.eql? 'FRA')

				idiomas = "ING-#{idioma1.id}-"
				idiomas_2 = "ING-#{idioma2.id}-"
				idiomas_3 = "FRA-#{idioma1.id}-"
				idiomas_4 = "FRA-#{idioma2.id}-"
				ni_ingles_ni_frances = true
			else
				idiomas = "#{idioma1.id}-#{idioma2.id}-"
			end

			# Compilo los archivos en relacion idiomas niveles

			annos.each{|ano| archivos << idiomas+ano.to_s}

			if ni_ingles_ni_frances
				annos.each{|ano| archivos << idiomas_2+ano.to_s}
				annos.each{|ano| archivos << idiomas_3+ano.to_s}
				annos.each{|ano| archivos << idiomas_4+ano.to_s}
			end
		end
		# puts "AÑÑÑÑÑOOOOOOOOOOSSSSS antes del retorno: #{annos}"

		return archivos
	end # Fin de funcion archivos_disponibles_para_descarga

	def idioma1
		combis = combinaciones.last
		if combis
			return combis.idioma1
		else
			return nil
		end
	end

	def idioma2
		combis = combinaciones.last
		if combis
			return combis.idioma2
		else
			return nil
		end
	end

	protected

	def set_default
		self.tipo_estado_inscripcion_id ||= 'NUEVO'	
	end

	private

	def destroy_all
		inscripcionescuelaperiodos.destroy_all
		usuario.destroy if (usuario.administrador.nil? and usuario.profesor.nil?)
		
	end


	def self.import row, fields, current_usuario_id, current_ip
		# fields: "escuela_id"=>"ARTE", "plan_id◊"=>"G394", "periodo_id◊"=>"2019-01S", "grado"=>{"tipo_ingreso"=>"OPSU◊", "estado_inscripcion◊"=>"preinscrito", "estado◊"=>"pregrado", "region◊"=>"no_aplica"}, "enviar_correo◊"=>"true"

		# row[0] = ci
		# row[1] = nombres
		# row[2] = apellidos
		# row[3] = emails

		total_newed = total_updated = 0
		no_registred = nil

		hay_usuario = false

		# row[0] = ci
		# row = row[0] if not row[0].nil?
		row[0].strip!
		row[0].delete! '^0-9'

		unless usuario = Usuario.where(ci: row[0]).first
			usuario = Usuario.new
			usuario.ci = row[0]
			usuario.password = usuario.ci
		end
		usuario.nombres = limpiar_cadena row[1]	# row[1] = nombres
		usuario.apellidos = limpiar_cadena row[2] # row[2] = apellidos
		usuario.email = row[3] # row[3]= Email

		nuevo = usuario.new_record?

		if usuario.save

			if nuevo
				desc_us = "Creacion de Usuario vía migración con CI: #{usuario.ci}"
				tipo_us = Bitacora::CREACION
			else
				desc_us = "Actualizacion de Usuario vía migración con CI: #{usuario.ci}"
				tipo_us = Bitacora::ACTUALIZACION
			end

			Bitacora.create!(
				descripcion: desc_us, 
				tipo: tipo_us,
				usuario_id: current_usuario_id,
				comentario: nil,
				id_objeto: usuario.id,
				tipo_objeto: 'Usuario',
				ip_origen: current_ip
			)

			estudiante = Estudiante.where(usuario_id: usuario.ci).first
			estudiante ||= Estudiante.new(usuario_id: usuario.ci)

			nuevo_estudiante = estudiante.new_record?

			if estudiante.save
				if plan = Plan.where(id: fields[:plan_id]).first
					unless grado = estudiante.grados.where(escuela_id: plan.escuela_id).first
						grado = Grado.new
						grado.plan_id = fields[:grado][:plan_id]
						grado.estudiante_id = estudiante.id
						grado.escuela_id = plan.escuela_id
					end

					grado.tipo_ingreso = fields[:grado][:tipo_ingreso]
					grado.iniciado_periodo_id = fields[:periodo_id]
					grado.region = fields[:grado][:region]
					grado.estado_inscripcion = fields[:grado][:estado_inscripcion]
					grado.estado = fields[:grado][:estado]
					
					nuevo_grado = grado.new_record?

					if grado.save

						if nuevo_grado
							desc = "Estudiante #{estudiante.id} registrado en #{grado.escuela.descripcion}"
							tipo = Bitacora::CREACION
							total_newed = 1

							if fields[:enviar_correo] and !usuario.email.blank?
								p '  ---- ENVIANDO CORREOS ---- '.center 800, '#'
								begin
									grado.delay.enviar_correo_bienvenida(current_usuario_id, current_ip)
									# total_correos_enviados += 1
								rescue Exception => e
									return [0,0, "error enviando correo: #{e}"]	
								end
							end

						else
							desc = "Actualizada carrera de #{estudiante.id} en #{grado.escuela.descripcion}"
							tipo = Bitacora::ACTUALIZACION
							total_updated = 1
						end

						Bitacora.create!(
							descripcion: desc, 
							tipo: tipo,
							usuario_id: current_usuario_id,
							comentario: nil,
							id_objeto: grado.id,
							tipo_objeto: 'Grado',
							ip_origen: current_ip
						)

					else
						return [0,0, 'error grado']	
					end
				else
					return [0,0, 'error plan']
				end

			else
				return [0,0, 'error estudiante']
			end
		else
			return [0,0, "error usuario: #{row}"]
		end

		[total_newed, total_updated, no_registred]
	end


	def self.limpiar_cadena cadena
		cadena.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
		cadena.strip!
		return cadena
	end

end
