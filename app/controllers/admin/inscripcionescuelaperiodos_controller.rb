module Admin
	class InscripcionescuelaperiodosController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador
		before_action :filtro_autorizado

		def index
			if @escuelaperiodo = Escuelaperiodo.find(params[:escuelaperiodo_id])
				if params[:status].eql? TipoEstadoInscripcion::PREINSCRITO or params[:status].eql? TipoEstadoInscripcion::INSCRITO
					@inscripciones = @escuelaperiodo.inscripcionescuelaperiodos.where(tipo_estado_inscripcion_id: params[:status])
				elsif params[:status].eql? 'reported'
					@inscripciones = @escuelaperiodo.inscripcionescuelaperiodos.con_reportepago
				else
					@inscripciones = @escuelaperiodo.inscripcionescuelaperiodos
				end
				@titulo = "Inscripciones para el #{@escuelaperiodo.periodo_id} en #{@escuelaperiodo.escuela.descripcion}"
				@titulo += " <span class='badge badge-warning'>#{@inscripciones.count}</span>"
			else
				flash[:danger] = 'Debe seleccionar una escuela'
				redirect_back fallback_location: escuelas_path
			end
		end

	end
end