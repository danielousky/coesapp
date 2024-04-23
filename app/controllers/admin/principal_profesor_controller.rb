module Admin
	class PrincipalProfesorController < ApplicationController

		before_action :filtro_logueado
		before_action :filtro_profesor

		def index
			@profesor = Profesor.find (session[:profesor_id])
			@usuario = @profesor.usuario
			@titulo = "Principal - Profesores"
			secciones = @profesor.secciones
			@secciones_pendientes = secciones.sin_calificar.order('periodo_id DESC, numero ASC')
			@secciones_calificadas = secciones.calificadas.order('periodo_id DESC, numero ASC')
			@secciones_secundarias = @profesor.secciones_secundarias.order('periodo_id DESC, numero ASC')#.where(periodo_id: @periodo_actual_id)
		end

	end
end