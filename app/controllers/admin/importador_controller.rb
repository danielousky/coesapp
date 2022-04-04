module Admin
	class ImportadorController < ApplicationController
		before_action :filtro_administrador
		before_action :filtro_autorizado#, only: [:importar_seccion, :importar_profesores, :importar_estudiantes]

		def index
			@titulo = "Importador"
		end

		def seleccionar_archivo
			@titulo = "Importador - Paso1"
		end

		def importar
			total = ImportCsv.importar_de_archivo params[:datafile].tempfile, params[:objeto]
			flash[:success] = "Total de #{params[:objeto].pluralize} agregadas: #{total}"
			redirect_to action: 'seleccionar_archivo'

		end

		# def vista_previa

		# 	@csv = ImportCsv.preview params[:datafile].tempfile
		# 	@csv_file = params[:datafile].tempfile

		# 	@objeto = params[:objeto].camelize.constantize
		# 	# object.camelize.constantize.create(row.to_hash)
		# 	# ImportCsv.import_from_file params[:datafile].tempfile, params[:objeto]
		# end

		# ==== IMPORTADOR DE SECCIONES ===== #
		def seleccionar_archivo_inscripciones
			@titulo = "Importador de Archivos de Inscripciones"
		end
		def importar_inscripciones

			resultado = ImportCsv.importar_inscripciones params[:datafile].tempfile, params[:escuela_id], params[:periodo_id]

			if resultado[0].eql? 1
				flash[:info] = resultado[1]
			else
				flash[:danger] = resultado[1]
			end
			redirect_to action: 'seleccionar_archivo_inscripciones'
		end

		# ==== IMPORTADOR DE PROFESORES ===== #
		def seleccionar_archivo_profesores
			@titulo = "Importador de Archivos de Profesores"
		end

		def importar_profesores
			resultado = ImportCsv.importar_profesores params[:datafile].tempfile
			if resultado[0].eql? 1
				flash[:info] = resultado[1]
			else
				flash[:danger] = resultado[1]
			end
			redirect_to action: 'seleccionar_archivo_profesores'
		end

		# ==== IMPORTADOR DE ESTUDIANTES ===== #
		def seleccionar_archivo_estudiantes
			@escuelas = current_admin ? current_admin.escuelas : Escuela.all
			@titulo = "Importador de Archivos de Estudiantes por Escuela"
		end

		def importar_estudiantes
			resultado = ImportCsv.importar_estudiantes params[:datafile].tempfile, params[:escuela_id], params[:plan_id], params[:periodo_id], params[:grado], current_admin.id,request.remote_ip, params[:enviar_correo]

			flash[:info] = resultado[0]
			errores = resultado[1]
			if errores.sum.count > 0
				flash[:danger] = "<h6>Algunos inconvenientes en el archivo. Por favor corrija los registros y cargue nuevamente el archivo</h6></br>"
				flash[:danger] += "Usuarios No Agregados (#{errores[0].count}): <b>#{errores[0].to_sentence.truncate(40)}</b><hr></hr>" if errores[0].count > 0
				flash[:danger] += "Estudiantes No Agregados (#{errores[1].count}): <b>#{errores[1].to_sentence.truncate(40)}</b><hr></hr>" if errores[1].count > 0
				flash[:danger] += "Carreras No Agregadas (#{errores[2].count}): <b>#{errores[2].to_sentence.truncate(40)}</b><hr></hr>" if errores[2].count > 0
				flash[:danger] += "Estudiates Con plan_id Errado en total (#{errores[3].count}): <b>#{errores[3].to_sentence.truncate(40)}</b><hr></hr>" if errores[3].count > 0
				flash[:danger] += "Estudiates Con tipo_ingreso Errado (#{errores[4].count}): <b>#{errores[4].to_sentence.truncate(40)}</b><hr></hr>" if errores[4].count > 0
				flash[:danger] += "Estudiates Con iniciado_periodo_id Errado (#{errores[5].count}): <b>#{errores[5].to_sentence.truncate(40)}</b><hr></hr>" if errores[5].count > 0
				flash[:danger] += "Estudiates Con region Errado (#{errores[6].count}): <b>#{errores[6].to_sentence.truncate(40)}</b><hr></hr>" if errores[6].count > 0
				flash[:danger] += "Error General (#{errores[7].count}): <b>#{errores[7].to_sentence.truncate(200)}</b><hr></hr>" if errores[7].count > 0
				flash[:danger] += "Error en las cabeceras:: <b>#{errores[8].to_sentence.truncate(40)}</b><hr></hr>" if errores[8].count > 0
			end

			redirect_to action: 'seleccionar_archivo_estudiantes'
		end

	end
end