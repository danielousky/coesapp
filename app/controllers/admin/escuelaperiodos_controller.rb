module Admin
	class EscuelaperiodosController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador
		before_action :filtro_autorizado

		before_action :set_escupe

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