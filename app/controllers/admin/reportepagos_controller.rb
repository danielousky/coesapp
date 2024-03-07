module Admin
  class ReportepagosController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador, only: [:edit, :show, :index]
    before_action :filtro_autorizado, only: [:edit, :show, :index]
    # before_action :filtro_estudiante
    before_action :set_reportepago, only: [:show, :edit, :update, :destroy]
    before_action :resize_image, only: [:create, :update]


    def index
      if current_admin
        @escuelas = current_admin.escuelas
      else
        @escuelas = Escuela.all
      end
      
      if params[:escuela_id]
        escuela = Escuela.find params[:escuela_id]
        @titulo = "Reportes de Pago de #{escuela.descripcion}"
        session[:escuela_id] = params[:escuela_id]
        @reportepagos = Reportepago.inscripciones_del_periodo(current_periodo.id).inscripciones_de_la_escuela(params[:escuela_id]).order(created_at: :desc)
      elsif session[:escuela_id]
        escuela = Escuela.find session[:escuela_id]
        @titulo = "Reportes de Pago de #{escuela.descripcion}"

        @reportepagos = Reportepago.inscripciones_del_periodo(current_periodo.id).inscripciones_de_la_escuela(session[:escuela_id]).order(created_at: :desc)

      else
        @titulo = 'Reportes de Pago'
        @reportepagos = Reportepago.inscripciones_del_periodo(current_periodo.id).limit(100).order(created_at: :desc)
      end

    end

    # GET /reportepagos
    # GET /reportepagos.json


    # def index
    #   @titulo = "Reportes Pago"
    #   @reportepagos = Reportepago.limit(50)
    # end

    # GET /reportepagos/1
    # GET /reportepagos/1.json
    def show
      @titulo = 'Detalle del Reporte de Pago'
      @estudiante = @reportepago.objeto.estudiante
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
      begin
        clazz = params[:reportable][:type].constantize
        obj = clazz.find params[:reportable][:id]
        unless obj
          flash[:danger] = "No se pudo encontrar el #{clazz} relacionado. "
        else
          if obj.reportepago
            flash[:danger] = "Ya posee un reporte de pago. "
          elsif (clazz.eql? Inscripcionescuelaperiodo) and obj.periodo and (obj.periodo.reportepagos.map{|rp| rp.numero}.include? @reportepago.numero)
            flash[:danger] = "Número de transacción #{@reportepago.numero} ya fue usado en otra inscripción en el período #{obj.periodo.id}. "

          elsif @reportepago.save

            obj.reportepago_id = @reportepago.id
            obj.estado_inscripcion = 'preinscrito' if clazz.eql? Grado

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
        return_to = (@reportepago.objeto and @reportepago.objeto.estudiante) ? usuario_path(@reportepago.objeto.estudiante.usuario) : periodos_path
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
            return_to = (@reportepago.objeto and @reportepago.objeto.estudiante) ? usuario_path(@reportepago.objeto.estudiante.usuario) : periodos_path
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
        format.html { redirect_back fallback_location: reportepagos_url, notice: 'Reporte de pago eliminado' }
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