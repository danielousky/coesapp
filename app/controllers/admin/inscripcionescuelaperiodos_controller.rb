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
					@titulo += " <span class='badge badge-info'>#{@inscripciones.count}</span>"
				elsif params[:status].eql? 'reported'
					@inscripciones = @inscripciones.con_reportepago.preinscritos
					@titulo = "Preinscritos Con Reporte - #{@escuelaperiodo.periodo_id} - #{@escuelaperiodo.escuela.id}"
					@titulo += " <span class='badge badge-warning'>#{@inscripciones.count}</span>"
				elsif params[:status].eql? TipoEstadoInscripcion::RESERVADO
					@inscripciones = @inscripciones.reservados
					@titulo = "Inscribiéndose - #{@escuelaperiodo.periodo_id} - #{@escuelaperiodo.escuela.id}"
					@titulo += " <span class='badge badge-secondary'>#{@inscripciones.count}</span>"
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

		def confirmacion_masiva
			escuelaperiodo = Escuelaperiodo.find params[:id]
			if escuelaperiodo
				escuelaperiodo.inscripcionescuelaperiodos.con_reportepago.preinscritos.each {|ins| ins.confirmar_con_correo}				
				flash[:success] = 'Inscripciones confimadas. Se enviarán los correos progresivamente en los próximos minutos'
			else
				flash[:danger] = 'No se encontró el período y escuela solicitado'
			end
			redirect_back fallback_location: root_path
		end

	end
end