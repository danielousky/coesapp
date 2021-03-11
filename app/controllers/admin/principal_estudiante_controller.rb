module Admin
	class PrincipalEstudianteController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_estudiante

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
				if @total.eql? 0
					aux = @estudiante.inscripcionescuelaperiodos
					aux.destroy_all if aux.any?
				end
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