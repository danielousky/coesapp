module Admin
  class UsuariosController < ApplicationController
    require 'mini_magick'
    before_action :filtro_logueado
    before_action :filtro_administrador, except: [:edit, :update, :countries, :getMunicipios, :getParroquias, :update_images]
    before_action :filtro_admin_mas_altos!, except: [:busquedas, :index, :show, :edit, :update, :countries, :getMunicipios, :getParroquias, :update_images]
    before_action :filtro_super_admin!, only: [:set_administrador]
    before_action :filtro_ninjas_or_jefe_control_estudio!, only: [:destroy, :delete_rol]

    before_action :resize_image, only: [:update_images]

    before_action :filtro_autorizado

    before_action :set_usuario, except: [:index, :new, :create, :busquedas, :countries, :getMunicipios, :getParroquias, :no_mismo_usuario?]

    # GET /usuarios
    # GET /usuarios.json

    def update_images

      respond_to do |format|
        if @usuario.update(usuario_params)
          if params[:usuario][:foto_perfil]
            url = main_app.url_for(@usuario.foto_perfil)
            filename = @usuario.foto_perfil_blob.filename
          else
            url = main_app.url_for(@usuario.imagen_ci)
            filename = @usuario.imagen_ci_blob.filename
          end
          info_bitacora "Agregadas imágenes de respaldo del usuario #{@usuario.descripcion}", Bitacora::CREACION, @usuario
          format.json { render json: {usuario: @usuario, url: url, filename: filename},  status: :ok}
        else
          format.json { render json: @usuario.errors, status: :unprocessable_entity }
        end
      end
    end


    def getMunicipios
      render json: Direccion.municipios(params[:term]), status: :ok
    end

    def getParroquias
      render json: Direccion.parroquias(params[:estado], params[:term]), status: :ok
    end

    def countries
      country = params[:term]
      data_hash = Usuario.naciones
      render json: data_hash[country].sort{|a,b| a <=> b}, status: :ok
    end

    def busquedas
      # @usuarios = Usuario.search(params[:term])
      if params[:estudiantes]
        @usuarios = Usuario.search(params[:term]).limit(10).reject{|u| u.estudiante.nil?} 
      elsif params[:profesores]
        @usuarios = Usuario.search(params[:term]).limit(10).reject{|u| u.profesor.nil?}
      else
        @usuarios = Usuario.search(params[:term]).limit(10)
      end
    end

    def index
      @titulo = 'Usuarios'

      if params[:search]
        @usuarios = Usuario.search(params[:search]).limit(50)
        if @usuarios.count > 0 && @usuarios.count < 50
          if @usuarios.count.eql? 1
            flash[:success] = "Una coincidencia, redirigido al detalle del usuario"
            redirect_to @usuarios.first
          else
            flash[:success] = "Total de coincidencias: #{@usuarios.count}"
          end
        elsif @usuarios.count == 0
          flash[:error] = "No se encontraron conincidencas. Intenta con otra búsqueda"
        else
          flash[:error] = "50 o más conincidencia. Puedes ser más explícito en la búsqueda. Recuerda que puedes buscar por CI, Nombre, Apellido, Correo Electrónico o incluso Número Telefónico"
        end
      else
        @usuarios = Usuario.limit(50).order("created_at, apellidos, nombres, ci")      
      end
    end

    def set_estudiante
      e = Estudiante.new
      e.usuario_id = @usuario.id
      if e.save
        flash[:success] = 'Estudiante registrado con éxito'
        if e.grados.create(escuela_id: params[:estudiante][:escuela_id])
          flash[:success] = 'Estudiante inscrito en la escuela con éxito' 
        else
          flash[:error] = "El estudiante no se pudo inscribir en la escula seleccionada. Error: # #{e.errors.full_messages.to_sentence}"
        end

        # OJO: No se puede implementar esto ya que no se tiene información sobre a partir de cuando (PERIODO_ID) es el plan
        # Debería incorporarse al form de set estudiante y al form de create usuario el plan y apartir de cuando

        # escuela = Escuela.find params[:estudiante][:escuela_id]
        # planes = escuela.planes
        # e.historialplanes.create(plan_id: planes.first.id) if planes.count.eql? 1
        info_bitacora_crud Bitacora::CREACION, e
      else
        flash[:danger] = "Error: #{e.errors.full_messages.to_sentence}."
      end
      redirect_to @usuario

    end

    def set_administrador
      unless a = @usuario.administrador
        a = Administrador.new
        a.usuario_id = @usuario.id
      end

      a.rol = params[:administrador][:rol]

      if params[:administrador][:rol].eql? "admin_departamento"
        a.departamento_id = params[:administrador][:departamento_id] 
        a.escuela_id = nil
      elsif params[:administrador][:rol].eql? "admin_escuela"
        a.escuela_id = params[:administrador][:escuela_id]
        a.departamento_id = nil
      else
        a.departamento_id = nil
        a.escuela_id = nil
      end

      if a.save
        info_bitacora_crud Bitacora::CREACION, a
        flash[:success] = 'Administrador guardado con éxito'
      else
        flash[:danger] = "Error: #{a.errors.full_messages.to_sentence}."
      end
      redirect_to @usuario

    end

    def set_profesor

      if pr = @usuario.profesor
      else
        pr = Profesor.new
        pr.usuario_id = @usuario.id
      end
      
      anterior = pr.departamento if params[:cambiar_dpto]

      pr.departamento_id = params[:profesor][:departamento_id]
      if pr.save
        if params[:cambiar_dpto]
          info_bitacora "Cambio de escuela de #{anterior.descripcion_completa} a #{pr.departamento.descripcion_completa}", Bitacora::CREACION, pr
        else
          info_bitacora_crud Bitacora::CREACION, pr
        end
        flash[:success] = 'Profesor guardado con éxito'
      else
        flash[:danger] = "Error: #{a.errors.full_messages.to_sentence}."
      end
      redirect_to @usuario

    end


    def delete_rol
      if params[:estudiante]
        u = Estudiante.find params[:id]
      elsif params[:profesor]
        u = Profesor.find  params[:id]
      elsif params[:administrador]
        u = Administrador.find params[:id]
      else
        flash[:danger] = "Error: Rol no encontrado."
      end
      if u and u.destroy
        flash[:info] = "Rol Eliminado." 
        info_bitacora_crud Bitacora::ELIMINACION, u
      end
      redirect_back fallback_location: index2_secciones_path
        
    end


    def resetear_contrasena
      @usuario.password = @usuario.ci
      
      if @usuario.save
        info_bitacora 'Reseteo de contraseña', Bitacora::ACTUALIZACION, @usuario
        flash[:success] = "Contraseña reseteada corréctamente"
      else
        flash[:error] = "no se pudo resetear la contraseña"
      end
      redirect_to @usuario
      
    end

    def cambiar_ci
      @usuario.id = params[:cedula]
      if @usuario.save
        if params[:cedula].eql? session[:administrador_id]
          session[:administrador_id] = session[:usuario_ci] = @usuario.id
        end
        info_bitacora 'Cambio de CI', Bitacora::ACTUALIZACION, @usuario
        flash[:success] = "Cambio de cédula de identidad correcto."
      else
        flash[:error] = "Error excepcional: #{@usuario.errors.full_messages.to_sentence}."
        @usuario = Usuario.find(params[:id])
      end
      redirect_to @usuario
    end

    # GET /usuarios/1
    # GET /usuarios/1.json
    def show
      if params[:escuela_id]
        session[:usuarioTypeTab] = 'estudiante'
        session[:tabEscuela] = params[:escuela_id] 
      end

      @estudiante = @usuario.estudiante
      @profesor = @usuario.profesor
      @administrador = @usuario.administrador
      @perfil = Perfil.new if @administrador
      #@periodos = @estudiante.escuela.periodos.order("inicia DESC") if @estudiante

      if @estudiante
        @periodos = Periodo.joins(:inscripcionseccion).where("inscripcionsecciones.estudiante_id = #{@estudiante.id}")
        @inactivo = "<span class='label label-warning'>Inactivo</span>" if @estudiante.inactivo? current_periodo.id
        ids = @estudiante.inscripcionsecciones.select{|ins| ins.pci_pendiente_por_asociar?}.collect{|i| i.id}
        @secciones_pci_pendientes = Inscripcionseccion.where(id: ids)#select{|ins| ins.pci_pendiente_por_asociar?}.ids
      end  
      # @escuelas_disponibles = @estudiante ? current_admin.escuelas.reject{|es| @estudiante.escuelas.include? es} : current_admin.escuelas
      @escuelas_disponibles = @estudiante ? Escuela.all.reject{|es| @estudiante.escuelas.include? es} : Escuela.all

      if @profesor
        @secciones_pendientes = @profesor.secciones.sin_calificar.order('periodo_id DESC, numero ASC')
        @secciones_calificadas = @profesor.secciones.calificadas.order('periodo_id DESC, numero ASC')
        @secciones_secundarias = @profesor.secciones_secundarias.order('periodo_id DESC, numero ASC')
      end
      @nickname = @usuario.nickname.capitalize
      @titulo = "Detalle de Usuario: #{@usuario.descripcion} #{@inactivo}"

    end

    # GET /usuarios/new
    def new
      if params[:estudiante]
        @titulo = "Nuevo Estudiante"
      elsif params[:profesor]
        @titulo = "Nuevo Profesor"
      elsif params[:administrador]
        @titulo = "Nuevo Administrador"
      else
        @titulo = "Nuevo Usuario"
      end
      @usuario = Usuario.new
      @escuelas_disponibles = @estudiante ? current_admin.escuelas.reject{|es| @estudiante.escuelas.include? es} : current_admin.escuelas
    end

    # GET /usuarios/1/edit
    def edit
      @titulo = "Editar Usuario: #{@usuario.descripcion}"
      estudiante = @usuario.estudiante
      if estudiante and estudiante.direccion
        @estado = @usuario.estudiante.direccion.estado
        if @estado
          @municipios = Direccion.municipios(@estado) 
          @municipio = estudiante.direccion.municipio
          if @municipio
            @parroquias = Direccion.parroquias(@estado, @municipio)
            @parroquia = estudiante.direccion.ciudad
          end
        end
      else
        @estado = nil
        @municipios = []
        @municipio = nil
        @parroquias = []
        @parroquia = nil
      end
    end

    # POST /usuarios
    # POST /usuarios.json
    def create
      @usuario = Usuario.new(usuario_params)

      respond_to do |format|
        if @usuario.save
          flash[:success] = 'Usuario creado con éxito.'
          if params[:estudiante_set]

            if e = Estudiante.create(usuario_id: @usuario.id) #, escuela_id: params[:estudiante][:escuela_id])
              # params[:grado]['escuela_id'] = params[:escuela_id]
              params[:grado]['estudiante_id'] = e.id
              # params[:grado]['iniciado_periodo_id'] = params[:periodo_id]

              if params[:grado]['estado_inscripcion']
                params[:grado]['inscrito_ucv'] = 1
              else
                params[:grado]['inscrito_ucv'] = 0
              end
              grado = Grado.new(grado_params)
              # grado.plan_id = params[:plan][:id]
              if grado.save!
                info_bitacora_crud Bitacora::CREACION, e
                historialplan = Historialplan.new
                historialplan.estudiante_id = e.id
                historialplan.periodo_id = params[:grado][:iniciado_periodo_id]
                historialplan.plan_id = params[:grado][:plan_id]

                if historialplan.save
                  info_bitacora_crud Bitacora::CREACION, historialplan
                  flash[:success] = 'Estudiante creado con éxito.' 
                end

                if params[:enviar_correo] and !@usuario.email.blank?
                  p '   CORREO ENVIADO    '.center(1000, "$")
                  begin
                    grado.enviar_correo_bienvenida(current_usuario.id, request.remote_ip)
                  rescue Exception => e
                    flash[:danger] = "No se pudo enviar el correo de bienvenida: #{e} "
                  end
                end

              end

            else
              flash[:danger] = "Error: #{e.errors.full_messages.to_sentence}"
            end
          elsif params[:administrador]
            a = Administrador.new
            a.usuario_id = @usuario.id
            a.rol = params[:administrador][:rol]

            unless params[:administrador][:departamento_id].blank?
              a.departamento_id = params[:administrador][:departamento_id] 
              a.escuela_id = nil
            end
            unless params[:administrador][:escuela_id].blank?
              a.escuela_id = params[:administrador][:escuela_id]
              a.departamento_id = nil
            end

            if a.save
              info_bitacora_crud Bitacora::CREACION, a
              flash[:success] = 'Administrador creado con éxito.'
            else
              flash[:danger] = "Error: #{a.errors.full_messages.to_sentence}"
            end
          elsif params[:profesor]
            pr = Profesor.new
            pr.usuario_id = @usuario.id
            pr.departamento_id = params[:profesor][:departamento_id]

            if pr.save
              info_bitacora_crud Bitacora::CREACION, pr
              flash[:success] = 'Profesor creado con éxito.'
            else
              flash[:danger] = "Error: #{pr.errors.full_messages.to_sentence}"
            end
          end
              
          format.html { redirect_to @usuario}
          format.json { render :show, status: :created, location: @usuario }
        else
          flash[:danger] = "Error: #{@usuario.errors.full_messages.to_sentence}"
          format.html { redirect_back fallback_location: new_usuario_path }
          format.json { render json: @usuario.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /usuarios/1
    # PATCH/PUT /usuarios/1.json
    def update

      if current_admin
        if current_admin.maestros?
          url_back = @usuario
        else
          url_back = index2_secciones_path
        end
      elsif current_usuario.estudiante
        url_back = principal_estudiante_index_path
      elsif current_usuario.profesor
        url_back = principal_profesor_index_path
      end

      if @usuario.update(usuario_params)
        # @usuario.estudiante.direccion.create(direccion_params)
        info_bitacora_crud Bitacora::ACTUALIZACION, @usuario
        flash[:success] = "Usuario actualizado con éxito"
        if @usuario.estudiante
          if @direccion = Direccion.where(estudiante_id: @usuario.estudiante.id).first
            
              flash[:info] = @direccion.update(direccion_params) ? 'Dirección actualizada' : 'No se pudo actualizar la dirección'
          else
            @direccion = Direccion.new(direccion_params)
            flash[:info] = @direccion.save ? 'Nueva dirección agregada a los registros del sistema.' : 'No se pudo guardar la dirección del estudiante'
          end

          @usuario.estudiante.discapacidad = params[:estudiante][:discapacidad]
          @usuario.estudiante.titulo_universitario = params[:estudiante][:titulo_universitario]
          @usuario.estudiante.titulo_universidad = params[:estudiante][:titulo_universidad]
          @usuario.estudiante.titulo_anno = params[:date][:year]

          if @usuario.estudiante.save
            flash[:success] = "Estudiante actualizado con éxito"
          else
            flash[:error] = "No se pudo completar la actualización. Por favor revise e inténtelo nuevamente: #{@usuario.estudiante.errors.full_messages.to_sentence}."
          end
        end  
        redirect_to url_back
      else
        flash[:danger] = "Error: #{@usuario.errors.full_messages.to_sentence}."
        params[:estudiante] = nil
        if @usuario.estudiante and @usuario.estudiante.direccion
          @estado = @usuario.estudiante.direccion.estado
          if @estado
            @municipios = Direccion.municipios(@estado) 
            @municipio = @usuario.estudiante.direccion.municipio
            if @municipio
              @parroquias = Direccion.parroquias(@estado, @municipio)
              @parroquia = @usuario.estudiante.direccion.ciudad
            end
          end
        else
          @estado = nil
          @municipios = []
          @municipio = nil
          @parroquias = []
          @parroquia = nil
        end
        @titulo = "Editar Usuario: #{@usuario.descripcion}"
        redirect_to edit_usuario_path(@usuario) 
      end
    end

    # DELETE /usuarios/1
    # DELETE /usuarios/1.json
    def destroy
      info_bitacora_crud Bitacora::ELIMINACION, @usuario
      @usuario.destroy
      respond_to do |format|
        format.html { redirect_to usuarios_url, notice: 'Usuario eliminado satisfactoriamente.' }
        format.json { head :no_content }
      end
    end
    
    protected

      def mismo_usuario?
        if action_name.eql? 'index'
          return true
        elsif params[:id]
          @usuario = Usuario.find(params[:id])
          @usuario.id.eql? current_usuario.id
        else
          true
        end
      end

    private
      # Use callbacks to share common setup or constraints between actions.

      def resize_image

        aux = params[:usuario][:foto_perfil]

        if aux #and aux.byte_size > 1.megabyte
          mini_image = MiniMagick::Image.new(params[:usuario][:foto_perfil].tempfile.path)
          mini_image.resize '200x400^'
        end

        aux = params[:usuario][:imagen_ci]

        if aux #and aux.byte_size > 1.megabyte
          mini_image = MiniMagick::Image.new(params[:usuario][:imagen_ci].tempfile.path)
          mini_image.resize '400x400^'
        end

      end

      def set_usuario
        @usuario = Usuario.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def usuario_params
        params.require(:usuario).permit(:ci, :nombres, :apellidos, :email, :telefono_habitacion, :telefono_movil, :password, :sexo, :password_confirmation, :nacionalidad, :estado_civil, :fecha_nacimiento, :pais_nacimiento, :ciudad_nacimiento, :foto_perfil, :imagen_ci)
      end

      def administrador_params
        params.require(:administrador).permit(:rol, :departamento_id, :escuela_id)
      end

      def grado_params
        params.require(:grado).permit(:escuela_id, :estudiante_id, :estado, :culminacion_periodo_id, :tipo_ingreso, :inscrito_ucv, :estado_inscripcion, :iniciado_periodo_id, :plan_id)
      end

      def direccion_params
        params.require(:direccion).permit(:estudiante_id, :estado, :municipio, :ciudad, :sector, :calle, :tipo_vivienda, :nombre_vivienda)
      end

      # def date_params
      #   params.require(:date).permit(:year)
      # end

  end
end