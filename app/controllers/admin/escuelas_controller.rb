module Admin
  class EscuelasController < ApplicationController
    # Privilegios
    before_action :filtro_logueado
    # before_action :filtro_ninja!, only: [:destroy]
    before_action :filtro_administrador
    before_action :filtro_super_admin!, only: [:set_periodo_inscripcion, :set_habilitar_retiro_asignaturas, :set_habilitar_cambio_seccion]

    before_action :filtro_autorizado#, except: [:new, :edit, :periodos, :set_inscripcion_abierta, :set_habilitar_retiro_asignaturas, :set_habilitar_cambio_seccion]
    before_action :set_escuela, except: [:new, :index, :create]

    # GET /escuelas
    # GET /escuelas.json
    def periodos
      render json: {ids: @escuela.periodos.where("periodos.id != ?", params[:periodo_actual_id]).order(inicia: :desc).ids.to_a}
    end

    def limpiar_programacion
      @escuela.asignaturas.each do |asig|
        total = true
        progs = asig.programaciones.del_periodo(current_periodo.id)
        if progs.count > 0
          total = false unless progs.delete_all
        end
      end
      # if Seccion.del_periodo(current_periodo.id).de_la_escuela(@escuela.id).delete_all
      # if Seccion.del_periodo(current_periodo.id).joins(:escuela).where("escuelas.id = ?", 'EDUC').delete_all

      Seccion.del_periodo(current_periodo.id).de_la_escuela(@escuela.id).each do |sec|
        sec.delete
      end
      info_bitacora("Eliminada programación de escuela: #{@escuela.descripcion}. Del período #{current_periodo.id}", 3)
      flash[:info] = "¡Programaciones eliminadas correctamente!"
      redirect_back fallback_location: "#{asignaturas_path}?escuela_id=#{@escuela.id}"
    end

    def clonar_programacion
      periodo_anterior = Periodo.find params[:periodo_id]
      errores_programaciones = []
      errores_secciones = []
      total_secciones = periodo_anterior.secciones.de_la_escuela(@escuela.id).count
      total_programaciones = 0
      programaciones_existentes = 0
      errores_excepcionales = []

      @escuela.secciones.del_periodo(periodo_anterior.id).each do |se|
        principal = params[:profesores] ? se.profesor_id : nil
        begin

          nueva_seccion = Seccion.find_or_initialize_by(numero: se.numero, asignatura_id: se.asignatura_id, periodo_id: current_periodo.id)
          nueva_seccion.profesor_id = principal
          nueva_seccion.capacidad = se.capacidad
          nueva_seccion.tipo_seccion_id = se.tipo_seccion_id
          nueva_seccion.save
        rescue Exception => e
          errores_excepcionales << "Error al crear o buscar sección: #{nueva_seccion.id} #{e}"
        end

        begin
          if params[:profesores]
            se.secciones_profesores_secundarios.each do |secundario|
              SeccionProfesorSecundario.find_or_create_by(profesor_id: secundario.profesor_id, seccion_id: nueva_seccion.id)
            end
          else
            nueva_seccion.secciones_profesores_secundarios.delete_all
          end
        rescue Exception => e
          errores_excepcionales << "Error al intentar agregar profesores secundarios a #{se.descripcion_simple}: #{e} </br></br>"
        end

        begin
          if params[:horarios] and se.horario
            nueva_seccion.horario.delete if nueva_seccion.horario
            Horario.create(seccion_id: nueva_seccion.id, color: se.horario.color)
            se.horario.bloquehorarios.each do |bh|
              bh_aux = Bloquehorario.new(dia: bh.dia, entrada: bh.entrada, salida: bh.salida, horario_id: nueva_seccion.id)
              bh_aux.profesor_id = bh.profesor_id if params[:profesores]
              bh_aux.save
            end
          end
        rescue Exception => e
          errores_excepcionales << "Error al intentar agregar horario a #{seccion_nueva.descripcion_simple}: #{e} </br></br>"
        end

          info_bitacora("Clonación de secciones de la escuela: #{@escuela.descripcion}. Del período #{periodo_anterior.id} al periodo #{current_periodo.id}", 5)
      end

      periodo_anterior.programaciones.de_la_escuela(@escuela.id).each do |pr|
        if progr_aux = Programacion.where(periodo_id: current_periodo.id, asignatura_id: pr.asignatura_id).first
          programaciones_existentes += 1
        else
          progr_aux = Programacion.new(periodo_id: current_periodo.id, asignatura_id: pr.asignatura_id)
          if progr_aux.save
            total_programaciones += 1 
          else
            errores_programaciones << "No se logró activar asignatura #{pr.asignatura_id}: #{progr_aux.errors.full_messages.to_sentence}"   
          end
        end
      end

      flash[:success] = "Clonación con éxito de un total de #{total_secciones - errores_secciones.count} secciones."
      
      flash[:danger] = "<b> Secciones no agregadas #{errores_secciones.count}:</b></br> #{errores_secciones.to_sentence}" if errores_secciones.any?
      flash[:info] = "<b>Información Complementaria:</b>  </br>"

      flash[:info] += "<b></br>Programaciones:</b></br>"
      flash[:info] += "Se activaron #{total_programaciones} asignaturas de un total de #{periodo_anterior.programaciones.de_la_escuela(@escuela.id).count}. "
      flash[:info] += "Estaban ya activas #{programaciones_existentes} asignaturas de un total de #{periodo_anterior.programaciones.de_la_escuela(@escuela.id).count}. "

      flash[:info] += "<b> #{errores_programaciones.count} Programaciones no activadas:</b></br> #{errores_programaciones.to_sentence}" if errores_programaciones.any?

      redirect_back fallback_location: "#{asignaturas_path}?escuela_id=#{@escuela.id}"

    end

    def index
      @titulo = "Escuelas"
      @escuelas = current_admin.escuelas
    end

    # GET /escuelas/1
    # GET /escuelas/1.json
    def show
      session['escuela_id'] = params[:id]
      @titulo = "Escuela #{@escuela.descripcion.titleize}"
      @escuelaperiodo = @escuela.escuelaperiodos.where(periodo_id: current_periodo.id).first
    end

    # GET /escuelas/new
    def new
      @titulo = "Nueva Escuela"
      @escuela = Escuela.new
    end

    # GET /escuelas/1/edit
    def edit
      @titulo = "Editando Escuela: #{@escuela.descripcion}"
    end

    # POST /escuelas
    # POST /escuelas.json
    def create
      @escuela = Escuela.new(escuela_params)

      respond_to do |format|
        if @escuela.save
          
          info_bitacora_crud Bitacora::CREACION, @escuela
          format.html { redirect_to @escuela, notice: 'Escuela creada con éxito.' }
          format.json { render :show, status: :created, location: @escuela }
        else
          format.html { render :new }
          format.json { render json: @escuela.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /escuelas/1
    # PATCH/PUT /escuelas/1.json
    def update
      respond_to do |format|
        if @escuela.update(escuela_params)
          info_bitacora_crud Bitacora::ACTUALIZACION, @escuela
          flash[:success] = 'Escuela actualizada con éxito.'
          format.html { redirect_back fallback_location: @escuela}
          format.json { render :show, status: :ok, location: @escuela }
        else
          format.html { render :edit }
          format.json { render json: @escuela.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /escuelas/1
    # DELETE /escuelas/1.json
    def destroy

      if @escuela.periodos.any?
        flash[:danger] = "No es posible eliminar la escuela, se encuentra asociada a un total de #{@escuela.periodos.count} peridos. Elmine dicha relación e inténtelo de nuevo."
      elsif @escuela.grados.any?
        flash[:danger] = "No es posible eliminar la escuela, hay #{@escuela.grados.count} estudiante(s) inscrito(s) en ella. Por favor elimínelo(s) e inténtelo de nuevo."
      elsif @escuela.asignaturas.any?
        flash[:danger] = "No es posible eliminar la escuela, hay #{@escuela.asignaturas.count} asignaturas registradas en ella. Por favor elimínela(s) e inténtelo de nuevo."
      elsif @escuela.secciones.any?
        flash[:danger] = "No es posible eliminar la escuela, hay #{@escuela.secciones.count} secciones registradas en ella. Por favor elimínela(s) e inténtelo de nuevo."
      elsif @escuela.departamentos.any?
        flash[:danger] = "No es posible eliminar la escuela, hay #{@escuela.departamentos.count} departamentos registrados en ella. Por favor elimínelo(s) e inténtelo de nuevo."
      else
        info_bitacora_crud Bitacora::ELIMINACION, @escuela 
        @escuela.destroy
      end

      respond_to do |format|
        format.html { redirect_to escuelas_url, notice: 'Escuela eliminada satisfactoriamente.' }
        format.json { head :no_content }
      end
    end

    def set_periodo_inscripcion
      begin
        params[:periodo_inscripcion_id] = nil if params[:periodo_inscripcion_id].eql? ""
        @escuela.periodo_inscripcion_id = params[:periodo_inscripcion_id]
        if @escuela.save
          aux = @escuela.periodo_inscripcion_id.nil? ? 'Inscripción Cerrada' : "Inscripción abierta para el período #{@escuela.periodo_inscripcion_id}."
          info_bitacora aux, Bitacora::ACTUALIZACION, @escuela
          flash[:success] = aux
        else
          flash[:danger] = "Error al intentar establecer periodo de inscripción: #{@escuela.errors.full_messages.to_sentence}"
        end
      rescue Exception => e
        flash[:danger] = "Error inesperado: #{e}"
      end
      redirect_back fallback_location: escuelas_path

    end

    def update_dependencias
      begin
        @escuela.habilitar_dependencias = !@escuela.dependencias_habilitadas?
        if @escuela.save
          aux = "¡Escuela actualizada!"
          render json: {data: aux, status: :success}
        else
          render json: {data: "Error al intentar cambio: #{@escuela.errors.full_messages.to_sentence}", status: :error}
        end
      rescue Exception => e
        render json: {data: "Error Excepcional: #{e}", status: :danger}
      end

    end


    # def set_inscripcion_abierta
    #   @escuela.inscripcion_abierta = !@escuela.inscripcion_abierta
    #   if @escuela.save
    #     aux = @escuela.inscripcion_abierta ? 'Inscripción Abierta' : 'Inscripción Cerrada'
    #     render json: {data: aux, status: :success}
    #   else
    #     render json: {data: "Error al intentar cambiar la noticia : #{@escuela.errors.full_messages.to_sentence}", status: :success}
    #   end
      
    # end

    def set_habilitar_retiro_asignaturas
      @escuela.habilitar_retiro_asignaturas = !@escuela.habilitar_retiro_asignaturas
      if @escuela.save
        aux = @escuela.retiro_asignaturas_habilitado? ? 'Retiro y Eliminación de Asignaturas Habilitado' : 'Retiro y Eliminación de Asignaturas Deshabilitado'
        render json: {data: aux, status: :success}
      else
        render json: {data: "Error al intentar cambio: #{@escuela.errors.full_messages.to_sentence}", status: :success}
      end
      
    end

    def set_habilitar_cambio_seccion
      @escuela.habilitar_cambio_seccion = !@escuela.habilitar_cambio_seccion
      if @escuela.save
        aux = @escuela.cambio_seccion_habilitado? ? 'Habilitado Cambios de Secciones' : 'Deshabilitado Cambios de Secciones'
        render json: {data: aux, status: :success}
      else
        render json: {data: "Error al intentar cambio: #{@escuela.errors.full_messages.to_sentence}", status: :success}
      end 
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_escuela
        @escuela = Escuela.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def escuela_params
        params.require(:escuela).permit(:descripcion, :id, :inscripcion_abierta, :habilitar_retiro_asignaturas, :habilitar_cambio_seccion, :periodo_inscripcion_id, :periodo_activo_id, :habilitar_dependencias)
      end
  end
end