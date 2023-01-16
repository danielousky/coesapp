module Admin
  class DepartamentosController < ApplicationController
    # Privilegios

    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado

    before_action :set_departamento, only: [:show, :edit, :update, :destroy]
    before_action :set_escuela, only: [:index]

    # GET /departamentos
    # GET /departamentos.json
    def index
      @departamentos = @escuela.departamentos
    end

    # GET /departamentos/1
    # GET /departamentos/1.json
    def show
      @titulo = "Departamento de #{@departamento.descripcion}"
      @catedradepartamentos = @departamento.catedradepartamentos
      cat_ids = @catedradepartamentos.collect{|o| o.catedra_id}
      @catedras_disponibles = Catedra.all.reject{|ob| cat_ids.include? ob.id}
    end

    # GET /departamentos/new
    def new
      @departamento = Departamento.new
      @titulo = "Crear Nuevo Departamento"
    end

    # GET /departamentos/1/edit
    def edit
    end

    # POST /departamentos
    # POST /departamentos.json
    def create
      @departamento = Departamento.new(departamento_params)

      respond_to do |format|
        if @departamento.save
          info_bitacora_crud Bitacora::CREACION, @departamento
          format.html { redirect_to @departamento, notice: 'Departamento creado con éxito.' }
          format.json { render :show, status: :created, location: @departamento }
        else
          flash[:danger] = "Error al intentar crear el departamento: #{@departamento.errors.full_messages.to_sentence}"
          format.html { render :new, notice: "Error al intentar crear el departamento: #{@departamento.errors.full_messages.to_sentence}" }
          format.json { render json: @departamento.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /departamentos/1
    # PATCH/PUT /departamentos/1.json
    def update
      respond_to do |format|
        if @departamento.update(departamento_params)
          info_bitacora_crud Bitacora::ACTUALIZACION, @departamento
          format.html { redirect_to @departamento, notice: 'Departamento actualizado con éxito.' }
          format.json { render :show, status: :ok, location: @departamento }
        else
          format.html { render :edit }
          format.json { render json: @departamento.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /departamentos/1
    # DELETE /departamentos/1.json
    def destroy
      if @departamento.inscripcionsecciones.any?
        flash[:danger] = "El departamento posee estudiantes inscritos. Por favor elimínelos e inténtelo nuevamente."
      else
        info_bitacora_crud Bitacora::ELIMINACION, @departamento
        @departamento.destroy
      end
      respond_to do |format|
        format.html { redirect_to departamentos_url, notice: 'Departamento eliminado satisfactoriamente.' }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_departamento
        @departamento = Departamento.find(params[:id])
      end

      def set_escuela
        if params[:escuela_id]
          @escuela = Escuela.find(params[:escuela_id])
        else
          flash[:danger] = 'Por favor seleccione una escuela en el menú'
          redirect_back fallback_location: principal_admin_index_path
        end
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def departamento_params
        params.require(:departamento).permit(:descripcion, :id, :escuela_id)
      end
  end
end