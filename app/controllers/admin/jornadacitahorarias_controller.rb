module Admin
  class JornadacitahorariasController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado

    before_action :set_jornadacitahoraria, only: %i[ show edit update destroy enviar_correo_citas_horarias]
    before_action :set_escuelaperiodo, only: %i[ index new create enviar_correo_citas_horarias]
    before_action :set_grados_sin_cita, only: %i[ index new]

    
    def enviar_correo_citas_horarias
      total = 0
      @jornadacitahoraria.grados_propios_ordenados.each do |grado|
        total += 1 if grado.enviar_correo_cita_horaria(current_usuario.id, request.remote_ip, @escuelaperiodo.periodo_id)
      end

      flash[:success] = "Se enviaron un total de #{total} correos "

      redirect_to jornadacitahorarias_path

    end

    def index
      @jornadacitahorarias = @escuelaperiodo.jornadacitahorarias
      @confirmados_periodo
    end

    def show
    end

    def new
      @jornadacitahoraria = Jornadacitahoraria.new
      @jornadacitahoraria.escuelaperiodo_id = @escuelaperiodo.id
      @total_grados_sin_cita = @grados_sin_cita.count
    end

    def create
      @jornada = Jornadacitahoraria.new(jornadacitahoraria_params)

      if @jornada.save
        total_franjas = @jornada.total_franjas
        grados_x_franja = @jornada.grado_x_franja
        total_grados_actualizados = 0
        for a in 0..(total_franjas-1) do
          limitado = @escuelaperiodo.escuela.grados.sin_cita_horarias.regular_or_articulo_3.con_inscripciones_en_periodo(@escuelaperiodo_anterior.periodo_id).includes(estudiante: :usuario).order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc]).uniq

          limitado[0..grados_x_franja-1].each{|gr| total_grados_actualizados += 1 if gr.update(citahoraria: @jornada.inicio+(a*@jornada.duracion_franja_minutos).minutes, duracion_franja_horaria: @jornada.duracion_franja_minutos)}

        end
        
        # limitado = @escuelaperiodo.escuela.grados.sin_cita_horarias.regular_or_articulo_3.con_inscripciones_en_periodo(@escuelaperiodo_anterior.periodo_id).includes(estudiante: :usuario).order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc]).uniq

        # if limitado.any?
        #   limitado.each{|gr| total_grados_actualizados += 1 if gr.update(citahoraria: @jornada.inicio+(total_franjas-1*@jornada.duracion_franja_minutos).minutes, duracion_franja_horaria: @jornada.duracion_franja_minutos)}
        # end


        flash[:success] = "Jornada de Cita Horaria guardada con éxito. Se asignaron #{total_grados_actualizados} citas horarias de un total esperado de #{@jornada.max_grados}."
        
        redirect_to jornadacitahorarias_path
      else
        flash[:danger] = "Inconvenientes para guardar la Jornada: #{@jornada.errors.full_messages.to_sentence}"
        redirect_back fallback_location: jornadacitahorarias_path
      end
      
    end

    def update
      respond_to do |format|
        if @jornadacitahoraria.update(jornadacitahoraria_params)
          format.html { redirect_to @jornadacitahoraria, notice: "Jornadacitahoraria was successfully updated." }
          format.json { render :show, status: :ok, location: @jornadacitahoraria }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @jornadacitahoraria.errors, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @jornadacitahoraria.destroy
      respond_to do |format|
        format.html { redirect_to jornadacitahorarias_url, notice: "Jornada Cita Horaria eliminada. Todos las citas horarias de los estudiantes fueron limpiadas." }
        format.json { head :no_content }
      end
    end

    private

      def set_jornadacitahoraria
        @jornadacitahoraria = Jornadacitahoraria.find(params[:id])
      end

      def set_escuelaperiodo
        if session['periodo_actual_id'].nil? and session['escuela_id'].nil?
          flash[:danger] = 'Debe dirigirse al detalle de la escuela y seleccionar un <b>Período Activo</b> perteneciente a dicha escuela'
          redirect_back fallback_location: principal_admin_index_path
        else
          @escuelaperiodo = Escuelaperiodo.where(escuela_id: session['escuela_id'], periodo_id: session['periodo_actual_id']).first
          if @escuelaperiodo.nil?
            flash[:danger] = 'Periodo para la escuela no encontrado. Por favor, elija un periodo activo asociado a la escuela'
            redirect_back fallback_location: principal_admin_index_path
          else
            @escuelaperiodo_anterior = @escuelaperiodo.escuelaperiodo_anterior
          end
        end  
      end

      def set_grados_sin_cita

        # @grados_sin_cita = @escuelaperiodo_anterior.inscripcionescuelaperiodos.inscritos.joins(:grado).joins(:escuelaperiodo).where("inscripcionescuelaperiodos.tipo_estado_inscripcion_id = '#{TipoEstadoInscripcion::INSCRITO}' AND escuelaperiodos.periodo_id = '#{@escuelaperiodo_anterior.periodo_id}' AND grados.citahoraria IS NULL").map{|iep| iep.grado}

        # grados_con_cita_ids = Grado.con_cita_horarias.ids
        # @grados_sin_cita = @escuelaperiodo.escuela.grados.sin_cita_horarias.includes(estudiante: :usuario).joins(inscripcionescuelaperiodos: :escuelaperiodo).where("inscripcionescuelaperiodos.tipo_estado_inscripcion_id = '#{TipoEstadoInscripcion::INSCRITO}' AND escuelaperiodos.periodo_id = '#{@escuelaperiodo_anterior.periodo_id}' AND grados.id NOT IN (#{grados_con_cita_ids.to_sentence last_word_connector: ' , '})").order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc])

        # @grados_sin_cita = @escuelaperiodo.escuela.grados.sin_cita_horarias.includes(estudiante: :usuario).joins(inscripcionescuelaperiodos: :escuelaperiodo).where("inscripcionescuelaperiodos.tipo_estado_inscripcion_id = '#{TipoEstadoInscripcion::INSCRITO}' AND escuelaperiodos.periodo_id = '#{@escuelaperiodo_anterior.periodo_id}'").order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc])  

        @grados_sin_cita = @escuelaperiodo.escuela.grados.sin_cita_horarias.regular_or_articulo_3.con_inscripciones_en_periodo(@escuelaperiodo_anterior.periodo_id).includes(estudiante: :usuario).order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc]).uniq

      end


      # Only allow a list of trusted parameters through.
      def jornadacitahoraria_params
        params.require(:jornadacitahoraria).permit(:escuelaperiodo_id, :inicio, :duracion_total_horas, :max_grados, :duracion_franja_minutos)
      end
  end
end
