module Admin
  class AsignaturasController < ApplicationController
    # Privilegios
    before_action :filtro_logueado
    #before_action :filtro_admin_mas_altos!, except: [:destroy]
    #before_action :filtro_ninja!, only: [:destroy]

    before_action :filtro_administrador
    before_action :filtro_autorizado#, except: [:new, :edit]

    before_action :set_asignatura, only: [:show, :edit, :update, :destroy, :set_activa, :set_pci]
    before_action :set_escuela_and_dptos, only: [:new]

    def set_activa
        progs = @asignatura.programaciones.where(periodo_id: current_periodo.id)
        if progs.count > 0
          progs.delete_all
        else
          @asignatura.programaciones.create(periodo_id: current_periodo.id)
        end

      head :no_content
    end

    def set_pci
      progrs = @asignatura.programaciones.where(periodo_id: current_periodo.id)
      if progrs.count > 0
        aux = progrs.first.pci
        progrs.delete_all
        @asignatura.programaciones.create(periodo_id: current_periodo.id, pci: !aux)
      else
        @asignatura.programaciones.create(periodo_id: current_periodo.id, pci: true)
      end        

      head :no_content
    end


    # GET /asignaturas
    # GET /asignaturas.json
    def index
      @titulo = 'Asignaturas'
      @departamentos = current_admin.departamentos
      @departamentos = Departamento.all unless @departamentos
      @seccion = Seccion.new
      if params[:escuela_id]
        @escuelas = Escuela.where(id: params[:escuela_id])
        @escuela = @escuelas.first
        @profesores = @escuelas.first.profesores
      else
        flash[:success] = 'Por favor, seleccione una escuela haciendo uso de los enlaces en el menú'
        redirect_back fallback_location: principal_admin_index_path
      end

      @vertical = 'flex-column'
      @orientacion = "vertical"
      @admin_inscripcion = true 
      @row = 'row'
      @col2 = 'col-md-2'
      @col10 = 'col-md-10'

    end

    # GET /asignaturas/1
    # GET /asignaturas/1.json
    def show
      @titulo = "Asignatura: #{@asignatura.descripcion.upcase}"
      @bitacoras = Bitacora.search(@asignatura.id).order(created_at: :desc).limit(30)

      @escuela = @asignatura.escuela
      @departamentos = @escuela.departamentos.includes(:departamento)
      @dependientes = @asignatura.dependencias

      @dependencia_hacia_atras = @asignatura.dependencia_hacia_atras
      @secciones = @asignatura.secciones.del_periodo(current_periodo.id)



      if @asignatura.escuela.id.eql? 'POST'
        @profesores = Profesor.all.includes(:usuario).order('usuarios.apellidos')
      else
        @profesores = @asignatura.escuela.profesores.includes(:usuario).all.order('usuarios.apellidos')
      end

    end

    # GET /asignaturas/new
    def new
      @titulo = 'Nueva Asignatura'
      @asignatura = Asignatura.new
    end

    # GET /asignaturas/1/edit
    def edit
      @titulo = "Editando #{@asignatura.descripcion}"
      @escuela = @asignatura.escuela
      @departamentos = @escuela.departamentos
    end

    # POST /asignaturas
    # POST /asignaturas.json
    def create
      @asignatura = Asignatura.new(asignatura_params)
      catdep = Catedradepartamento.where(departamento_id: asignatura_params[:departamento_id], catedra_id: asignatura_params[:catedra_id]).limit(1).first
      unless catdep
        flash[:danger] = "No se pudo encontrar la asociación Cátedra-Departamento. Seleccione el departamento y la cátedra apropiadamente o primero agregue la cátedra (+ Cátedra) en la <a class='btn btn-info btn-sm' href='#{departamento_path(asignatura_params[:departamento_id])}'>Asignatura</a> para luego generar las asignaturas respectivas."
        redirect_back fallback_location: asignaturas_path 
      else
        @asignatura.id = @asignatura.id_uxxi
        respond_to do |format|
          if @asignatura.save
            info_bitacora_crud Bitacora::CREACION, @asignatura
            format.html { redirect_to @asignatura}
            format.json { render :show, status: :created, location: @asignatura }
          else
            @titulo = 'Nueva Asignatura'
            @departamentos = current_admin.departamentos
            @departamentos = Departamento.all unless @departamentos
            @escuelas = current_admin.escuelas
            flash[:danger] = "Error al intentar generar la asignatura: #{@asignatura.errors.full_messages.to_sentence}."
            format.html { render :new }
            format.json { render json: @asignatura.errors, status: :unprocessable_entity }
          end
        end
      end
    end



    # PATCH/PUT /asignaturas/1
    # PATCH/PUT /asignaturas/1.json
    def update
      respond_to do |format|
        asignatura_params[:id] = asignatura_params[:id_uxxi]
        if @asignatura.update(asignatura_params)
          info_bitacora_crud Bitacora::ACTUALIZACION, @asignatura
          format.html { redirect_to @asignatura, notice: 'Asignatura actulizada con éxito.' }
          format.json { render :show, status: :ok, location: @asignatura }
        else
          flash[:danger] = "Error al intentar actualizar la asignatura: #{@asignatura.errors.full_messages.to_sentence}."
          @titulo = "Editando #{@asignatura.descripcion}"
          @departamentos = current_admin.departamentos
          format.html { render :edit }
          format.json { render json: @asignatura.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /asignaturas/1
    # DELETE /asignaturas/1.json
    def destroy

      if @asignatura.inscripcionsecciones.any?
        flash[:danger] = "El asignatura posee estudiantes inscritos. Por favor elimínelos e inténtelo nuevamente."
      else
        info_bitacora_crud Bitacora::ELIMINACION, @asignatura
        @asignatura.destroy
      end

      @asignatura.destroy
      info_bitacora_crud Bitacora::ELIMINACION, @asignatura
      respond_to do |format|
        format.html { redirect_to asignaturas_url, notice: 'Asignatura eliminada satisfactoriamente.' }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_asignatura
        @asignatura = Asignatura.find(params[:id])
      end

      def set_escuela_and_dptos
        unless params[:escuela_id]
          flash[:danger] = 'Para agregar una asignatura debe asociarla a una escuela, por favor inténtelo nuevamente desde el medio aducuado.'
          redirect_back fallback_location: root_path
        else
          @escuela = Escuela.find params[:escuela_id]
          @departamentos = @escuela.departamentos
        end

      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def asignatura_params
        params.require(:asignatura).permit(:id, :descripcion, :catedra_id, :departamento_id, :anno, :orden, :id_uxxi, :creditos, :tipoasignatura_id, :calificacion, :forzar_absoluta)
      end

  end
end