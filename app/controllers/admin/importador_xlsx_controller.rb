module Admin
	class ImportadorXlsxController < ApplicationController
		before_action :filtro_administrador
		before_action :filtro_autorizado#, only: [:importar_seccion, :importar_profesores, :importar_estudiantes]


		def seleccionar_archivo
			@titulo = "Importador - Paso1"
		end

		def importar
			total = ImportCsv.importar_de_archivo params[:datafile].tempfile, params[:objeto]
			flash[:success] = "Total de #{params[:objeto].pluralize} agregadas: #{total}"
			redirect_to action: 'seleccionar_archivo'

		end

		# ==== IMPORTADOR DE SECCIONES ===== #
		def seleccionar_archivo_inscripciones
			@titulo = "Importador de Archivos de Inscripciones"
		end

		def entidades
		
			if params[:entity]
				begin
					result = ImportXslx.general_import params

					flash[:success] = "Registros Procesados: "
					flash[:success] += "#{result[0]}"+ " Nuevo".pluralize(result[0]) + " | "
					flash[:success] += "#{result[1]}"+ " Actualizado".pluralize(result[1])

					if result[2].include? 'limit_records'
						result[2].delete 'limit_records'
						flash[:success] += " | 1 advertencia"

						flash[:warning] = "¡El archivo contiene más de 400 registros! Se procesaron estos primeros 400 y quedaron pendientes el resto. Por favor, divida el archivo y realice una nueva carga. ".html_safe
					end
				
					if result[2].any? 
						flash[:success] += " | #{result[2].count}"+ " con errores."
						flash[:danger] = ""
						if result[2].count > 50
							flash[:danger] += "Más de 50 registros tienen problemas, por lo que no se continuó el proceso de carga. ".html_safe
						end
						flash[:danger] += " A continuación la(s) fila(s):columna(s)  de datos que reportan algún error: #{result[2].to_sentence}."

						# if params[:entity].eql? 'inscripcionsecciones'
						# 	flash[:danger] += " Correbore en el sistema que tanto el código de la asignatura como la cédula del estudiante que desea migrar existen. De no encontrarse la sección se creará siempre y cuando la asignatura exista. Revise los valores de los datos en el archivo de carga e inténtelo nuevamente. "
						# end
					end
				rescue Exception => e
					flash[:danger] = "Error General: #{e}"
				end
			else
				flash[:danger] = 'Tipo de entidad no encontrada. Por favor inténtelo nuevamente.'
			end
			redirect_back fallback_location: root_path

		end

	end
end