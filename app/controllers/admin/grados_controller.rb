module Admin
  class GradosController < ApplicationController
    # Privilegios
    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado, only: [:agregar, :update, :eliminar, :index]
    before_action :set_grado, only: [:update, :eliminar]

    def citas_horarias
      # Colocar un mensaje que si en el periodo actual no está dentro de los periodos de la escuela debe cambiarlos
      @escuelas = current_periodo.escuelas.merge current_admin.escuelas
      @periodos = Periodo.all # Esto debe ser dinamico en funcion a los periodods de la escuela seleccionada
      if params[:criterios]
        @escuela = Escuela.find params[:criterios][:escuela_id]
        @periodos_ids = params[:criterios][:periodo_ids]#.reject(&:empty?)
        aux = params[:criterios][:periodo_ids] ? params[:criterios][:periodo_ids].to_sentence : 'Todos'
        flash[:success] = "<b>Criterios de Búsqueda: </b> Escuela: #{@escuela.descripcion}. Períodos: #{aux}"

        @periodo_anterior = @escuela.periodo_anterior current_periodo.id
        
        ep = Escuelaperiodo.where(escuela_id: @escuela.id, periodo_id: current_periodo.id)

        # Criterios temporales para la generacion de la cita horaria de EIM 2019-02A
        # PARA LOS QUE TIENEN SOLO INSCRIPCIONES DEL 2019-02A
        # @grados = @escuela.grados.con_inscripciones.where(iniciado_periodo_id: '2019-02A').distinct

        # PARA LOS QUE TIENEN INSCRIPCIONES ANTERIORES AL 2019-02A
        ## @grados = @escuela.grados.reject{|gr| !gr.inscripciones.map{ |ins| ins.seccion.periodo_id}.include? '2019-02A'}

        # @grados = @escuela.grados.con_inscripciones.where("iniciado_periodo_id != '2019-02A'").distinct
        
        @grados = @escuela.grados.con_inscripciones.iniciados_en_periodos(@periodos_ids) if params[:criterios][:iniciados_en]

        # @grados = @grados.reject{|grado| !grado.inscrito_en_periodo? @periodo_anterior} if params[:criterios][:sin_inscripciones_periodo_anterior]

        if params[:criterios][:criterio1].eql? 'EFICIENCIA'
          # @grados = @grdos.order_by{|o| o.eficiencia @periodos_ids}
          @grados = @grados.sort {|a,b| a.eficiencia(@periodos_ids) <=> b.eficiencia(@periodos_ids)}
        end

      end
    end


    def cambiar_estado
      estado = params[:estado].to_i
      grado = Grado.find(params[:id])
      estudiante_id = grado.estudiante_id
      escuela_id = grado.escuela_id
      escuelas_ids = current_admin.escuelas.ids
      if estado.eql? 1
        escuelas_ids = current_admin.escuelas.ids
        # Creo que pudieran publicarse todas los grados no solo del periodo como en la linea d abajo
        # inscripcion = grado.inscripciones.grados.de_la_escuela(escuela_id).first
        inscripcion = grado.inscripciones.proyectos.del_periodo(current_periodo.id).de_la_escuela(escuela_id).first
        estado_anterior = inscripcion.estado
        info_bitacora "Cambio de estado del estudiante #{estudiante_id} de #{estado_anterior} a #{inscripcion.estado}", Bitacora::ACTUALIZACION, inscripcion if inscripcion.update_attributes(estado: :sin_calificar)
        total1 = Inscripcionseccion.proyectos.del_periodo(current_periodo.id).de_las_escuelas(escuelas_ids).sin_calificar.count
        total2 = Grado.de_las_escuelas(escuelas_ids).culminado_en_periodo(current_periodo.id).posible_graduando.count
      elsif estado > 1

        Grado.where(escuela_id: escuela_id, estudiante_id: estudiante_id).first.update(estado: estado, culminacion_periodo_id: current_periodo.id)

        total1 = Grado.de_las_escuelas(escuelas_ids).culminado_en_periodo(current_periodo.id).where(estado: estado-1).count
        total2 = Grado.de_las_escuelas(escuelas_ids).culminado_en_periodo(current_periodo.id).where(estado: estado).count
      end
      tr = view_context.render partial: '/admin/grados/detalle_registro', locals: {registro: grado, estado: estado}
      msg = "Cambio de estado de #{grado.estudiante.usuario.descripcion}"

      render json: {tr: tr, msg: msg, total1: total1, total2: total2}, status: :ok

    end

    def agregar
      # unless @estudiante = Estudiante.where(params[:id]).first
      #   @estudiante = Estudiante.create!(usuario_id: params[:id])
      #   # params[:grado]['estudiante_id'] = params[:id]
      # end

      @estudiante = Estudiante.find_or_create_by(usuario_id: params[:id]) 
      params[:grado]
      if params[:grado]['estado_inscripcion']
        params[:grado]['inscrito_ucv'] = 1
      else
        params[:grado]['inscrito_ucv'] = 0
      end
      grado = Grado.new(grado_params)

              
      if grado.save
        info_bitacora "Registrado en Escuela #{grado.escuela.descripcion}", Bitacora::CREACION, @estudiante
        info_bitacora_crud Bitacora::CREACION, grado
        historialplan = Historialplan.new
        historialplan.periodo_id = grado.iniciado_periodo_id
        historialplan.plan = grado.plan
        historialplan.grado = grado
        # historialplan.estudiante_id = @estudiante.id
        # historialplan.escuela_id = grado.escuela_id
        flash[:success] = '¡Registro de Carrera en escuela generado con éxito!'

        if historialplan.save
          info_bitacora_crud Bitacora::CREACION, historialplan
          flash[:success] = '¡Plan de carrera creada con éxito!' 
        else
          flash[:error] = "Error al intentar guardar el historial del plan: #{historialplan.errors.full_messages.to_sentence}"
        end
      else
        flash[:error] = "Error al intentar guardar la Carrera: #{grado.errors.full_messages.to_sentence}"
      end

      redirect_to usuario_path(@estudiante.id)

    end

    def index_nuevos
      escuelas_ids = current_admin.escuelas.ids
      grados = Grado.iniciados_en_periodo(current_periodo.id)#.limit(50)
      @preinscritos = grados.preinscrito
      @asignados = grados.asignado
      @confirmados = grados.confirmado.no_inscritos_ucv
      @inscritos_ucv = grados.inscritos_ucv
      @reincorporados = grados.reincorporado
      @nuevos = grados.con_inscripciones#.reject{|g| !g.inscripciones.any?}
      @nuevos_sin_sec = grados.con_inscripciones.no_inscritos_ucv#.reject{|g| !g.inscripciones.any?}
    end

    def index
      @titulo = 'Graduandos'
      escuelas_ids = current_admin.escuelas.ids
      if escuelas_ids.count > 0
      
        @registros = Grado.de_las_escuelas(escuelas_ids).culminado_en_periodo(current_periodo.id)


        @tesistas = Inscripcionseccion.proyectos.del_periodo(current_periodo.id).de_las_escuelas(escuelas_ids).sin_calificar

        # @posibles_graduandos = Grado.de_las_escuelas(escuelas_ids).posible_graduando.culminado_en_periodo(current_periodo.id)
        # @graduandos = Grado.de_las_escuelas(escuelas_ids).graduando.culminado_en_periodo(current_periodo.id)
        # @graduados = Grado.de_las_escuelas(escuelas_ids).graduado.culminado_en_periodo(current_periodo.id)
      else
        flash[:danger] = 'Debe tener al menos una escuela asociada. Por favor diríjase al personal administrativo correspondiente para solventar esto y vuelva a intentarlo.'
        redirect_back fallback_location: principal_admin_index_path
      end
    end
    # Fin Index

    def update
      params[:grado]['inscrito_ucv'] = true if (params[:grado]['estado_inscripcion'] and params[:grado]['estado_inscripcion'].eql? 'reincorporado')

      params[:grado]['autorizar_inscripcion_en_periodo_id'] = nil if params[:grado]['autorizar_inscripcion_en_periodo_id'].blank?

      if @grado.update(grado_params.to_hash)
        info_bitacora "Actualización de #{@grado.estudiante_id} en #{@grado.escuela.descripcion}: #{params[:grado]}", Bitacora::ACTUALIZACION, @grado
        flash[:success] = 'Actualización exitosa' 
      else
        flash[:success] = 'No se pudo completar la actualización. Por favor verifique e inténtelo nuevamente.'
      end
      redirect_back fallback_location: usuario_path(@grado.estudiante_id)
    end

    def eliminar
      estudiante_id = @grado.estudiante_id
      usuario = Usuario.find estudiante_id
      inscripciones = @grado.inscripciones
      total = 0
      if params[:escuela_destino_id] and inscripciones.any?
        inscripciones.each do |inscrip|
          inscrip.pci_escuela_id = params[:escuela_destino_id]
          total += 1 if inscrip.save
        end
      end

      info_bitacora_crud Bitacora::ELIMINACION, @grado

      if @grado.destroy
        flash[:info] = '¡Escuela Eliminada con éxito!'
        flash[:info] += " Se transfirieró un total de #{total} asignatura(s) como pci a #{params[:escuela_destino_id]}" if params[:escuela_destino_id]
      else
        flash[:danger] = 'No se pudo pudo eliminar la escuela. Por favor, inténtelo de nuevo.'
      end
      redirect_to principal_admin_index_path

    end
    # Fin Eliminar
    private

      def set_grado
        @grado = Grado.find params[:id]
      end

      def grado_params
        params.require(:grado).permit(:escuela_id, :estudiante_id, :estado, :culminacion_periodo_id, :tipo_ingreso, :inscrito_ucv, :estado_inscripcion, :iniciado_periodo_id, :plan_id, :autorizar_inscripcion_en_periodo_id, :region, :citahoraria, :duracion_franja_horaria)
      end

  end
end