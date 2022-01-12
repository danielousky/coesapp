module Admin
  class JornadacitahorariasController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado

    before_action :set_jornadacitahoraria, only: %i[ show edit update destroy ]
    before_action :set_escuelaperiodo, only: %i[ index new ]

    # GET /jornadacitahorarias or /jornadacitahorarias.json
    def index

      @jornadacitahorarias = @escuelaperiodo.jornadacitahorarias
      # @grados_sin_cita = escuelaperiodo_anterior.inscripcionescuelaperiodos.inscritos.joins(:grado).where('grados.citahoraria IS NULL').map{|iep| iep.grado}

      # Completed 200 OK in 7329ms (Views: 4233.9ms | ActiveRecord: 1526.0ms)
      # Completed 200 OK in 7686ms (Views: 4542.8ms | ActiveRecord: 1625.6ms)

      # EL SIGUIENTE QUERY ES MÁS EFICIENTE QUE EL ANTERIOR
      # El include optimisa el query precargándolo en una sola búsqueda
      # Completed 200 OK in 891ms (Views: 834.5ms | ActiveRecord: 40.5ms)

      # Completed 200 OK in 4877ms (Views: 3502.1ms | ActiveRecord: 1237.7ms)
      # Completed 200 OK in 5334ms (Views: 3956.8ms | ActiveRecord: 1233.7ms)

    end

    # GET /jornadacitahorarias/1 or /jornadacitahorarias/1.json
    def show
    end

    # GET /jornadacitahorarias/new
    def new
      @jornadacitahoraria = Jornadacitahoraria.new
      @jornadacitahoraria.escuelaperiodo_id = @escuelaperiodo.id
      @total_grados_sin_cita = @grados_sin_cita.count
    end

    # GET /jornadacitahorarias/1/edit
    # def edit
    # end

    # POST /jornadacitahorarias or /jornadacitahorarias.json
    def create
      @jornada = Jornadacitahoraria.new(jornadacitahoraria_params)

      respond_to do |format|
        if @jornada.save
          # grados_a_asignar_cita = @jornada.escuelaperiodo.grados_sin_cita_horaria_ordenados
          esc = Escuela.find 'IDIO'
          @grados_sin_cita = esc.grados.sin_cita_horarias.order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc])

          total_franjas = @jornada.total_franjas
          grados_x_franja = @jornada.grado_x_franja

          total_grados_actualizados = 0
          for a in 0..(total_franjas-1) do
            grados_limitados = @grados_sin_cita.limit(grados_x_franja)
            total_grados_actualizados += grados_limitados.count if grados_limitados.update_all(citahoraria: @jornada.inicio+(a*@jornada.duracion_franja_minutos).minutes)
            @grados_sin_cita = @grados_sin_cita.sin_cita_horarias
          end

          format.html { redirect_to jornadacitahorarias_path, flash: {success: "Jornada de Cita Horaria guardada con éxito. Se asignaron #{total_grados_actualizados} citas horarias en total"}}
          format.json { render :show, status: :created, location: @jornada }
        else

          format.html { redirect_back fallback_location: jornadacitahorarias_path,flash: {danger: "Inconvenientes para guardar la Jornada: #{@jornada.errors.full_messages.to_sentence}"}  }
          format.json { render json: @jornada.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /jornadacitahorarias/1 or /jornadacitahorarias/1.json
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

    # DELETE /jornadacitahorarias/1 or /jornadacitahorarias/1.json
    def destroy
      @jornadacitahoraria.destroy
      respond_to do |format|
        format.html { redirect_to jornadacitahorarias_url, notice: "Jornada Cita Horaria eliminada. Todos las citas horarias de los estudiantes fueron limpiadas." }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
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
            set_grados_sin_cita
          end
        end  
      end

      def set_grados_sin_cita
        escuelaperiodo_anterior = @escuelaperiodo.escuelaperiodo_anterior
        @grados_sin_cita = @escuelaperiodo.escuela.grados.sin_cita_horarias.includes(estudiante: :usuario).joins(inscripcionescuelaperiodos: :escuelaperiodo).where("inscripcionescuelaperiodos.tipo_estado_inscripcion_id = '#{TipoEstadoInscripcion::INSCRITO}' AND escuelaperiodos.periodo_id = '#{escuelaperiodo_anterior.periodo_id}'").order([eficiencia: :desc, promedio_simple: :desc, promedio_ponderado: :desc])
      end

      # Only allow a list of trusted parameters through.
      def jornadacitahoraria_params
        params.require(:jornadacitahoraria).permit(:escuelaperiodo_id, :inicio, :duracion_total_horas, :max_grados, :duracion_franja_minutos)
      end
  end
end
