
class ImportCsv

	def self.importar_estudiantes file, escuela_id, plan_id, periodo_id, grado, usuario_id, ip, enviar_correo= false
		require 'csv'

		# Totales
		# Usuarios
		total_usuarios_nuevos = 0
		total_usuarios_actualizados = 0
		#Estudiantes
		total_estudiantes_nuevos = 0
		total_estudiantes_actualizados = 0
		#Grados
		total_grados_nuevos = 0
		total_grados_actualizados = 0

		#No agregados
		usuarios_no_agregados = []
		estudiantes_no_agregados = []
		grados_no_agregados = []

		#Errores
		errores_generales = []
		errores_cabeceras = []
		estudiates_con_plan_errado = []
		estudiates_con_tipo_ingreso_errado = []
		estudiates_con_iniciado_periodo_id_errado = []
		estudiates_con_region_errada = []

		begin
			csv_text = File.read(file).encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_generales << "Error al intentar abrir el archivo: #{e}"			
		end

		# Validación de Cabeceras
		# begin
		# 	headers = csv.headers.flatten.split(";")
		# rescue Exception => e
		# 	errores_generales << "Error al intentar crear las cabeceras: #{e}"
		# end

		# unless errores_generales.any?
		# 	errores_cabeceras << "'ci'" unless (headers.include? 'ci')
		# 	if !(headers.include? 'nombres_apellidos')
		# 		errores_cabeceras << "'nombres'" unless (headers.include? 'nombres')
		# 		errores_cabeceras << "'apellidos'" unless (headers.include? 'apellidos')
		# 	end
		# end
		# Emails

		total_correos_enviados = 0
		total_correos_no_enviados = 0

		if not errores_generales.any?
			p "    INICIANDO PROCESO GENERAL    ".center(300, '$')

			csv.group_by{|row| row['ci']}.values.each do |row|

				begin

					# if profe = Profesor.where(usuario_id: row.field(0))
					hay_usuario = false

					p "    CONTENIDO DE ROW: #{row}    ".center(300, '$')


					row = row[0] if not row[0].nil?
					row['ci'].strip!
					row['ci'].delete! '^0-9'

					p "    INICIANDO A PROCESAR: #{row['ci']}    ".center(300, '$')
					unless usuario = Usuario.where(ci: row['ci']).limit(1).first
						usuario = Usuario.new
						usuario.ci = row['ci']
						usuario.password = usuario.ci
					end

					if row['nombres_apellidos'] 
						nombres_apellidos = separar_cadena row['nombres_apellidos']
						usuario.apellidos = nombres_apellidos[0]
						usuario.email = nombres_apellidos[1]
					else
						usuario.apellidos = limpiar_cadena row['apellidos']
						usuario.nombres = limpiar_cadena row['nombres']
					end
					
					usuario.telefono_movil = row['telefono']
					usuario.email = row['email']
					usuario.telefono_habitacion = row['telefono_habitacion']
					
					nuevo_usuario = usuario.new_record?
					if usuario.save
						p "    USUARIO REGISTRADO: #{usuario.ci}    ".center(300, '$')

						if nuevo_usuario
							total_usuarios_nuevos += 1
							desc_us = "Creacion de Usuario vía migración con CI: #{usuario.ci}"
							tipo_us = Bitacora::CREACION
						else
							total_usuarios_actualizados += 1
							desc_us = "Actualizacion de Usuario vía migración con CI: #{usuario.ci}"
							tipo_us = Bitacora::ACTUALIZACION
						end
						Bitacora.create!(
							descripcion: desc_us, 
							tipo: tipo_us,
							usuario_id: usuario_id,
							comentario: nil,
							id_objeto: usuario.id,
							tipo_objeto: 'Usuario',
							ip_origen: ip
						)						
						hay_usuario = true
					else
						hay_usuario = false
						usuarios_no_agregados << row['ci']
					end

					if hay_usuario
						hay_estudiante = false

						estudiante = Estudiante.where(usuario_id: usuario.ci).first
						estudiante ||= Estudiante.new(usuario_id: usuario.ci)

						nuevo_estudiante = estudiante.new_record?

						if estudiante.save

							p "    ESTUDIANTE REGISTRADO: #{usuario.ci}    ".center(300, '$')

							nuevo_estudiante ? (total_estudiantes_nuevos += 1) : (total_estudiantes_actualizados += 1)
							Bitacora.create!(
								descripcion: "Asociación de Usuario como Estudiante vía migración con CI: #{estudiante.id}", 
								tipo: Bitacora::CREACION,
								usuario_id: usuario_id,
								comentario: nil,
								id_objeto: usuario.id,
								tipo_objeto: 'Usuario',
								ip_origen: ip
							)

							hay_estudiante = true
						else
							estudiantes_no_agregados << estudiante.ci
						end

						if hay_estudiante
							escuela_id = row['escuela_id'] unless row['escuela_id'].blank?

							grado['plan_id'] = row['plan_id'] ? row['plan_id'].upcase.strip : plan_id

							unless Plan.all.ids.include? grado['plan_id']
								estudiates_con_plan_errado << estudiante.id
							else
								grado['tipo_ingreso'] = row['tipo_ingreso'].upcase.strip if row['tipo_ingreso']

								unless Grado.tipos_ingreso.keys.include? grado['tipo_ingreso']
									estudiates_con_tipo_ingreso_errado << estudiante.id
								else
									
									grado['iniciado_periodo_id'] = row['periodo_id'] ? row['periodo_id'] : periodo_id

									unless Periodo.all.ids.include? grado['iniciado_periodo_id']
										estudiates_con_iniciado_periodo_id_errado << estudiante.id
									else

										grado['region'] = row['region'] ? row['region'].downcase : 'no_aplica'

										unless (Grado.regiones.keys.include? grado['region'] )
											estudiates_con_region_errada << estudiante.id
										else
											grado['estudiante_id'] = estudiante.id
											grado['escuela_id'] = escuela_id

											p "    #{grado}  ".center(200, "€")
											grado_aux = estudiante.grados.where(escuela_id: escuela_id).first
											grado_aux ||= Grado.new
											
											grado_aux.plan_id = grado['plan_id']
											grado_aux.tipo_ingreso = grado['tipo_ingreso']
											grado_aux.iniciado_periodo_id = grado['iniciado_periodo_id']
											grado_aux.estudiante_id = grado['estudiante_id']
											grado_aux.escuela_id = grado['escuela_id']
											grado_aux.region = grado['region']
											grado_aux.estado_inscripcion = grado['estado_inscripcion']
											
											nuevo_grado = grado_aux.new_record?
											if grado_aux.save
												if nuevo_grado
													desc = "Estudiante #{estudiante.id} registrado en #{grado_aux.escuela.descripcion}"
													tipo = Bitacora::CREACION
													total_grados_nuevos += 1

													if enviar_correo
														p '  ---- ENVIANDO CORREOS ---- '.center 200, '#'
														begin
															grado_aux.enviar_correo_bienvenida(usuario_id, ip)
															total_correos_enviados += 1
														rescue Exception => e
															total_correos_no_enviados += 1
														end
													end

												else
													desc = "Actualizada carrera de #{estudiante.id} en #{grado_aux.escuela.descripcion}"
													tipo = Bitacora::ACTUALIZACION
													total_grados_actualizados += 1
												end

												Bitacora.create!(
													descripcion: desc, 
													tipo: tipo,
													usuario_id: usuario_id,
													comentario: nil,
													id_objeto: grado_aux.id,
													tipo_objeto: 'Grado',
													ip_origen: ip
												)
											else
												grados_no_agregados << "#{grado_aux.id} Error: (#{grado_aux.errors.full_messages.to_sentence})"
											end

											# begin
											# 	grado_aux.enviar_correo_asignados_opsu_2020(usuario_id, ip)
											# 	# grado_aux.enviar_correo_bienvenida(usuario_id, ip)
											# 	total_correos_enviados += 1
											# rescue Exception => e
											# 	total_correos_no_enviados += 1
											# end
										end
									end
								end

							end

							# self.historialplanes.destroy_all

							# if plan_id and !self.historialplanes.where(plan_id: plan_id, periodo_id: periodo_id).any?
							# 	hp = Historialplan.new
							# 	p "ESTUDIANTE CI: #{estudiante.id}"
							# 	hp.plan_id = plan_id
							# 	hp.periodo_id = periodo_id
							# 	# hp.estudiante_id = estudiante.id
							# 	# hp.escuela_id = escuela_id
							# 	hp.grado = grado_aux
							# 	if hp.save
							# 		total_planes_agregados += 1
							# 	else
							# 		total_planes_no_agregados += 1
							# 	end
							# end
						end
					end
					
				rescue Exception => e
					errores_generales << "#{row} #{e}" 
				end
			end
		end
		resumen = "<h6>Resumen de Migración de Datos:</h6>"
		resumen +=  "</br>Total de registros a procesar: <b>#{csv.group_by{|row| row['ci']}.count}</b><hr></hr>"
		resumen += "Total Usuarios Nuevos: <b>#{total_usuarios_nuevos}</b><hr></hr>"
		resumen += "Total Usuarios Actualizados: <b>#{total_usuarios_actualizados}</b><hr></hr>"
		resumen += "Total Estudiantes Nuevos: <b>#{total_estudiantes_nuevos}</b><hr></hr>"
		resumen += "Total Estudiantes Actualizados: <b>#{total_estudiantes_actualizados}</b><hr></hr>"
		resumen += "Total Grados(Carreras) Nuevos: <b>#{total_grados_nuevos}</b><hr></hr>"
		resumen += "Total Grados(Carreras) Actualizados: <b>#{total_grados_actualizados}</b><hr></hr>"
		resumen += "Total Correos Procesados: <b>#{total_correos_enviados}</b>"

		return [resumen, [estudiantes_no_agregados, usuarios_no_agregados, grados_no_agregados, estudiates_con_plan_errado,estudiates_con_tipo_ingreso_errado, estudiates_con_iniciado_periodo_id_errado, estudiates_con_region_errada, errores_generales, errores_cabeceras]]
	end

	def self.importar_profesores file
		require 'csv'
		errores_cabeceras = []

		begin
			csv_text = File.read(file).encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_cabeceras << "Error al intentar abrir el archivo: #{e}"			
		end

		errores_cabeceras << "Falta la cabecera 'ci' en el archivo o está mal escrita" unless csv.headers.include? 'ci'
		errores_cabeceras << "Falta la cabecera 'nombres' en el archivo o está mal escrita" unless csv.headers.include? 'nombres'
		errores_cabeceras << "Falta la cabecera 'apellidos' en el archivo o está mal escrita" unless csv.headers.include? 'apellidos'
		errores_cabeceras << "Falta la cabecera 'departamento_id' en el archivo o está mal escrita" unless csv.headers.include? 'departamento_id'

		if errores_cabeceras.count > 0
			return [0, "Error en las cabaceras del archivo: #{errores_cabeceras.to_sentence}"]
		else		
			total_agregados = 0
			usuarios_existentes = []
			profesores_existentes = []
			usuarios_no_agregados = []
			profes_no_agregados = []
			departamentos_no_encontrados = []
			csv.each do |row|
				begin
					row['ci'].delete! '^0-9'
					row['ci'].strip!
					# if profe = Profesor.where(usuario_id: row.field(0))
					dpto = Departamento.where("id = '#{row['departamento_id']}' OR descripcion = '#{row['departamento_id']}'").first
					if dpto.nil? 
						departamentos_no_encontrados << row['departamento_id']
					else
						if profe = Profesor.where(usuario_id: row['ci']).first
							profesores_existentes << profe.usuario_id
						elsif usuario = Usuario.where(ci: row['ci']).first
							usuarios_existentes << usuario.ci
							profe = Profesor.new
							profe.departamento_id = dpto.id
							profe.usuario_id = usuario.ci
							total_agregados += 1 if profe.save
						else
							usuario = Usuario.new
							usuario.ci = row['ci']
							usuario.password = usuario.ci
							usuario.nombres = row['nombres']
							usuario.apellidos = row['apellidos']
							usuario.email = row['email']
							usuario.telefono_movil = row['telefono']
							if usuario.save
								profe = Profesor.new
								profe.departamento_id = dpto.id
								profe.usuario_id = usuario.ci
								if profe.save
									total_agregados += 1
								else
									profes_no_agregados << profe.usuario_id
								end
							else
								usuarios_no_agregados << row['ci']
							end
						end
					end
				end
			end

			resumen = "</br><b>Resumen:</b></br>"
			resumen += "Total Profesores Agregados: <b>#{total_agregados}</b>"
			resumen += "</br>Detalle: #{profesores_existentes.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Usuarios Existentes (Se les creó el rol de profesor): <b>#{usuarios_existentes.size}</b>"
			resumen += "</br>Detalle: #{usuarios_existentes.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Profesores No Agregados (Se creó el usuario pero no el profesor): <b>#{profes_no_agregados.count}</b>"
			resumen += "</br>Detalle: #{profes_no_agregados.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Usuarios No Agregados: <b>#{usuarios_no_agregados.count}</b>"
			resumen += "</br>Detalle: #{usuarios_no_agregados.to_sentence.truncate(200)}<hr></hr>"
			resumen += "Total Departmanetos no enconrtados: <b>#{departamentos_no_encontrados.count}</b>"
			resumen += "</br>Detalle: #{usuarios_no_agregados.to_sentence.truncate(200)}"
				
			return [1, "Proceso de importación completado. #{resumen}"]
		end

	end

	def self.importar_inscripciones file, escuela_id, periodo_id=nil
		require 'csv'


		errores_cabeceras = []
		total_inscritos = 0
		total_existentes = 0
		estudiantes_no_inscritos = []
		total_nuevas_secciones = 0
		secciones_no_creadas = []
		estudiantes_inexistentes = []
		asignaturas_inexistentes = []
		total_calificados = 0
		total_aprobados = 0
		total_aplazados = 0
		total_retirados = 0
		total_no_calificados = 0

		estudiantes_sin_grado = []

		begin
			csv_text = File.read(file).encode('UTF-8', invalid: :replace, replace: '')
			csv = CSV.parse(csv_text, headers: true)
		rescue Exception => e
			errores_cabeceras << "Error al intentar abrir el archivo: #{e}"			
		end

		errores_cabeceras << "Falta la cabecera 'ci' en el archivo" unless csv.headers.include? 'ci'
		errores_cabeceras << "Falta la cabecera 'id_uxxi' en el archivo" unless csv.headers.include? 'id_uxxi'
		errores_cabeceras << "Falta la cabecera 'numero' en el archivo" unless csv.headers.include? 'numero'

		if errores_cabeceras.count > 0
			return [0, "Error en las cabeceras: #{errores_cabeceras.to_sentence}. Corrija el nombre e intente cargar el archivo nuevamente."]
		else

			csv.each_with_index do |row, i|
				begin
					# row = row[0]
					row['ci'].strip!
					row['ci'].delete! '^0-9'

					row['id_uxxi'].strip!
					row['numero'].strip! if row['numero']

					# BUSCAR PERIODO
					if periodo_id.nil?
						if row['periodo_id']

							row['periodo_id'].strip!
							row['periodo_id'].upcase!
							
							unless Periodo.where(id: row['periodo_id']).any?
								return [0, "Error: Periodo '#{row['periodo_id']}' es inválido. fila (#{i}): [#{row}]. Revise el archivo e inténtelo nuevamente."]
							end

						else
							return [0, "Sin período para la inscripción: #{row}. Por favor revise el archivo e inténtelo nuevamente."]
						end
						periodo_id = row['periodo_id']
					end

					# BUCAR ASIGNATURA
					unless a = Asignatura.where(id_uxxi: row['id_uxxi']).first
						asignaturas_inexistentes << row['id_uxxi']
					else
						# BUSCAR O CREAR SECCIÓN
						s = Seccion.where(numero: row['numero'], periodo_id: periodo_id, asignatura_id: a.id).limit(1).first
						if s.nil?
							total_nuevas_secciones += 1 if s = Seccion.create!(numero: row['numero'], periodo_id: periodo_id, asignatura_id: a.id, tipo_seccion_id: 'NF')
						end

						unless s
							secciones_no_creadas << row.to_hash
						else
							# BUSCAR ESTUDIANTE
							estu = Estudiante.where(usuario_id: row['ci']).first
							if estu.nil?
								estudiantes_inexistentes << row['ci']
							else
								# BUSCAR GRADO
								unless grado = estu.grados.where(escuela_id: escuela_id).first
									estudiantes_sin_grado << estu.id
								else
									# BUSCAR O CREAR INSCRIPCIÓN:
									p "     #{grado.descripcion}    ".center(2000, "#")
									inscrip = s.inscripcionsecciones.where(estudiante_id: row['ci']).first
									if inscrip.nil?
										inscrip = Inscripcionseccion.new
										escuelaperiodo = Escuelaperiodo.where(periodo_id: periodo_id, escuela_id: a.escuela.id).first
										escuelaperiodo ||= Escuelaperiodo.create!(periodo_id: periodo_id, escuela_id: a.escuela.id)
										# BUSCAR O CREAR INSCRIPCIÓN_ESCUELA_PERIODO
										unless inscrip_escuela_period = estu.inscripcionescuelaperiodos.where(escuelaperiodo_id: escuelaperiodo.id).first

											inscrip_escuela_period = Inscripcionescuelaperiodo.create!(estudiante_id: row['ci'], escuelaperiodo_id: escuelaperiodo.id, tipo_estado_inscripcion_id: 'INS', grado_id: grado.id)
										end

										inscrip.inscripcionescuelaperiodo_id = inscrip_escuela_period.id

										inscrip.estudiante_id = estu.id
										inscrip.escuela_id = escuela_id
										inscrip.seccion_id = s.id
										inscrip.grado_id = grado.id

									end

									# CALIFICAR:
									if row['nota'] and !row['nota'].blank?
										row['nota'].strip!
										inscrip.calificar row['nota']										
										if inscrip.retirado?
											total_retirados += 1
										elsif inscrip.aprobado?
											total_aprobados += 1
										else
											total_aplazados += 1
										end
									end

									if inscrip.save!
										total_inscritos += 1
										total_calificados += 1
									else
										estudiantes_no_inscritos << row['ci']
										total_no_calificados += 1
									end
								end
							end
						end						
					end
				rescue Exception => e
					# => OJO AYUDA EN EL ENTORNO DE DESARROLLO COLOCANDO EL BACKTRACE VISIBLE
					backtrace = (Rails.root.to_s.include? 'localhost') ? "#{e.backtrace.first}" : ''

					return [0, "<b>Error excepcional con el registro #{row.to_hash}: #{e.message} #{backtrace}</b>. #{self.resumen total_inscritos, total_existentes, estudiantes_no_inscritos, total_nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados, periodo_id, estudiantes_sin_grado }"]
					
				end
			end
			return [1, "Resumen procesos de migración: #{self.resumen total_inscritos, total_existentes, estudiantes_no_inscritos, total_nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados,periodo_id, estudiantes_sin_grado}"]
		end

	end


	def self.importar_estudiantes_e_inscripciones file, periodo_id
		require 'csv'

		csv_text = File.read(file)
		total_inscritos = 0
		total_existentes = 0
		estudiantes_no_inscritos = []
		total_nuevas_secciones = 0
		secciones_no_creadas = []
		estudiantes_inexistentes = []
		asignaturas_inexistentes = []
		total_calificados = 0
		total_aprobados = 0
		total_aplazados = 0
		total_retirados = 0
		total_no_calificados = 0		
		p "RESULTADO".center(200, "=")
		rows = CSV.parse(csv_text, headers: true, encoding: 'iso-8859-1:utf-8')

		rows.group_by{|row| row[2]}.values.each do |asig|
			id_uxxi = limpiar_cadena asig[0][1]
			if a = Asignatura.where(id_uxxi: id_uxxi).first
				asig.group_by{|sec| sec[2]}.each do |seccion|
					seccion_id = seccion[0]

					unless s = Seccion.where(numero: seccion_id, periodo_id: periodo_id, asignatura_id: id_uxxi).limit(1).first
					
						total_nuevas_secciones += 1 if s = Seccion.create!(numero: seccion_id, periodo_id: periodo_id, asignatura_id: id_uxxi, tipo_seccion_id: 'NF')
					end

					if s
						seccion[1].each do |reg|

							if Estudiante.where(usuario_id: reg.field(0)).count <= 0

								estudiantes_inexistentes << reg.field(0)

							else
								inscrip = s.inscripcionsecciones.where(estudiante_id: reg.field(0)).first
								
								unless inscrip
										inscrip = Inscripcionseccion.new
										inscrip.seccion_id = s.id
										inscrip.estudiante_id = reg.field(0)
										
									if inscrip.save
										total_inscritos += 1
									else
										estudiantes_no_inscritos << reg.field(0)
									end
								else
									total_existentes += 1
								end

								# CALIFICAR:
								if reg.field(3) and ! reg.field(3).blank?
									reg.field(3).strip!
									if reg.field(3).eql? 'RT'
										inscrip.estado = :retirado
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
									elsif inscrip.asignatura and inscrip.asignatura.absoluta?
										if reg.field(3).eql? 'A'
											inscrip.estado = :aprobado
										else
											inscrip.estado = :aplazado
										end
										inscrip.tipo_calificacion_id = TipoCalificacion::FINAL
									else
										inscrip.calificacion_final = reg.field(3)
										
										if inscrip.calificacion_final >= 10
											inscrip.estado = :aprobado
										else
											if inscrip.calificacion_final == 0
												inscrip.tipo_calificacion_id = TipoCalificacion::PI 
											else
												inscrip.tipo_calificacion_id = TipoCalificacion::FINAL 
											end
											inscrip.estado = :aplazado
										end
									end

									if inscrip.save
										total_calificados += 1
										if inscrip.retirado?
											total_retirados += 1
										elsif inscrip.aprobado?
											total_aprobados += 1
										else
											total_aplazados += 1
										end
									else
										total_no_calificados += 1
									end
								end
							end







						end

					else
						secciones_no_creadas << row.to_hash
					end						



				end 
			else
				asignaturas_inexistentes << id_uxxi
			end
		end
  		# puts [group.first['ID'], group.map{|r| r['COMMENT']} * ' '] * ' | '
		
		# rows.each do |row|
		# 	begin
		# 		row = limpiar_fila row
		# 		#p self.separar_cadena(row.field(1))
		# 	rescue Exception => e
		# 		return "Error excepcional: #{e.to_sentence}"
		# 	end
		# end
		p "=".center(200, "=")
	end

	private


	def self.resumen inscritos, existentes, no_inscritos, nuevas_secciones, secciones_no_creadas, estudiantes_inexistentes, asignaturas_inexistentes, total_calificados, total_no_calificados, total_aprobados, total_aplazados, total_retirados, periodo_id, estudiantes_sin_grado
		
		aux = ""
		aux = "</br>
			<b>Resumen:</b>
			</br></br>Período: <b>#{periodo_id}</b>
			</br></br>Total Nuevos Inscritos: <b>#{inscritos}</b>
			</br>Total Existentes: <b>#{existentes}</b>
			</br>Total Nuevas Secciones: <b>#{nuevas_secciones}</b>
			<hr></hr>Total Secciones No Creadas: <b>#{secciones_no_creadas.count}</b>
			<hr></hr>Total Asignaturas Inexistentes: <b>#{asignaturas_inexistentes.uniq.count}</b>
			</br><i>Detalle últimos 50:</i></br> #{asignaturas_inexistentes.uniq.to_sentence}
			<hr></hr>No registrados en la escuela: <b>#{estudiantes_sin_grado.uniq[0..50].to_sentence}</b>
			<hr></hr>Total Estudiantes Inexistentes: <b>#{estudiantes_inexistentes.uniq.count}</b>
			</br><i>Detalle últimos 50:</i></br> #{estudiantes_inexistentes.uniq[0..50].to_sentence}"

		if total_calificados and total_calificados.to_i > 0
			aux += "<hr></hr>Calificaciones:"
			aux += "</br>Total Estudiantes Calificados: <b>#{total_calificados}</b>"
			aux += "</br>Total Estudiantes Aprobados: <b>#{total_aprobados}</b>"
			aux += "</br>Total Estudiantes Aplazados: <b>#{total_aplazados}</b>"
			aux += "</br>Total Estudiantes Retirados: <b>#{total_retirados}</b>"
			aux += "</br>Total Estudiantes No Calificados: <b>#{total_no_calificados}</b>"

		end
		return aux
	end

	def crear_usuario usuario_params
		hay_usuario = false
		if usuario = Usuario.where(ci: usuario_params[:ci]).limit(1).first
			hay_usuario = true
		else
			usuario = Usuario.new
			usuario.ci = usuario_params[:ci]
			usuario.password = usuario_params[:ci]
			usuario.nombres = usuario_params[:nombres]
			usuario.apellidos = usuario_params[:apellidos]
			
			hay_usuario = true if usuario.save
		end

		hay_usuario ? usuario : false

	end



	def self.separar_cadena cadena = nil
		if cadena.blank?
			return [nil,nil]
		else
			cadena = limpiar_cadena cadena
			a = cadena.split(" ")
			t = (a.count)-1
			i = (a.count/2)-1
			i = 0 if i < 0  

			return [a[0..i].join(" "),a[i+1..t].join(" ")]
		end
	end

	def self.limpiar_fila row
		row.field(0).delete! '^0-9'
		row.fields.each{|r| r = limpiar_cadena(r) if r}
		# row.field(1) = limpiar_cadena(row.field(1))
		# row.field(2) = limpiar_cadena row.field(2) if row.field(2)
		# row.field(3) = limpiar_cadena row.field(3) if row.field(3)
		# row.field(4) = limpiar_cadena row.field(4) if row.field(4)

		return row
	end

	def self.limpiar_cadena cadena
		cadena.delete! '^0-9|^A-Za-z|áÁÄäËëÉéÍÏïíÓóÖöÚúÜüñÑ '
		cadena.strip!
		return cadena
	end




end