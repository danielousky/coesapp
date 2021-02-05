module Admin
	class EscuelaperiodosController < ApplicationController
		before_action :filtro_logueado
		before_action :filtro_administrador
		before_action :filtro_autorizado


		def show
			@escupe = Escuelaperiodo.find params[:id]

			if @escupe.escuela_id.eql? 'IDIO' and @escupe.periodo_id.eql? '2019-02A'
				if params[:rat]
					@inscripciones = Inscripcionseccion.joins(:escuela).where("escuelas.id = ?", @escupe.escuela_id).del_periodo(@escupe.periodo_id).inscritos.joins(:usuario).order("usuarios.apellidos ASC").joins(:asignatura).group(:estudiante_id).select('estudiante_id, usuarios.apellidos apellidos, usuarios.nombres nombres, SUM(asignaturas.creditos) total_creditos, COUNT(*) asignaturas, SUM(IF (estado = 1, asignaturas.creditos, 0)) aprobados')
					@titulo = "Ratificaciones para el período #{@escupe.periodo_id} en la escuela #{@escupe.escuela.descripcion} (#{@inscripciones.size.count})"

				else
					@inscripciones = Inscripcionseccion.joins(:escuela).where("escuelas.id = ?", @escupe.escuela_id).del_periodo(@escupe.periodo_id).preinscritos.joins(:usuario).order("usuarios.apellidos ASC").joins(:asignatura).group(:estudiante_id).select('estudiante_id, usuarios.apellidos apellidos, usuarios.nombres nombres, SUM(asignaturas.creditos) total_creditos, COUNT(*) asignaturas, SUM(IF (estado = 1, asignaturas.creditos, 0)) aprobados')
					@titulo = "Inscripciones para el período #{@escupe.periodo_id} en la escuela #{@escupe.escuela.descripcion} (#{@inscripciones.size.count})"
				end
			else
				@inscripciones = Inscripcionseccion.joins(:escuela).where("escuelas.id = ?", @escupe.escuela_id).del_periodo(@escupe.periodo_id).joins(:usuario).order("usuarios.apellidos ASC").joins(:asignatura).group(:estudiante_id).select('estudiante_id, usuarios.apellidos apellidos, usuarios.nombres nombres, SUM(asignaturas.creditos) total_creditos, COUNT(*) asignaturas, SUM(IF (estado = 1, asignaturas.creditos, 0)) aprobados')
				@titulo = "Inscripciones para el período #{@escupe.periodo_id} en la escuela #{@escupe.escuela.descripcion} (#{@inscripciones.size.count})"
			end

		end

	end
end