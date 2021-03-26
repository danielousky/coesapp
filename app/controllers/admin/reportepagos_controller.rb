module Admin
  class ReportepagosController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_autorizado, only: [:edit, :show]
    # before_action :filtro_estudiante
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
      @estudiante = @reportepago.inscripcionescuelaperiodo.estudiante
    end

    # GET /reportepagos/new
    def new
      @titulo = "Reporte Pago"
      @reportepago = Reportepago.new
      clazz = params[:reportable_type].constantize
      @reportable = clazz.find params[:reportable_id]
      # @inscripcionescuelaperiodo_id = params[:inscripcionescuelaperiodo_id]
      # @grado_id = params[:grado_id]
    end

    # GET /reportepagos/1/edit
    def edit
      @titulo = "Editando Reporte de Pago"
    end

    # POST /reportepagos
    # POST /reportepagos.json
    def create

      @reportepago = Reportepago.new(reportepago_params)
      params[:reportable][:id] = params[:reportable][:id].split if params[:reportable][:type].eql? 'Grado'

      begin
        clazz = params[:reportable][:type].constantize
        obj = clazz.find params[:reportable][:id]
        unless obj
          flash[:danger] = "No se pudo encontrar el #{clazz} relacionado. "
        else
          if obj.reportepago
            flash[:danger] = "Ya posee un reporte de pago. "
          elsif obj.periodo and (obj.periodo.reportepagos.map{|rp| rp.numero}.include? @reportepago.numero)
            flash[:danger] = "Número de transacción #{@reportepago.numero} ya fue usado en otra inscripción en el período #{obj.periodo.id}. "

          elsif @reportepago.save
            obj.reportepago_id = @reportepago.id
            if obj.save
              flash[:success] = 'Reporte de Pago guardado con éxito. '
            else
              flash[:danger] = "Error al intentar asociar el reporte de pago al #{obj.class.name}. #{obj.errors.full_messages.to_sentence}. "
            end
          else
            flash[:danger] = "No fue posible guardar el reporte de pago: #{obj.errors.full_messages.to_sentence}. "
          end
        end
      rescue Exception => e
         flash[:danger] = "Error General: #{e}. "
      end

      if current_admin
        return_to = (@reportepago.objeto and @reportepago.objeto.estudaante) ? usuario_path(@reportepago.objeto.estudiante.usuario) : periodo_index_path
      else
        return_to = principal_estudiante_index_path
      end

      if flash[:danger]
        redirect_back fallback_location: return_to
      else
        redirect_to return_to
      end
    end

    # PATCH/PUT /reportepagos/1
    # PATCH/PUT /reportepagos/1.json
    def update
      respond_to do |format|
        if @reportepago.update(reportepago_params)

          if current_admin
            return_to = (@reportepago.objeto and @reportepago.objeto.estudiante) ? usuario_path(@reportepago.objeto.estudiante.usuario) : periodo_index_path
          else
            return_to = principal_estudiante_index_path
          end

          format.html { redirect_to return_to, success: 'Reporte de Pago guardado con éxito' }
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
          mini_image.resize '800x800'
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