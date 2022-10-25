module Admin
	class EscuelaperiodosController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador
		before_action :filtro_autorizado

		before_action :set_escupe

		def index_reglamento

			@titulo = "Estudiantes que finalizaron el período #{@escupe.periodo_id} incurriendo en artículos de la normativa"
			@grados_con_inscripciones_periodo_anterior = @escupe.escuela.grados.con_inscripciones_en_periodo(@escupe.periodo_id).includes(estudiante: :usuario).order(['usuarios.nombres ASC', 'usuarios.apellidos'])
		end

		def ponderados
			@periodo_ultimo_año_ids = @escupe.periodos_ultimo_año_ids
			@titulo = "Estudiantes incritos en el último año: #{@periodo_ultimo_año_ids.to_sentence} "
			@inscritos_ultimo_año = Inscripcionescuelaperiodo.includes(:usuario, :grado, :escuelaperiodo).where('escuelaperiodos.escuela_id': @escupe.escuela_id, 'escuelaperiodos.periodo_id': @periodo_ultimo_año_ids.last)

		end

		def correr_reglamento
			total_actualizados = 0
			total_error = 0
			Jornadacitahoraria.destroy_all
			@escupe.inscripcionescuelaperiodos.each do |iep|
				reglamento = iep.revisar_reglamento
				grado = iep.grado 

				if grado.update(reglamento: reglamento, eficiencia: grado.calcular_eficiencia, promedio_ponderado: grado.calcular_promedio_ponderado, promedio_simple: grado.calcular_promedio_simple)
					total_actualizados += 1
				else
					total_error += 1
				end
			end

			
			flash[:danger] = 'Errores en la actualización del estado de reglamento' if total_error > 0 
			flash[:success] = "#{ total_actualizados} #{'inscripción'.pluralize(total_actualizados)} en total actualizados" if total_actualizados > 0
			
			redirect_back fallback_location: escuelas_path(@escuela) 
		end

		def borrar_ausentes
			preinscritos = @escupe.escuela.grados.asignado.sin_inscripciones.where(iniciado_periodo_id: @escupe.periodo_id)

			total = preinscritos.count
			if preinscritos.destroy_all
				flash[:success] = "Se eliminaron un total de #{total} registros."
			else
				flash[:danger] = "No se pudo completar la eliminación de los registros. Por favor inténtelo nuevamente o infome al desarrollador del sistema."
			end
			redirect_back fallback_location: escuelas_path
		end

		def show

			if @escupe.id.eql? 77 #77= 2019-02A,Idiomas
				@inscripciones = Inscripcionseccion.por_confirmar.con_totales(@escupe.escuela_id, @escupe.periodo_id)
			else
				@inscripciones = Inscripcionseccion.con_totales(@escupe.escuela_id, @escupe.periodo_id)
			end
			
			@titulo = "Inscripciones para el #{@escupe.periodo_id} en #{@escupe.escuela.descripcion}"
			@titulo += " <span class='badge badge-warning'>#{@inscripciones.size.count}</span>"
			# end

		end

		private

		def set_escupe
			@escupe = Escuelaperiodo.find params[:id]
		end
	end
end