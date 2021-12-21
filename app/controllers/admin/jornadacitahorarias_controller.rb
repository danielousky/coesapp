module Admin
  class JornadacitahorariasController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado

    before_action :set_jornadacitahoraria, only: %i[ show edit update destroy ]

    # GET /jornadacitahorarias or /jornadacitahorarias.json
    def index
      if params[:escuelaperiodo_id]
        @escuelaperiodo = Escuelaperiodo.find params[:escuelaperiodo_id]
        @jornadacitahorarias = @escuelaperiodo.jornadacitahorarias
        @grados_sin_cita = @escuelaperiodo.grados_sin_cita_horaria_ordenados.limit(100)
      else
        redirect_back fallback_location: principal_admin_index_path
      end
    end

    # GET /jornadacitahorarias/1 or /jornadacitahorarias/1.json
    def show
    end

    # GET /jornadacitahorarias/new
    def new
      @jornadacitahoraria = Jornadacitahoraria.new
      if params[:escuelaperiodo_id]
        @escuelaperiodo = Escuelaperiodo.find params[:escuelaperiodo_id]
        @jornadacitahoraria.escuelaperiodo_id = @escuelaperiodo.id
        @total_grados_sin_cita = @escuelaperiodo.grados_sin_cita_horaria_ordenados.count#.limit(100)
      else
        flash[:warning] = 'Disculpe, debe acceder a las citas horarias haciendo uso de los enlaces respectivos.'
        redirect_back fallback_location: principal_admin_index_path
      end
    end

    # GET /jornadacitahorarias/1/edit
    # def edit
    # end

    # POST /jornadacitahorarias or /jornadacitahorarias.json
    def create
      @jornada = Jornadacitahoraria.new(jornadacitahoraria_params)

      respond_to do |format|
        if @jornada.save
          grados_a_asignar_cita = @jornada.escuelaperiodo.grados_sin_cita_horaria_ordenados

          total_franjas = @jornada.total_franjas
          grados_x_franja = @jornada.grado_x_franja

          total_grados_actualizados = 0
          for a in 0..(total_franjas-1) do
            grados_limitados = grados_a_asignar_cita.limit(grados_x_franja)
            total_grados_actualizados += grados_limitados.count if grados_limitados.update_all(citahoraria: @jornada.inicio+(a*@jornada.duracion_franja_minutos).minutes)
            grados_a_asignar_cita = grados_a_asignar_cita.sin_cita_horarias
            p "  Total de Grados en vuelta #{a}: <#{grados_a_asignar_cita.count}>  ".center(400, "#")
          end

          format.html { redirect_to "#{jornadacitahorarias_path}?escuelaperiodo_id=#{@jornada.escuelaperiodo_id}", flash: {success: "Jornada de Cita Horaria guardada con éxito. Se asignaron #{total_grados_actualizados} citas horarias en total"}}
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

      # Only allow a list of trusted parameters through.
      def jornadacitahoraria_params
        params.require(:jornadacitahoraria).permit(:escuelaperiodo_id, :inicio, :duracion_total_horas, :max_grados, :duracion_franja_minutos)
      end
  end
end
