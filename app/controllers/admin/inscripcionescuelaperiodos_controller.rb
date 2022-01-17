module Admin
	class InscripcionescuelaperiodosController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador
		before_action :filtro_autorizado

		def index
			
			if @escuelaperiodo = Escuelaperiodo.find(params[:escuelaperiodo_id])
				@inscripciones = @escuelaperiodo.inscripcionescuelaperiodos
				@titulo = "Total Estudiantes #{@escuelaperiodo.periodo_id} - #{@escuelaperiodo.escuela.id}"
				@titulo += " <span class='badge badge-secondary'>#{@inscripciones.count}</span>"
				if params[:status].eql? TipoEstadoInscripcion::PREINSCRITO
					@inscripciones = @inscripciones.sin_reportepago.preinscritos
					@titulo = "Preinscritos Sin Reporte - #{@escuelaperiodo.periodo_id} - #{@escuelaperiodo.escuela.id}"
					@titulo += " <span class='badge badge-primary'>#{@inscripciones.count}</span>"
				elsif params[:status].eql? 'reported'
					@inscripciones = @inscripciones.con_reportepago.preinscritos
					@titulo = "Preinscritos Con Reporte - #{@escuelaperiodo.periodo_id} - #{@escuelaperiodo.escuela.id}"
					@titulo += " <span class='badge badge-warning'>#{@inscripciones.count}</span>"
				elsif params[:status].eql? TipoEstadoInscripcion::INSCRITO
					@inscripciones = @inscripciones.inscritos
					@titulo = "Confirmados - #{@escuelaperiodo.periodo_id} - #{@escuelaperiodo.escuela.id}"
					@titulo += " <span class='badge badge-success'>#{@inscripciones.count}</span>"

				end
			else
				flash[:danger] = 'Debe seleccionar una escuela'
				redirect_back fallback_location: escuelas_path
			end
		end

	end
end