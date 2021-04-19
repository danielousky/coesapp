module Admin
	class EscuelaperiodosController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador
		before_action :filtro_autorizado


		def show
			@escupe = Escuelaperiodo.find params[:id]

			if @escupe.id.eql? 77 #77= 2019-02A,Idiomas
				@inscripciones = Inscripcionseccion.por_confirmar.con_totales(@escupe.escuela_id, @escupe.periodo_id)
			else
				@inscripciones = Inscripcionseccion.con_totales(@escupe.escuela_id, @escupe.periodo_id)
			end
			
			@titulo = "Inscripciones para el #{@escupe.periodo_id} en #{@escupe.escuela.descripcion}"
			@titulo += " <span class='badge badge-warning'>#{@inscripciones.size.count}</span>"
			# end

		end

	end
end