module Admin
  class ReportepagosController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_estudiante
    before_action :set_reportepago, only: [:show, :edit, :update, :destroy]
    before_action :resize_image, only: [:create, :update]

    # GET /reportepagos
    # GET /reportepagos.json
    def index
      @reportepagos = Reportepago.all
    end

    # GET /reportepagos/1
    # GET /reportepagos/1.json
    def show
    end

    # GET /reportepagos/new
    def new
      @titulo = "Reporte Pago"
      @reportepago = Reportepago.new
      @inscripcionescuelaperiodo_id = params[:inscripcionescuelaperiodo_id]
      @grado_id = params[:grado_id]
    end

    # GET /reportepagos/1/edit
    def edit
      @titulo = "Editando Reporte de Pago"
    end

    # POST /reportepagos
    # POST /reportepagos.json
    def create

      @reportepago = Reportepago.new(reportepago_params)

      respond_to do |format|
        if @reportepago.save
          if params[:grado_id] or params[:inscripcionescuelaperiodo_id]
            if params[:grado_id]
              obj = Grado.find params[:grado_id].split
            elsif params[:inscripcionescuelaperiodo_id]
              obj = Inscripcionescuelaperiodo.find params[:inscripcionescuelaperiodo_id]
            end
            if obj
              obj.reportepago_id = @reportepago.id
              if obj.save
                flash[:success] = 'Reporte de Pago guardado con éxito'
              else
                flash[:danger] = "Error al intentar asociar el reporte de pago al #{obj.class.name}. Se eliminó el reporte. #{obj.errors.full_messages.to_sentence if (obj and obj.errors)}"
              end
            else
              reportepago.destroy
              flash[:danger] = "No se encontró el #{obj.class.name}."
            end
          end
          format.html { redirect_to principal_estudiante_index_path}
          format.json { render :show, status: :created, location: @reportepago }
        else
          format.html { render :new }
          format.json { render json: @reportepago.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /reportepagos/1
    # PATCH/PUT /reportepagos/1.json
    def update
      respond_to do |format|
        if @reportepago.update(reportepago_params)
          format.html { redirect_to principal_estudiante_index_path, success: 'Reporte de Pago guardado con éxito' }
          format.json { render :show, status: :ok, location: @reportepago }
        else
          format.html { render :edit }
          format.json { render json: @reportepago.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /reportepagos/1
    # DELETE /reportepagos/1.json
    def destroy
      @reportepago.destroy
      respond_to do |format|
        format.html { redirect_to reportepagos_url, notice: 'Reportepago was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private

      def resize_image

        aux = params[:reportepago][:respaldo]

        if aux #and aux.byte_size > 1.megabyte
          mini_image = MiniMagick::Image.new(params[:reportepago][:respaldo].tempfile.path)
          mini_image.resize '400x400'
        end

      end
      # Use callbacks to share common setup or constraints between actions.
      def set_reportepago
        @reportepago = Reportepago.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def reportepago_params
        params.require(:reportepago).permit(:numero, :monto, :tipo_transaccion, :fecha_transaccion, :respaldo, :banco_origen_id)
      end
  end
end