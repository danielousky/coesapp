module Admin
	class InscripcionseccionesController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador, except: [:confirmar_inscripcion_idiomas201902A, :preinscribirse, :reservar_cupo]#, only: [:destroy]
		# before_action :filtro_admin_mas_altos!, except: [:destroy]
		# before_action :filtro_ninja!, only: [:destroy]

		# before_action :filtro_autorizado, except: [:index, :buscar_estudiante, :seleccionar, :inscribir, :resumen]
		# before_action :filtro_autorizado_inscribir, only: [:buscar_estudiante, :seleccionar, :inscribir, :resumen]

		before_action :filtro_autorizado, except: [:reservar_cupo]
		before_action :set_inscripcionseccion, only: [:cambiar_seccion]
		before_action :set_estudiante, only: [:seleccionar, :inscribir]
		before_action :set_escuela, only: [:buscar_estudiante,:seleccionar, :inscribir]
		before_action :set_inscripcionescuelaperiodo, only: [:resumen]
		before_action :get_inscripcionperiodo, only: [:seleccionar]
		before_action :set_label_inscripcionperiodo, only: [:seleccionar]

		# def set_pci
		# 	inscripcion = Inscripcionseccion.find params[:inscripcionseccion_id]
		# 	inscripcion.pci_escuela_id = params[:escuela_pci_id]
		# end

		def reservar_cupo
			begin
				asignatura = Asignatura.find params[:asignatura_id]
				grado = Grado.find params[:grado_id].split("-")

				periodo = grado.escuela.periodo_inscripcion
				limite_creditos = periodo.anual? ? 49 : 25
				inscripcion = Inscripcionseccion.joins(:asignatura).joins(:periodo).where("estudiante_id = #{params[:estudiante_id]} AND asignaturas.id = '#{params[:asignatura_id]}' AND periodos.id = '#{periodo.id}'").first

				
				if params[:seccion_id].eql? ''
					if inscripcion and inscripcion.destroy
						msg = "Cupo liberado"
						estado = 'success'
					else
						msg = "Inscripcion no encontrada o no se pudo eliminar. Por favor, inténtelo nuevamente."
						estado = 'error'
					end
				else

					if (inscripcion and inscripcion.inscripcionescuelaperiodo and (inscripcion.inscripcionescuelaperiodo.total_creditos > inscripcion.inscripcionescuelaperiodo.limite_creditos_permitidos))

						estado = 'error'
						msg = "Supera el límite de créditos permitidos por #{inscripcion.escuela.descripcion}. Por favor, corrija su inscripción e inténtelo de nuevo. (#{inscripcion.inscripcionescuelaperiodo.total_creditos} / #{limite_creditos})"
					else
						inscripcion.destroy if inscripcion

						sec = Seccion.find params[:seccion_id]
						unless sec.hay_cupos?
							msg = "Sin cupos disponibles para: #{sec.descripcion} en el período #{sec.periodo.id}"
							estado = 'error'
						else
							ins = Inscripcionseccion.new
							ins.estudiante_id = params[:estudiante_id]
							ins.seccion_id = sec.id
							ins.escuela_id = grado.escuela.id 
							ins.pci_escuela_id = sec.escuela.id if (params[:pci].eql? 'true')
							

							if ins.save
								info_bitacora "Cupo Reservado para la sección #{ins.seccion.descripcion_simple}.", Bitacora::CREACION, ins
								if ins.inscripcionescuelaperiodo and ins.inscripcionescuelaperiodo.update(tipo_estado_inscripcion_id: TipoEstadoInscripcion::RESERVADO)
									msg = "Cupo reservado"
									estado = 'success'
								else
									estado = 'error'
									msg = "Error: #{ins.inscripcionescuelaperiodo.errors.full_messages.to_sentence}"
								end
							else
								estado = 'error'
								msg = "Error: #{ins.errors.full_messages.to_sentence}"
							end
						end

					end			


				end

			rescue Exception => e
				estado = 'error'
				msg = "Error: #{e}"				
			end
			cupo = sec ? sec.descripcion_con_cupos : 'Seleccione'
			respond_to do |format|

				format.json do 
					render json: {data: msg, status: estado, cupo: cupo}
				end

			end

		end

		def preinscribirse
			escupe = Escuelaperiodo.find(params[:escuelaperiodo_id])
			any_error = false
			inscripcionescuelaperiodo = escupe.inscripcionescuelaperiodos.where(estudiante_id: params[:estudiante_id]).first
			if inscripcionescuelaperiodo.nil?
				flash[:danger] = 'No realizó inscripción alguna. Por favor, selección las asignaturas e inténtelo nuevamente. Tenga en cuenta que al seleccionar una sección en cada asignatura, debe aparecer un mensaje afirmativo de completación de la reserva del cupo.'
			elsif !inscripcionescuelaperiodo.inscripcionsecciones.any?
				flash[:danger] = 'Sin selección se asignaturas. Por favor, selección alguna asignaturas e inténtelo nuevamente. Tenga en cuenta que al seleccionar una sección en cada asignatura, debe aparecer un mensaje afirmativo de completación de la reserva del cupo.'
				any_error = true
				
			elsif (inscripcionescuelaperiodo.total_creditos > escupe.limite_creditos_permitidos)
				flash[:danger] = "Supera el límite de créditos permitidos por #{inscripcion.escuela.descripcion}. Por favor, corrija su inscripción e inténtelo de nuevo. Se procede a anular las selecciones previas."
				
				any_error = true
			elsif (inscripcionescuelaperiodo.update(tipo_estado_inscripcion_id: TipoEstadoInscripcion::PREINSCRITO))
				info_bitacora "Estudiante #{inscripcionescuelaperiodo.estudiante_id} Preinscrito en el periodo #{inscripcionescuelaperiodo.periodo.id} en #{inscripcionescuelaperiodo.escuela.descripcion}.", Bitacora::CREACION, inscripcionescuelaperiodo
				begin
					info_bitacora "Envío de correo de Preinscripcion #{inscripcionescuelaperiodo.estudiante_id} Preinscrito en el periodo #{inscripcionescuelaperiodo.periodo.id} en #{inscripcionescuelaperiodo.escuela.descripcion}.", Bitacora::CREACION, inscripcionescuelaperiodo if EstudianteMailer.preinscrito(inscripcionescuelaperiodo.estudiante.usuario, inscripcionescuelaperiodo).deliver
					
				rescue Exception => e
					flash[:warning] = "Correo de completación de proceso de preinscripción no enviado: #{e}" 
				end
				flash[:success] = "Proceso de preinscripción completado con éxito. El personal administrativo revisará su expediente y confirmará su inscripción."
				flash[:info] = "Asignaturas Inscritas: #{inscripcionescuelaperiodo.total_asignaturas}. Créditos Inscritos: #{inscripcionescuelaperiodo.total_creditos}"
			else
				flash[:danger] = "Error al intentar completar el procesos de preinscripción: #{inscripcionescuelaperiodo.errors.full_messages.to_sentence}"
				any_error = true
			end
			inscripcionescuelaperiodo.destroy if any_error
			redirect_back fallback_location: '/principal_estudiante'
		end

		# def preinscribirse_original
		# 	params[:secciones] = params[:secciones].reject{|a| a.blank? }
		# 	begin
		# 		flash[:danger] = ""
		# 		unless @grado = Grado.find([params[:estudiante_id], params[:escuela_id]])
		# 			flash[:danger] += 'El estudiante no se encuentra registrado en la escuela solicitada'

		# 		else
		# 			estudiante = @grado.estudiante
		# 			escuela = @grado.escuela
		# 			if escuela.inscripcion_cerrada?
		# 				flash[:danger] += "Inscripción cerrada para #{escuela.descripcion}"

		# 			else
		# 				periodo = escuela.periodo_inscripcion
		# 				periodo_id = periodo.id
		# 				limiteCreditos = periodo.anual? ? 49 : 25

		# 				if params['total_creditos'].to_i > limiteCreditos 
		# 					flash[:danger] += "Supera el límite de créditos permitidos por #{escuela.descripcion}. Por favor, corrija su inscripción e inténtelo de nuevo."
		# 				else
		# 					# ins_periodo = estudiante.inscripcionescuelaperiodos.del_periodo(periodo_id).first

		# 					ins_periodo = Inscripcionescuelaperiodo.find_or_new(escuela.id, periodo_id, estudiante.id)

		# 					ins_periodo.tipo_estado_inscripcion_id = TipoEstadoInscripcion::PREINSCRITO

		# 					if ins_periodo.save
		# 						asign_inscritas_ids = []
		# 						flash[:warning] = ""
		# 						if params[:secciones]
		# 							params[:secciones].each do |seccion_id|
		# 								seccion = Seccion.find(seccion_id)
		# 								unless seccion.hay_cupos?
		# 									flash[:warning] += "Sin cupos disponibles para: #{seccion.descripcion_simple} en el período #{periodo_id}"
		# 								else
		# 									inscripcion = ins_periodo.inscripcionsecciones.where(seccion_id: seccion.id, estudiante_id: estudiante.id).first
		# 									unless

		# 										inscripcion = Inscripcionseccion.new()
		# 										inscripcion.seccion_id = seccion.id
		# 										inscripcion.estudiante_id = estudiante.id
		# 										inscripcion.inscripcionescuelaperiodo_id = ins_periodo.id
		# 										inscripcion.escuela_id = escuela.id
		# 									end

		# 									if inscripcion.save
		# 										info_bitacora "Prenscrito en la sección #{inscripcion.seccion.descripcion_simple} exitosamente.", Bitacora::CREACION, inscripcion
		# 										asign_inscritas_ids << seccion.asignatura.id
		# 									else
		# 										flash[:danger] += "Error al intentar inscribir en la sección: #{inscripcion.errors.full_messages.to_sentence}"
		# 									end
		# 								end
		# 							end
		# 						end

		# 						unless asign_inscritas_ids.any? 
		# 							ins_periodo.destroy
		# 							flash[:danger] += " No se completó ninguna inscripción. Por favor inténtelo nuevamente."
		# 						else
		# 							begin
		# 								info_bitacora "Preinscrito en el periodo #{ins_periodo.periodo.id} en #{ins_periodo.escuela.descripcion} exitosamente.", Bitacora::CREACION, ins_periodo
		# 								EstudianteMailer.preinscrito(estudiante.usuario, ins_periodo).deliver
		# 							rescue Exception => e
		# 								flash[:danger] += " No se pudo enviar el correo asociado: #{e}"
		# 							end
		# 							flash[:info] = "Proceso de inscripción completado con éxito. Total asignaturas preinscritas: #{asign_inscritas_ids.count}. "
		# 						end

		# 						# reporte = Reportepago.new()
		# 						# reporte.numero = params[:reportepago][:numero]
		# 						# reporte.tipo_transaccion = params[:reportepago][:tipo_transaccion]
		# 						# reporte.fecha_transaccion = params[:reportepago][:fecha_transaccion]
		# 						# reporte.respaldo = params[:reportepago][:respaldo]
		# 						# reporte.inscripcionescuelaperiodo_id = ins_periodo.id

		# 						# if reporte.save
		# 						# 	flash[:success] = " Reporte de pago generado con éxito."
		# 						# else
		# 						# 	flash[:danger] += "Error al intentar guardar el reporte de pago: #{ins_periodo.errors.full_messages.to_sentence}"
		# 						# end
		# 					else
		# 						flash[:danger] += " Error al intentar registar la inscripción: #{ins_periodo.errors.full_messages.to_sentence}"
		# 					end

		# 				end
		# 			end
		# 		end

		# 	rescue Exception => e
		# 		flash[:danger] = e
		# 	end
		# 	flash[:danger] = nil if flash[:danger].blank?
		# 	flash[:warning] = nil if flash[:warning].blank?
		# 	redirect_back fallback_location: '/principal_estudiante'
		# end


		def confirmar_inscripcion_idiomas201902A

			# descripcion_eliminadas = []
			@estudiante = Estudiante.find params[:estudiante_id]

			inscripcion_del_periodo = Inscripcionescuelaperiodo.find_or_new('IDIO', '2019-02A', @estudiante.id)

			if inscripcion_del_periodo.update(tipo_estado_inscripcion_id: TipoEstadoInscripcion::INSCRITO)
				flash[:success] = "Inscripción en el período 2019-02A para Idiomas Modernos en la modalidad Online confirmada con éxito." 

				info_bitacora "Estudiante #{inscripcion_del_periodo.estudiante_id} Confirmado en el periodo #{inscripcion_del_periodo.periodo.id} en #{inscripcion_del_periodo.escuela.descripcion}.", Bitacora::CREACION, inscripcion_del_periodo

				inscripcionsecciones = @estudiante.inscripciones.del_periodo('2019-02A').where(inscripcionescuelaperiodo_id: nil)
				if inscripcionsecciones.any?
					total_confirmadas = 0
					total_eliminadas = 0

					inscripcionsecciones.each do |insc|
						if params[:inscripciones] and params[:inscripciones].values.include? "#{insc.id}"
							total_confirmadas += 1 if insc.update(inscripcionescuelaperiodo_id: inscripcion_del_periodo.id)
						else
							# descripcion_eliminadas << insc.seccion.descripcion
							total_eliminadas += 1 if insc.destroy
						end
					end
					
					begin
						EstudianteMailer.ratificacionEIM201902A(@estudiante).deliver_now
						info_bitacora "Envío de correo de Confirmación de Inscripción de #{inscripcion_del_periodo.estudiante_id} en el periodo #{inscripcion_del_periodo.periodo.id} en #{inscripcion_del_periodo.escuela.descripcion}.", Bitacora::CREACION, inscripcion_del_periodo
						msg_email = ' Correo enviado con la información resumen.'
						
					rescue Exception => e
						msg_email = "No se pudo enviar el email: #{e}"
					end
					
					if total_confirmadas.eql? 0
						flash[:info] = "No se confirmaron asignaturas. "
					else
						flash[:info] = "Se confirmaron un total de #{total_confirmadas} asignaturas. "
					end
					if total_eliminadas.eql? 0
						flash[:info] += "No se eliminaron asignaturas. "
					else
						flash[:info] += "Se eliminaron #{total_eliminadas} en total. "
					end
					flash[:info] += msg_email
				else
					flash[:danger] = "Sin inscripciones en el período 2019-02A en Idiomas Modernos por confirmar."
				end

			else
				flash[:danger] = "No se pudo confirmar la inscripción: #{inscripcion_del_periodo.errors.full_messages.to_sentence}"
			end


			
			redirect_back fallback_location: '/principal_estudiante'
		end

		def cambiar_seccion
			seccion_anterior = @inscripcionseccion.seccion
			@inscripcionseccion.seccion_id = params[:inscripcionseccion][:seccion_id]
			if @inscripcionseccion.save
				flash[:success] = 'Cambio de sección exitoso'
				info_bitacora "Cambio de sección de la #{seccion_anterior.descripcion} (#{seccion_anterior.id}) a la #{@inscripcionseccion.seccion.descripcion} (#{@inscripcionseccion.seccion.id}) al estudiante #{@inscripcionseccion.estudiante.usuario.descripcion}" , Bitacora::ACTUALIZACION, @inscripcionseccion
			else
				flash[:danger] = "Error al intentar realizar el cambio en la inscripción: #{@inscripcionseccion.errors.full_messages.to_sentence}"
			end
			redirect_back fallback_location: @inscripcionseccion.estudiante.usuario
		end

		def set_escuela_pci
			inscripcion = Inscripcionseccion.find params[:id]
			inscripcion.pci_escuela_id = params[:pci_escuela_id]

			inscripcion.escuela_id = params[:pci_escuela_id]

			inscripcion.pci = true

			# respond_to do |format|
			# 	if inscripcion.save
			# 		format.json {render json: {html: '¡Asociación exitosa!'}, status: :ok}
			# 	end
			# end

			if inscripcion.save
				flash[:success] = '¡Escuela asignada a Pci!'
			else
				flash[:error] = "Error: #{inscripcion.errors.full_messages.to_sentence}"
			end
			redirect_back fallback_location: inscripcion.estudiante.usuario 
		end

		def index
			@escuela = Escuela.find params[:escuela_id]

			@inscripciones = @escuela.inscripcionsecciones.con_totales(@escuela_id, params[:periodo_id])

			@titulo = "Inscripciones para el período #{params[:periodo_id]} en la escuela #{@escuela.descripcion} (#{@inscripciones.size.count})"

		end

		def cambiar_calificacion

			inscripcion = Inscripcionseccion.find params[:inscripcionseccion_id]

			if inscripcion.asignatura.numerica3? and params[:tipo_calificacion_id].eql? TipoCalificacion::PARCIAL
				params[:valor] = nil if params[:valor].eql? '-1'
				inscripcion[params[:calificacion_parcial]] = params[:valor]

				if params[:calificacion_parcial].eql? 'primera_calificacion'
					inscripcion.estado = :trimestre1
					p 'solicitud de modificacion de estado a trimestre1'
				elsif params[:calificacion_parcial].eql? 'segunda_calificacion'
					inscripcion.estado = :trimestre2
					p 'solicitud de modificacion de estado a trimestre2'
				else
					if params[:valor].nil?
						if inscripcion.segunda_calificacion
							inscripcion.estado = :trimestre2
						elsif inscripcion.primera_calificacion
							inscripcion.estado = :trimestre1
						else
							inscripcion.estado = 'sin_calificar'
						end
					end
				end

				inscripcion.calificacion_final = nil if (inscripcion.primera_calificacion.nil? or inscripcion.segunda_calificacion.nil? or inscripcion.tercera_calificacion.nil?)

			elsif inscripcion.seccion.asignatura.absoluta?
				inscripcion.estado = Inscripcionseccion.estados.key params[:calificacion_final].to_i
				inscripcion.calificacion_posterior = nil
				inscripcion.calificacion_final = inscripcion.aprobado? ? 20 : 1
			else
				params[:tipo_calificacion_id] = 'NF' if params[:tipo_calificacion_id].nil?

				if (params[:tipo_calificacion_id].eql? TipoCalificacion::DIFERIDO) or (params[:tipo_calificacion_id].eql? TipoCalificacion::REPARACION)
					calificacion_anterior = inscripcion.calificacion_posterior
					inscripcion.calificacion_posterior = params[:calificacion_posterior] ? params[:calificacion_posterior].to_i : params[:calificacion_final].to_i

				elsif params[:tipo_calificacion_id].eql? TipoCalificacion::PI
					calificacion_anterior = inscripcion.calificacion_final
					inscripcion.calificacion_final = 1 
					params[:calificacion_final] = 1
					inscripcion.calificacion_posterior = nil 
				else
					calificacion_anterior = inscripcion.calificacion_final
					inscripcion.calificacion_final = params[:calificacion_final].to_i
					inscripcion.calificacion_posterior = nil
				end

				if inscripcion.calificacion_final.to_i.eql? 0 or inscripcion.calificacion_final.nil?

					inscripcion.primera_calificacion = inscripcion.calificacion_final
					inscripcion.segunda_calificacion = inscripcion.calificacion_final
					inscripcion.tercera_calificacion = inscripcion.calificacion_final

				end

				inscripcion.estado = inscripcion.estado_segun_calificacion
			end

			inscripcion.tipo_calificacion_id = params[:tipo_calificacion_id]

			respond_to do |format|

				format.html {
					if inscripcion.save

						info_bitacora "Se cambió la calificación del estudiante #{inscripcion.estudiante.usuario.descripcion} de la sección #{inscripcion.seccion.descripcion}. Calificacion anterior: #{calificacion_anterior}" , Bitacora::ESPECIAL, inscripcion, params[:comentario]
						flash[:success] = 'Calificación modificada con éxito'

					else
						flash[:danger] = 'Error al intentar modificar la calificación. Por favor verifica e inténtalo nuevamente.'
					end
					redirect_to inscripcion.seccion
				}

				format.json {render json: inscripcion.save, status: :ok}
			end
		end
		
		def buscar_estudiante
			@titulo = "Inscripción en #{@escuela.id} para el período #{current_periodo.id} Buscar Estudiante:"
			@estudiantes = Estudiante.last(5).sort_by{|e| e.usuario.apellidos}
		end

		def seleccionar
			session[:inscripcion_estudiante_id] = @estudiante.id
			@asignatura = Asignatura.find session[:asignatura] if session[:asignatura]
			
			inscripciones = @estudiante.inscripciones.de_la_escuela(@escuela.id)
			@inscripciones = inscripciones.del_periodo(current_periodo.id) 

			if inscripciones
				@ids_asignaturas = @inscripciones.collect{|i| i.seccion.asignatura_id} 
				@ids_aprobadas = inscripciones.aprobadas.collect{|i| i.seccion.asignatura_id}
				@incritar_o_aprobadas = ((@ids_aprobadas and (@ids_aprobadas.include? session[:asignatura])) or (@ids_asignaturas and (@ids_asignaturas.include? session[:asignatura])))
			end

			@titulo = "Inscripción en #{@escuela.descripcion} para el período #{current_periodo.id} - Seleccionar Secciones"
			@escuelas = Escuela.where(id: @escuela.id)
			@escuelas = current_admin.escuelas.merge @escuelas

			@creditLimits = current_periodo.anual? ? 49 : 25

			aux = current_periodo.escuelas.merge @estudiante.escuelas

			# @creditLimits = 31 if aux.ids.include? 'COMU'
			@creditLimits *= aux.count
		end

		def inscribir
			secciones = params[:secciones]
			guardadas = 0
			# id = params[:id]
			asignaturas_pci_error = []
			asignaturas_impropias = []

			begin
				flash[:success] = ''
				flash[:danger] = ''
				# escuelaperiodo = Escuelaperiodo.where(escuela_id: @escuela.id, periodo_id: current_periodo.id).first
				# Acá se puede usar el método find_or_create_by 
				# @inscripciones_del_periodo = Inscripcionescuelaperiodo.find_or_create_by(escuelaperiodo_id: escuelaperiodo.id, estudiante)
				# El tema es que debe incluirsele un tipo_estado_inscripcion_id por defecto que aún no está definido.

				se_preinscribio = false
				# inscripcion_del_periodo = @estudiante.inscripcionescuelaperiodos.de_la_escuela_y_periodo(escuelaperiodo.id).first

				# if inscripcion_del_periodo.nil?
				# 	inscripcion_del_periodo = @estudiante.inscripcionescuelaperiodos.new
				# 	inscripcion_del_periodo.escuelaperiodo = escuelaperiodo

				# else
				# 	se_preinscribio = true if inscripcion_del_periodo.tipo_estado_inscripcion_id.eql? 'PRE'
				# end

				inscripcion_del_periodo = Inscripcionescuelaperiodo.find_or_new(@escuela.id, current_periodo.id, @estudiante.id)

				se_preinscribio = true if inscripcion_del_periodo.tipo_estado_inscripcion_id.eql? TipoEstadoInscripcion::PREINSCRITO
				
				inscripcion_del_periodo.tipo_estado_inscripcion_id = TipoEstadoInscripcion::INSCRITO

				flash[:success] = "Inscripción en el período #{current_periodo.id} para la escuela #{@escuela.descripcion} realizada con éxito." if inscripcion_del_periodo.save

				inscripcionsecciones = @estudiante.inscripciones.del_periodo(current_periodo.id).where(inscripcionescuelaperiodo_id: nil)
				if inscripcionsecciones.any?
					if inscripcionsecciones.update(inscripcionescuelaperiodo_id: inscripcion_del_periodo.id)
						flash[:success] += "  | Confirmas #{inscripcion_del_periodo.inscripcionsecciones.count} preinscripciones"
					end
				end

				if secciones
					secciones.each_pair do |sec_id, pci_escuela_id|
						seccion = Seccion.find sec_id

						ins = Inscripcionseccion.new
						ins.seccion_id = seccion.id
						ins.estudiante_id = @estudiante.id
						ins.inscripcionescuelaperiodo_id = inscripcion_del_periodo.id

						if pci_escuela_id and !(pci_escuela_id.eql? 'on')

							unless seccion.pci?
								# Error:
								asignaturas_pci_error << seccion.asignatura_id
							else
								escuela = Escuela.find pci_escuela_id
								ins.pci_escuela_id = escuela.id 
								ins.escuela_id = escuela.id
								ins.pci = true 
							end

						elsif ins.estudiante.escuelas.include? seccion.escuela
							ins.escuela_id = seccion.escuela.id
						else
							asignaturas_impropias << seccion.asignatura_id
						end
						volumen = seccion.capacidad.to_i - seccion.total_estudiantes.to_i

						if volumen <= 0 and !(current_admin and current_admin.maestros?)
							flash[:danger] += "Se superó la capacidad de la sección por favor amplíela o indíquele a su superior para realizar la inscripción"
						else
							if ins.save
								info_bitacora "Inscripción (Confimación) en #{ins.seccion.descripcion} (#{ins.asignatura.id}). Id inscripcion: #{ins.id}" , Bitacora::CREACION, ins
								guardadas += 1
							else
								flash[:danger] += ins.errors.full_messages.to_sentence
							end
						end
						flash[:info] = "Para mayor información vaya al detalle del estudiante haciendo clic <a href='#{usuario_path(@estudiante.id)}' class='btn btn-primary btn-sm'>aquí</a> "
					end 

					flash[:success] += " |  Estudiante inscrito desde admin en #{guardadas} seccion(es)"
					flash[:danger] += "La(s) asignatura(s) con código(s): #{asignaturas_pci_error.to_sentence} se intenta(n) inscribir como PCI, sin embargo para este periodo no está(n) ofertada(s) como tal. Por favor, corrija el error e inténtelo de nuevo." if asignaturas_pci_error.any?
					
					flash[:danger] += "La(s) asignatura(s) con código(s): #{asignaturas_impropias.to_sentence} se intenta(n) inscribir inapropiadamente. Por favor, corrija el error e inténtelo nuevamente." if asignaturas_impropias.any?


				end


			rescue Exception => e
				flash[:danger] += "Error general: #{e}"
			end


			if se_preinscribio and inscripcion_del_periodo.tipo_estado_inscripcion_id.eql? 'INS' and inscripcion_del_periodo.inscripcionsecciones.any?
				begin
					info_bitacora "Confirmación inscripción estudiante #{inscripcion_del_periodo.estudiante_id} en periodo #{inscripcion_del_periodo.periodo.id} en #{inscripcion_del_periodo.escuela.descripcion}.", Bitacora::CREACION, inscripcion_del_periodo


					if EstudianteMailer.confirmado(@estudiante, inscripcion_del_periodo).deliver
						info_bitacora "Se envió correo de confirmacion de inscripción estudiante #{inscripcion_del_periodo.estudiante_id} en periodo #{inscripcion_del_periodo.periodo.id} en #{inscripcion_del_periodo.escuela.descripcion}.", Bitacora::CREACION, inscripcion_del_periodo
					end
				rescue Exception => e
					flash[:danger] += "No se pude enviar el email: #{e}"
				end
			end
			flash[:success] = nil if flash[:success].blank?
			flash[:danger] = nil if flash[:danger].blank?

			unless flash[:danger].blank?
				redirect_back fallback_location: "/inscripcionsecciones/resumen?id=#{params[:id]}"
			else
				redirect_to action: :resumen, id: inscripcion_del_periodo.id
			end

		end

		def resumen
			session[:inscripcion_estudiante_id] = nil

			@periodo = @inscripcionperiodo.periodo
			@escuela = @inscripcionperiodo.escuela
			@estudiante = @inscripcionperiodo.estudiante
			@inscripciones = @inscripcionperiodo.inscripcionsecciones.del_periodo(@periodo.id).de_la_escuela(@escuela.id)
			# @secciones = @estudiante.inscripcionsecciones.del_periodo current_periodo.id
			@titulo = "Resumen Inscripción #{@estudiante.usuario.descripcion} en #{@escuela.descripcion} para el período #{@periodo.id}:"

			@label_inscripcionperiodo = "Estado de Inscripción: <div class= 'badge badge-info'>#{@inscripcionperiodo.tipo_estado_inscripcion.descripcion.titleize}</div>".html_safe if (@inscripcionperiodo.tipo_estado_inscripcion)

		end

		# def nuevo
		# 	@accion = params[:accion]
		# 	@controlador = params[:controlador]
		# 	@secciones = CalSeccion.all
		# 	@estudiante = CalEstudiante.find(params[:ci])
		# end

		def crear
			id = params[:estudiante_id]
			seccion_id = (params[:seccion][:id]).to_i
			if Inscripcionseccion.where(estudiante_id: id, seccion_id: seccion_id).limit(1).first
				flash[:error] = "El Estudiante ya esta inscrito en esa sección"
			else
				ins = Inscripcionseccion.new
				ins.estudiante_id = id
				ins.seccion_id = seccion_id
				if !(ins.estudiante.escuelas.include? ins.seccion.escuela)
					flash[:danger] = 'La asignatura debe pertenecer a la Escuela'
				else
					ins.escuela_id = ins.seccion.escuela.id
					if ins.save
						flash[:success] = "Estudiante inscrito satisfactoriamente"
						info_bitacora "Inscripción directa en #{ins.seccion.descripcion} (#{ins.asignatura.id}). Id inscripcion: #{ins.id}" , Bitacora::CREACION, ins.estudiante
					else
						flash[:danger] = "Error al intentar inscribir en la sección: #{ins.errors.full_messages.to_sentence}"
					end
				end
			end
			redirect_back fallback_location: "/usuarios/#{id}"
		end

		def destroy
			es = Inscripcionseccion.find params[:id]
			sec = es.seccion
			est = es.estudiante 
			if es.destroy
				info_bitacora "Eliminada inscripción en #{sec.descripcion} (#{sec.asignatura_id})" , Bitacora::ELIMINACION, est

				flash[:info] = "Inscripción eliminado satisfactoriamente"
			else
				flash[:danger] = "El estudiante no pudo ser eliminado: #{es.errors.full_messages.to_sentence}"
			end
			redirect_back fallback_location: est.usuario

		end

		def cambiar_estado
			if es = Inscripcionseccion.find(params[:id])
				estado_anterior = es.estado
				es.estado = Inscripcionseccion.estados.key params[:estado].to_i

				if es.save
					flash[:success] = "Se guardó el estado #{es.estado} del estudiante #{es.estudiante.usuario.descripcion} en la sección #{es.seccion.descripcion}."
					info_bitacora "Cambio de estado del estudiante #{es.estudiante_id} de #{estado_anterior} a #{es.estado}", Bitacora::ACTUALIZACION, es
				else
					flash[:error] = "No se pudo cambiar el valor de retiro, intentelo de nuevo: #{es.errors.full_messages.join' | '}"
				end
			else
				flash[:error] = "El estudiante no fue encontrado en la sección especificada"
			end

			if es.grado.posible_graduando?
				tr = view_context.render partial: '/admin/grados/detalle_registro', locals: {registro: es.grado, estado: 2}
			elsif es.grado.tesista?
				tr = view_context.render partial: '/admin/grados/detalle_registro', locals: {registro: es.grado, estado: 1}
			else
				tr = ''
			end

			respond_to do |format|
				format.html { redirect_to es.estudiante.usuario}
				format.json do 
					flash[:success] = flash[:error] = nil
					msg = "Cambio de estado de #{es.estudiante.usuario.descripcion}"
					render json: {tr: tr, msg: msg}, status: :ok 
				end

			end
		end

		private

		def set_inscripcionescuelaperiodo
			@inscripcionperiodo = Inscripcionescuelaperiodo.find params[:id]
		end

		def set_escuela
			@escuela = Escuela.where(id: params[:escuela_id]).first

			if @escuela.nil?
				flash[:danger] = "Escuela no encontrada"
				redirect_back fallback_location: periodos_path
			end


		end

		def get_inscripcionperiodo
			@inscripcionperiodo = @estudiante.inscripcionescuelaperiodos.del_periodo(current_periodo.id).first if @estudiante
		end

		def set_label_inscripcionperiodo
			@label_inscripcionperiodo = "Estado de Inscripción:<div class= 'badge badge-info'>#{@inscripcionperiodo.tipo_estado_inscripcion.descripcion.titleize}</div>".html_safe if (@inscripcionperiodo and @inscripcionperiodo.tipo_estado_inscripcion)
		end
		def set_estudiante
			@estudiante = Estudiante.where(usuario_id: params[:id]).limit(1).first
		end

		def set_inscripcionseccion
			@inscripcionseccion = Inscripcionseccion.find(params[:id])
		end

	end
end