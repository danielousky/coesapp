module Admin
	class PrincipalEstudianteController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_estudiante

		def oferta_academica
			@grado = Grado.find(params[:id])
			if @grado
				@escuela = @grado.escuela
				@estudiante = @grado.estudiante

				if @escuela and @estudiante
					
					if current_usuario.estudiante and (current_usuario.ci.eql? @estudiante.usuario_id)

						if @periodo_inscripcion = @escuela.periodo_inscripcion

							if @escupe = @escuela.escuelaperiodos.where(periodo_id: @periodo_inscripcion.id).first

								periodo_anterior = @escuela.periodo_anterior @periodo_inscripcion.id

								@jornada_horaria_actual = @escupe.jornadacitahorarias.del_dia.first

								inscripcion_permitida_por_citahoraria = (!@jornada_horaria_actual.nil? and !@grado.citahoraria.nil? and @jornada_horaria_actual.puede_inscribir? @grado.citahoraria)
								
								con_inscripciones_en_periodo_anterior = @grado.inscripciones.del_periodo(periodo_anterior.id).any?


								valido_inscripcion_regular = (@jornada_horaria_actual.nil? and (@grado.confirmado? or @grado.reincorporado?) and (!@grado.inscripciones.any? or con_inscripciones_en_periodo_anterior))

								autorizado_especial = (@grado.autorizar_inscripcion_en_periodo_id.eql? @periodo_inscripcion.id)
									
								inscripcion_en_proceso = !@inscripcionperiodo.nil? and @inscripcionperiodo.reservado?

								permitida = !(@grado.articulo_7? or @grado.articulo_6? or @grado.iniciado_periodo_id.eql? @periodo_inscripcion.id)

								#NOTA INTERNA: La siguiente línea no funciona con or. por lo que fue cambiada a || 
								#Tiene que ver con que el or pareciera un or exclusivo, es decir que tienen que ser todos true
								inscripcion_regular_permitida = valido_inscripcion_regular or inscripcion_en_proceso

								if autorizado_especial or (permitida and inscripcion_permitida_por_citahoraria or inscripcion_regular_permitida)

									@inscripcionperiodo = @estudiante.inscripcionescuelaperiodos.where(escuelaperiodo_id: @escupe.id).first

									@limiteCreditos = @escupe.limite_creditos_permitidos
									@limiteAsignaturas = @escupe.limite_asignaturas_permitidas
									
									# Habilitadas depedencias?
									if @escuela.dependencias_habilitadas?
										asignaturas_ofertables_segun_dependencia = @grado.asignaturas_ofertables_segun_dependencia
										@asignaturas_ofertadas_x_escuela = @escuela.asignaturas.activas(@periodo_inscripcion.id).order(anno: :asc)
										@asignaturas_ofertadas_x_escuela = @asignaturas_ofertadas_x_escuela.merge(asignaturas_ofertables_segun_dependencia)

									else
										@asignaturas_ofertadas_x_escuela = @escuela.asignaturas.activas(@periodo_inscripcion.id).order(anno: :asc )
									end

									# Con inscripción en proceso
									if @inscripcionperiodo.nil? or (@inscripcionperiodo and @inscripcionperiodo.reservado?)

										@totalCreditosReservados = @inscripcionperiodo ? @inscripcionperiodo.total_creditos : 0
										@totalAsignaturasReservadas = @inscripcionperiodo ? @inscripcionperiodo.total_asignaturas : 0
										periodo_anterior = @escuela.periodo_anterior @periodo_inscripcion.id
									end


									@inscripciones = @estudiante.inscripcionsecciones.joins(:escuela).where("escuelas.id = :e or pci_escuela_id = :e", e: @escuela.id)
										
									@aprobadas = @inscripciones.aprobadas.includes(:seccion).map{|s| [s.id, s.seccion.asignatura_id]}.uniq.flatten

									@titulo = "Proceso de Preinscripción #{@periodo_inscripcion.id}"
								else
									flash[:danger] = 'Inhabilitado para inscribirse en este momento.'
								end

							else
								flash[:danger] = 'Periodo Académico no disponible'
							end
						else
							flash[:danger] = 'Inscripción Cerrada'
						end

					else
						descripcion = "ATENCIÓN: Intento de inscripción suplantando identidad: Usuario CI #{current_usuario.ci} a Estudiante CI=#{@estudiante.usuario_id}."
						tipo = Bitacora::CREACION
						info_bitacora descripcion, tipo, @estudiante
						flash[:danger] = 'ATENCIÓN: Intento de suplantación de identidad de un estudiante. La acción será guardada en los registros del sistema!'
					end
				else
					flash[:danger] = '¡Imposible encontrar estudiante o la escuela indicada!'
				end
			else
				flash[:danger] = '¡Dato inválido!'
			end

			if flash[:danger]
				redirect_back fallback_location: principal_estudiante_index_path
			end
			
		end

		def index

			@usuario = Usuario.find session[:estudiante_id]

			@nickname = @usuario.nickname.capitalize

			if (current_usuario.datos_incompletos? or (current_usuario.estudiante and current_usuario.estudiante.direccion.blank?))

				redirect_to controller: :usuarios, action: :edit, id: @usuario.id
			else
				usuario = Usuario.find session[:estudiante_id]
				estu = usuario.estudiante
				@estudiante = @usuario.estudiante #Estudiante.where(usuario_ci: session[:usuario_id]).limit(1).first
				
				@titulo = "#{@usuario.descripcion} - #{@estudiante.escuelas.collect{|es| es.descripcion}.to_sentence.upcase}"

				# @periodos = Periodo.order("inicia DESC").all
				# @inscripciones = Inscripcionseccion.joins(:seccion).where(estudiante_id: @estudiante.usuario_id).order("secciones.asignatura_id DESC")
				
				# @inscripciones = @estudiante.inscripcionsecciones
				@periodos = Periodo.joins(:inscripcionseccion).where("inscripcionsecciones.estudiante_id = #{@estudiante.id}")

				@total = @estudiante.inscripcionsecciones.count

				# OJO: Parche para el caso en que no tengan inscripcionsecciones y si tengan inscripcionescuelaperiodos
				# if @total.eql? 0
				# 	aux = @estudiante.inscripcionescuelaperiodos
				# 	aux.destroy_all if aux.any?
				# end
			end

		end

		def actualizar_idiomas
			estudiante = Estudiante.find params[:principal_estudiante_id]
			idiomas = params[:estudiante]
			if estudiante.combinaciones.create(periodo_id: current_periodo.id, idioma1_id: idiomas[:idioma1], idioma2_id: idiomas[:idioma2] )
				flash[:success] = "Combinación guardada con éxito."
			else
				flash[:error] = "No se pudo guardar la combinación. Diríjase al personal administrativo."
			end

			redirect_to action: :index

		end

	end
end