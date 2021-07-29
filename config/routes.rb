
Rails.application.routes.draw do
  # default_url_options host: 'https://coes.nyc3.digitaloceanspaces.com'

  resources :visitors, only: [:index] do
    collection do
      post :validar
      get 'olvido_clave'
      get 'un_rol'
      get 'seleccionar_rol'
      get 'cerrar_sesion'
      post 'olvido_clave_guardar'
      get 'olvido_clave_guardar'
      # get 'usuario'
    end
    member do
    end
  end

  resources :verificar do
    member do
      get 'documento'
      get 'descargar_documento'
    end
  end

  scope module: :admin do
    resources :tipo_secciones, :tipoasignaturas, :tipo_calificaciones, :tipo_estado_inscripciones, :bloquehorarios, :restringidas, :bitacoras, :reportepagos, :bancos



    resources :perfiles do
      member do
        post 'autorizar_usuario'
      end
    end
    resources :inscripcionescuelaperiodos, only: :index
    resources :parametros_generales, only: :index do 
      member do
        post :update
      end
    end

    resources :escuelaperiodos, only: :show

    resources :horarios do
      member do
        get 'get_bloques'
      end
    end

    resources :autorizadas, only: :index do 
      member do
        post 'set'
      end
    end

    resources :grados, only: :index do
      member do
        post 'agregar'
        post 'eliminar'
        get 'cambiar_estado'
        post 'cambiar_inscripcion'
      end
      collection do
        get 'index_nuevos'
        get 'citas_horarias'
        post 'citas_horarias'
      end
    end

    resources :comentarios do
      member do
        get 'habilitar'
      end
    end

    get '/importador/seleccionar_archivo'
    get '/importador/index'
    get '/importador/seleccionar_archivo_inscripciones'
    get '/importador/seleccionar_archivo_profesores'
    get '/importador/seleccionar_archivo_estudiantes'
    post '/importador/vista_previa'
    post '/importador/importar'
    post '/importador/importar_inscripciones'
    post '/importador/importar_profesores'
    post '/importador/importar_estudiantes'

    resources :administradores, only: :index

    resources :principal_admin, only: :index do
      collection do
        get 'index2'
        get 'set_tab'
        post 'cambiar_sesion_periodo'
      end
      member do 
        get 'ver_seccion_admin'
        post 'cambiar_estudiante_escuela'
      end
    end

    resources :principal_profesor, only: :index 
    resources :principal_estudiante, only: :index do
      post 'actualizar_idiomas'
    end


    resources :periodos, :planes, :departamentos, :catedras
    resources :escuelas do 
      member do
        get 'periodos'
        post 'set_periodo_inscripcion'
        get 'set_habilitar_retiro_asignaturas'
        get 'set_habilitar_cambio_seccion'
        get 'limpiar_programacion'
      end
      collection do
        post 'clonar_programacion'
      end

    end
    
    resources :historialplanes, :dias

    resources :catedradepartamentos, only: [:create, :destroy]

    resources :carteleras do
      member do
        get 'set_activa'
      end
    end
    resources :descargar do
      member do
        get 'verificar_constancia_estudio'
        get 'exportar_lista_csv'
        get 'exportar_historial_grado'
        get :kardex
        get 'acta_examen_excel'
        get 'acta_examen'
        get 'constancia_inscripcion'
        get 'constancia_preinscripcion_facultad'
        get 'constancia_estudio'
        get 'listado_seccion'
        get 'listado_seccion_excel'
        get 'notas_seccion'
        get 'notas_seccion_online'
        get 'actas_secciones_escuelaperiodo'
        get 'inscritos_escuela_periodo'
        get 'listado_completo_estudiante'
      end
    end

    resources :inscripcionsecciones do
      collection do
        post 'reservar_cupo'
        post 'confirmar_inscripcion_idiomas201902A'
        post 'preinscribirse'
        get 'buscar_estudiante'
        get :seleccionar
        post :inscribir
        post :crear
        post 'cambiar_calificacion' 
        post 'set_escuela_pci'
        post 'cambiar_seccion'
      end
      member do
        get :seleccionar
        get :resumen
        get 'cambiar_estado'
      end
    end

    resources :secciones do
      collection do
        get 'get_profesores'
        get 'get_tab_objects'
        get 'index2'
        get 'get_secciones'
        get 'habilitar_calificar'
        get 'habilitar_calificar_trim'
        post 'cambiar_capacidad'
        post 'cambiar_profe_seccion'
        post 'agregar_profesor_secundario'
        get 'importar_secciones'
      end
      member do
        get 'desasignar_profesor_secundario'
        get 'seleccionar_profesor'
        post :calificar
        get 'delete_all_inscripcions'
        get 'descargar_notas'
        get 'habilitar_calificar'
        get 'habilitar_calificar_trim'
      end
    end

    resources :asignaturas do
      member do
        get 'set_activa'
        get 'set_pci'
      end
    end

    resources :combinaciones
    resources :usuarios do
      collection do
        # post :index
        get :busquedas
        get :countries
        get :getMunicipios
        get :getParroquias
      end
      member do
        get 'delete_rol'
        post 'update_images'
        post 'set_estudiante'
        post 'set_administrador'
        post 'set_profesor'
        post 'cambiar_ci'
        get 'resetear_contrasena'
      end
    end
  end
  
  get '/check.txt', to: proc {[200, {}, ['it_works']]}
  
  root to: 'visitors#index'
end
