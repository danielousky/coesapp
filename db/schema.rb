# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_10_06_222236) do

  create_table "active_storage_attachments", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "administradores", primary_key: "usuario_id", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "rol", null: false
    t.string "departamento_id"
    t.string "escuela_id"
    t.bigint "perfil_id"
    t.index ["departamento_id"], name: "index_administradores_on_departamento_id"
    t.index ["escuela_id"], name: "index_administradores_on_escuela_id"
    t.index ["perfil_id"], name: "index_administradores_on_perfil_id"
    t.index ["usuario_id"], name: "index_administradores_on_usuario_id"
  end

  create_table "asignaturas", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.integer "anno"
    t.integer "orden"
    t.integer "calificacion", default: 0
    t.boolean "activa", default: false
    t.string "departamento_id", null: false
    t.string "catedra_id", null: false
    t.string "tipoasignatura_id", null: false
    t.string "id_uxxi"
    t.integer "creditos"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pci", default: false, null: false
    t.index ["catedra_id"], name: "index_asignaturas_on_catedra_id"
    t.index ["departamento_id"], name: "index_asignaturas_on_departamento_id"
    t.index ["id"], name: "index_asignaturas_on_id"
    t.index ["tipoasignatura_id"], name: "index_asignaturas_on_tipoasignatura_id"
  end

  create_table "autorizadas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "restringida_id", null: false
    t.string "usuario_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["restringida_id", "usuario_id"], name: "index_autorizadas_on_restringida_id_and_usuario_id", unique: true
    t.index ["restringida_id"], name: "index_autorizadas_on_restringida_id"
    t.index ["usuario_id"], name: "index_autorizadas_on_usuario_id"
  end

  create_table "bancos", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_bancos_on_id"
  end

  create_table "bitacoras", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "comentario"
    t.string "descripcion"
    t.string "usuario_id"
    t.string "id_objeto"
    t.string "tipo_objeto"
    t.string "ip_origen"
    t.integer "tipo", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["usuario_id"], name: "index_bitacoras_on_usuario_id"
  end

  create_table "bloquehorarios", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "dia"
    t.time "entrada"
    t.time "salida"
    t.string "profesor_id"
    t.bigint "horario_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["horario_id", "dia", "entrada"], name: "index_bloquehorarios_on_horario_id_and_dia_and_entrada", unique: true
    t.index ["horario_id", "dia", "salida"], name: "index_bloquehorarios_on_horario_id_and_dia_and_salida", unique: true
    t.index ["horario_id"], name: "index_bloquehorarios_on_horario_id"
    t.index ["profesor_id"], name: "fk_rails_26c329a0d2"
  end

  create_table "carteleras", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "contenido"
    t.boolean "activa", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "catedradepartamentos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "departamento_id"
    t.string "catedra_id"
    t.integer "orden"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["catedra_id", "departamento_id"], name: "index_catedradepartamentos_on_catedra_id_and_departamento_id", unique: true
    t.index ["catedra_id"], name: "index_catedradepartamentos_on_catedra_id"
    t.index ["departamento_id", "catedra_id"], name: "index_catedradepartamentos_on_departamento_id_and_catedra_id", unique: true
    t.index ["departamento_id"], name: "index_catedradepartamentos_on_departamento_id"
  end

  create_table "catedras", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.integer "orden"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_catedras_on_id"
  end

  create_table "citahorarias", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.datetime "fecha", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "combinaciones", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "estudiante_id"
    t.string "periodo_id"
    t.string "idioma1_id"
    t.string "idioma2_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estudiante_id", "periodo_id"], name: "index_combinaciones_on_estudiante_id_and_periodo_id", unique: true
    t.index ["estudiante_id"], name: "index_combinaciones_on_estudiante_id"
    t.index ["idioma1_id"], name: "index_combinaciones_on_idioma1_id"
    t.index ["idioma2_id"], name: "index_combinaciones_on_idioma2_id"
    t.index ["periodo_id", "estudiante_id"], name: "index_combinaciones_on_periodo_id_and_estudiante_id", unique: true
    t.index ["periodo_id"], name: "index_combinaciones_on_periodo_id"
  end

  create_table "comentarios", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.text "contenido"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "estado", default: 0
    t.boolean "habilitado", default: true
  end

  create_table "delayed_jobs", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "departamentos", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.string "escuela_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["escuela_id"], name: "index_departamentos_on_escuela_id"
    t.index ["id"], name: "index_departamentos_on_id"
  end

  create_table "direcciones", primary_key: "estudiante_id", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "estado"
    t.string "municipio"
    t.string "ciudad"
    t.string "sector"
    t.string "calle"
    t.string "tipo_vivienda"
    t.string "nombre_vivienda"
    t.index ["estudiante_id"], name: "index_direcciones_on_estudiante_id"
  end

  create_table "escuelaperiodos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "periodo_id"
    t.string "escuela_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "max_creditos", default: 20
    t.integer "max_asignaturas", default: 3
    t.index ["escuela_id", "periodo_id"], name: "index_escuelaperiodos_on_escuela_id_and_periodo_id", unique: true
    t.index ["escuela_id"], name: "index_escuelaperiodos_on_escuela_id"
    t.index ["periodo_id", "escuela_id"], name: "index_escuelaperiodos_on_periodo_id_and_escuela_id", unique: true
    t.index ["periodo_id"], name: "index_escuelaperiodos_on_periodo_id"
  end

  create_table "escuelas", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "inscripcion_abierta", default: true
    t.boolean "habilitar_retiro_asignaturas", default: true
    t.boolean "habilitar_cambio_seccion", default: true
    t.string "periodo_inscripcion_id"
    t.string "periodo_activo_id"
    t.index ["id"], name: "index_escuelas_on_id"
    t.index ["periodo_activo_id"], name: "fk_rails_490583ce06"
    t.index ["periodo_inscripcion_id"], name: "fk_rails_5f0f1fec52"
  end

  create_table "estudiantes", primary_key: "usuario_id", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "tipo_estado_inscripcion_id"
    t.boolean "activo", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "citahoraria_id"
    t.string "discapacidad"
    t.string "titulo_universitario"
    t.string "titulo_universidad"
    t.string "titulo_anno"
    t.index ["citahoraria_id"], name: "index_estudiantes_on_citahoraria_id"
    t.index ["tipo_estado_inscripcion_id"], name: "index_estudiantes_on_tipo_estado_inscripcion_id"
    t.index ["usuario_id"], name: "index_estudiantes_on_usuario_id"
  end

  create_table "grados", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "escuela_id"
    t.string "estudiante_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "estado", default: 0, null: false
    t.string "culminacion_periodo_id"
    t.integer "tipo_ingreso", null: false
    t.boolean "inscrito_ucv", default: false
    t.integer "estado_inscripcion", default: 0, null: false
    t.string "plan_id"
    t.string "iniciado_periodo_id"
    t.bigint "reportepago_id"
    t.string "autorizar_inscripcion_en_periodo_id"
    t.integer "region", default: 0, null: false
    t.index ["culminacion_periodo_id"], name: "fk_rails_fef4486ce7"
    t.index ["escuela_id", "estudiante_id"], name: "index_grados_on_escuela_id_and_estudiante_id", unique: true
    t.index ["escuela_id"], name: "index_grados_on_escuela_id"
    t.index ["estudiante_id", "escuela_id"], name: "index_grados_on_estudiante_id_and_escuela_id", unique: true
    t.index ["estudiante_id"], name: "index_grados_on_estudiante_id"
    t.index ["iniciado_periodo_id"], name: "fk_rails_ee0083ce7b"
    t.index ["plan_id"], name: "index_grados_on_plan_id"
    t.index ["reportepago_id"], name: "index_grados_on_reportepago_id"
  end

  create_table "historialplanes", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "estudiante_id"
    t.string "periodo_id"
    t.string "plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "escuela_id"
    t.index ["escuela_id"], name: "index_historialplanes_on_escuela_id"
    t.index ["estudiante_id", "escuela_id", "periodo_id", "plan_id"], name: "unique_historial", unique: true
    t.index ["estudiante_id", "periodo_id"], name: "index_unique", unique: true
    t.index ["estudiante_id"], name: "index_historialplanes_on_estudiante_id"
    t.index ["periodo_id"], name: "index_historialplanes_on_periodo_id"
    t.index ["plan_id"], name: "index_historialplanes_on_plan_id"
  end

  create_table "horarios", primary_key: "seccion_id", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "titulo"
    t.string "color"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["seccion_id"], name: "index_horarios_on_seccion_id"
  end

  create_table "inscripcionescuelaperiodos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "estudiante_id", null: false
    t.bigint "escuelaperiodo_id", null: false
    t.string "tipo_estado_inscripcion_id"
    t.bigint "reportepago_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["escuelaperiodo_id"], name: "index_inscripcionescuelaperiodos_on_escuelaperiodo_id"
    t.index ["estudiante_id", "escuelaperiodo_id"], name: "index_inscripciones_on_estudiante_id_and_escuelaperiodo_id", unique: true
    t.index ["estudiante_id"], name: "index_inscripcionescuelaperiodos_on_estudiante_id"
    t.index ["reportepago_id"], name: "index_inscripcionescuelaperiodos_on_reportepago_id"
    t.index ["tipo_estado_inscripcion_id"], name: "index_inscripcionescuelaperiodos_on_tipo_estado_inscripcion_id"
  end

  create_table "inscripcionsecciones", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "seccion_id"
    t.string "estudiante_id"
    t.string "tipo_estado_calificacion_id"
    t.string "tipo_estado_inscripcion_id"
    t.string "tipoasignatura_id"
    t.float "primera_calificacion"
    t.float "segunda_calificacion"
    t.float "tercera_calificacion"
    t.float "calificacion_final"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "calificacion_posterior"
    t.integer "estado", default: 0, null: false
    t.string "tipo_calificacion_id"
    t.string "pci_escuela_id"
    t.string "escuela_id"
    t.boolean "pci", default: false
    t.bigint "inscripcionescuelaperiodo_id"
    t.index ["escuela_id"], name: "index_inscripcionsecciones_on_escuela_id"
    t.index ["estudiante_id", "seccion_id"], name: "index_inscripcionsecciones_on_estudiante_id_and_seccion_id", unique: true
    t.index ["estudiante_id"], name: "index_inscripcionsecciones_on_estudiante_id"
    t.index ["inscripcionescuelaperiodo_id"], name: "index_inscripcionsecciones_on_inscripcionescuelaperiodo_id"
    t.index ["pci_escuela_id"], name: "fk_rails_24a264013f"
    t.index ["seccion_id", "estudiante_id"], name: "index_inscripcionsecciones_on_seccion_id_and_estudiante_id", unique: true
    t.index ["seccion_id"], name: "index_inscripcionsecciones_on_seccion_id"
    t.index ["tipo_calificacion_id"], name: "fk_rails_d92b783c84"
    t.index ["tipo_estado_calificacion_id"], name: "index_inscripcionsecciones_on_tipo_estado_calificacion_id"
    t.index ["tipo_estado_inscripcion_id"], name: "index_inscripcionsecciones_on_tipo_estado_inscripcion_id"
    t.index ["tipoasignatura_id"], name: "index_inscripcionsecciones_on_tipoasignatura_id"
  end

  create_table "inscripcionsecciones_copy", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "seccion_id"
    t.string "estudiante_id"
    t.string "tipo_estado_calificacion_id"
    t.string "tipo_estado_inscripcion_id"
    t.string "tipoasignatura_id"
    t.float "primera_calificacion"
    t.float "segunda_calificacion"
    t.float "tercera_calificacion"
    t.float "calificacion_final"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["estudiante_id", "seccion_id"], name: "index_inscripcionsecciones_on_estudiante_id_and_seccion_id", unique: true
    t.index ["estudiante_id"], name: "index_inscripcionsecciones_on_estudiante_id"
    t.index ["seccion_id", "estudiante_id"], name: "index_inscripcionsecciones_on_seccion_id_and_estudiante_id", unique: true
    t.index ["seccion_id"], name: "index_inscripcionsecciones_on_seccion_id"
    t.index ["tipo_estado_calificacion_id"], name: "index_inscripcionsecciones_on_tipo_estado_calificacion_id"
    t.index ["tipo_estado_inscripcion_id"], name: "index_inscripcionsecciones_on_tipo_estado_inscripcion_id"
    t.index ["tipoasignatura_id"], name: "index_inscripcionsecciones_on_tipoasignatura_id"
  end

  create_table "inscripcionsecciones_copy1", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "seccion_id"
    t.string "estudiante_id"
    t.string "tipo_estado_calificacion_id"
    t.string "tipo_estado_inscripcion_id"
    t.string "tipoasignatura_id"
    t.float "primera_calificacion"
    t.float "segunda_calificacion"
    t.float "tercera_calificacion"
    t.float "calificacion_final"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.float "calificacion_posterior"
    t.integer "estado", default: 0, null: false
    t.string "tipo_calificacion_id"
    t.string "pci_escuela_id"
    t.string "escuela_id"
    t.boolean "pci", default: false
    t.index ["escuela_id"], name: "index_inscripcionsecciones_on_escuela_id"
    t.index ["estudiante_id", "seccion_id"], name: "index_inscripcionsecciones_on_estudiante_id_and_seccion_id", unique: true
    t.index ["estudiante_id"], name: "index_inscripcionsecciones_on_estudiante_id"
    t.index ["pci_escuela_id"], name: "fk_rails_24a264013f"
    t.index ["seccion_id", "estudiante_id"], name: "index_inscripcionsecciones_on_seccion_id_and_estudiante_id", unique: true
    t.index ["seccion_id"], name: "index_inscripcionsecciones_on_seccion_id"
    t.index ["tipo_calificacion_id"], name: "fk_rails_d92b783c84"
    t.index ["tipo_estado_calificacion_id"], name: "index_inscripcionsecciones_on_tipo_estado_calificacion_id"
    t.index ["tipo_estado_inscripcion_id"], name: "index_inscripcionsecciones_on_tipo_estado_inscripcion_id"
    t.index ["tipoasignatura_id"], name: "index_inscripcionsecciones_on_tipoasignatura_id"
  end

  create_table "parametros_generales", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "valor"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_parametros_generales_on_id"
  end

  create_table "perfiles", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "nombre"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "perfiles_restringidas", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.bigint "restringida_id", null: false
    t.bigint "perfil_id", null: false
    t.index ["perfil_id"], name: "perfiles_restringidas_perfile_id_fk"
    t.index ["restringida_id", "perfil_id"], name: "index_perfiles_restringidas_on_restringida_id_and_perfil_id", unique: true
  end

  create_table "periodos", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.date "inicia"
    t.date "culmina"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "tipo", null: false
    t.index ["id"], name: "index_periodos_on_id"
  end

  create_table "planes", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.string "escuela_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "creditos", default: 0
    t.index ["escuela_id"], name: "index_planes_on_escuela_id"
    t.index ["id"], name: "index_planes_on_id"
  end

  create_table "profesores", primary_key: "usuario_id", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "departamento_id"
    t.index ["departamento_id"], name: "index_profesores_on_departamento_id"
    t.index ["usuario_id"], name: "index_profesores_on_usuario_id"
  end

  create_table "programaciones", id: false, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "asignatura_id"
    t.string "periodo_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "pci", default: false, null: false
    t.index ["asignatura_id", "periodo_id"], name: "index_programaciones_on_asignatura_id_and_periodo_id", unique: true
    t.index ["asignatura_id"], name: "index_programaciones_on_asignatura_id"
    t.index ["periodo_id", "asignatura_id"], name: "index_programaciones_on_periodo_id_and_asignatura_id", unique: true
    t.index ["periodo_id"], name: "index_programaciones_on_periodo_id"
  end

  create_table "reportepagos", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "numero"
    t.decimal "monto", precision: 10
    t.integer "tipo_transaccion"
    t.date "fecha_transaccion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "banco_origen_id"
    t.index ["banco_origen_id"], name: "fk_rails_d6018c63f7"
  end

  create_table "restringidas", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.boolean "acceso_total", default: false
    t.string "nombre_publico", null: false
    t.string "controlador", null: false
    t.string "accion", null: false
    t.integer "grupo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["controlador", "accion"], name: "index_restringidas_on_controlador_and_accion", unique: true
    t.index ["nombre_publico"], name: "index_restringidas_on_nombre_publico", unique: true
  end

  create_table "seccion_profesores_secundarios", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "profesor_id"
    t.bigint "seccion_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["profesor_id", "seccion_id"], name: "seccion_secundarios_on_profesor_id_and_seccion_id", unique: true
    t.index ["profesor_id"], name: "index_seccion_profesores_secundarios_on_profesor_id"
    t.index ["seccion_id", "profesor_id"], name: "seccion_secundarios_on_seccion_id_and_profesor_id", unique: true
    t.index ["seccion_id"], name: "index_seccion_profesores_secundarios_on_seccion_id"
  end

  create_table "secciones", options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "numero"
    t.string "asignatura_id"
    t.string "periodo_id"
    t.string "profesor_id"
    t.boolean "calificada", default: false
    t.integer "capacidad"
    t.string "tipo_seccion_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "abierta", default: true
    t.index ["asignatura_id"], name: "index_secciones_on_asignatura_id"
    t.index ["numero", "periodo_id", "asignatura_id"], name: "index_secciones_on_numero_and_periodo_id_and_asignatura_id", unique: true
    t.index ["periodo_id"], name: "index_secciones_on_periodo_id"
    t.index ["profesor_id"], name: "index_secciones_on_profesor_id"
    t.index ["tipo_seccion_id"], name: "index_secciones_on_tipo_seccion_id"
  end

  create_table "tipo_calificaciones", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_tipo_calificaciones_on_id"
  end

  create_table "tipo_estado_calificaciones", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_tipo_estado_calificaciones_on_id"
  end

  create_table "tipo_estado_inscripciones", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_tipo_estado_inscripciones_on_id"
  end

  create_table "tipo_secciones", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_tipo_secciones_on_id"
  end

  create_table "tipoasignaturas", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8", force: :cascade do |t|
    t.string "descripcion"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["id"], name: "index_tipoasignaturas_on_id"
  end

  create_table "usuarios", primary_key: "ci", id: :string, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8 ROW_FORMAT=DYNAMIC", force: :cascade do |t|
    t.string "nombres"
    t.string "apellidos"
    t.string "email"
    t.string "telefono_habitacion"
    t.string "telefono_movil"
    t.string "password"
    t.integer "sexo", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "nacionalidad"
    t.integer "estado_civil"
    t.date "fecha_nacimiento"
    t.string "pais_nacimiento"
    t.string "ciudad_nacimiento"
    t.index ["ci"], name: "index_usuarios_on_ci"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "administradores", "departamentos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "administradores", "escuelas", on_update: :cascade, on_delete: :nullify
  add_foreign_key "administradores", "perfiles"
  add_foreign_key "administradores", "usuarios", primary_key: "ci", on_update: :cascade, on_delete: :cascade
  add_foreign_key "asignaturas", "catedras", on_update: :cascade, on_delete: :cascade
  add_foreign_key "asignaturas", "departamentos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "asignaturas", "tipoasignaturas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "autorizadas", "restringidas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "autorizadas", "usuarios", primary_key: "ci", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bloquehorarios", "horarios", primary_key: "seccion_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "bloquehorarios", "profesores", primary_key: "usuario_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "catedradepartamentos", "catedras", on_update: :cascade, on_delete: :cascade
  add_foreign_key "catedradepartamentos", "departamentos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "combinaciones", "departamentos", column: "idioma1_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "combinaciones", "departamentos", column: "idioma2_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "combinaciones", "estudiantes", primary_key: "usuario_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "combinaciones", "periodos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "departamentos", "escuelas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "direcciones", "estudiantes", primary_key: "usuario_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "escuelaperiodos", "escuelas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "escuelaperiodos", "periodos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "escuelas", "periodos", column: "periodo_activo_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "escuelas", "periodos", column: "periodo_inscripcion_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "estudiantes", "citahorarias", name: "estudiantes_ibfk_1", on_update: :cascade, on_delete: :nullify
  add_foreign_key "estudiantes", "usuarios", primary_key: "ci", name: "estudiantes_ibfk_3", on_update: :cascade, on_delete: :cascade
  add_foreign_key "grados", "escuelas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "grados", "estudiantes", primary_key: "usuario_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "grados", "periodos", column: "culminacion_periodo_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "grados", "periodos", column: "iniciado_periodo_id", on_update: :cascade, on_delete: :nullify
  add_foreign_key "grados", "reportepagos", on_update: :cascade, on_delete: :nullify
  add_foreign_key "historialplanes", "escuelas"
  add_foreign_key "historialplanes", "estudiantes", primary_key: "usuario_id", name: "historialplanes_ibfk_3", on_update: :cascade, on_delete: :cascade
  add_foreign_key "historialplanes", "periodos", name: "historialplanes_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "historialplanes", "planes", name: "historialplanes_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "horarios", "secciones", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionescuelaperiodos", "escuelaperiodos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionescuelaperiodos", "estudiantes", primary_key: "usuario_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionescuelaperiodos", "reportepagos", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionescuelaperiodos", "tipo_estado_inscripciones", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones", "escuelas", column: "pci_escuela_id", name: "inscripcionsecciones_ibfk_1", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones", "estudiantes", primary_key: "usuario_id", name: "inscripcionsecciones_ibfk_4", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones", "inscripcionescuelaperiodos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones", "secciones", name: "inscripcionsecciones_ibfk_6", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones", "tipo_calificaciones", name: "inscripcionsecciones_ibfk_2", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones", "tipo_estado_calificaciones", name: "inscripcionsecciones_ibfk_5", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones", "tipo_estado_inscripciones", name: "inscripcionsecciones_ibfk_7", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones", "tipoasignaturas", name: "inscripcionsecciones_ibfk_3", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy", "estudiantes", primary_key: "usuario_id", name: "inscripcionsecciones_copy_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones_copy", "secciones", name: "inscripcionsecciones_copy_ibfk_4", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones_copy", "tipo_estado_calificaciones", name: "inscripcionsecciones_copy_ibfk_3", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy", "tipo_estado_inscripciones", name: "inscripcionsecciones_copy_ibfk_5", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy", "tipoasignaturas", name: "inscripcionsecciones_copy_ibfk_1", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy1", "escuelas", column: "pci_escuela_id", name: "inscripcionsecciones_copy1_ibfk_1", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy1", "estudiantes", primary_key: "usuario_id", name: "inscripcionsecciones_copy1_ibfk_4", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones_copy1", "secciones", name: "inscripcionsecciones_copy1_ibfk_6", on_update: :cascade, on_delete: :cascade
  add_foreign_key "inscripcionsecciones_copy1", "tipo_calificaciones", name: "inscripcionsecciones_copy1_ibfk_2", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy1", "tipo_estado_calificaciones", name: "inscripcionsecciones_copy1_ibfk_5", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy1", "tipo_estado_inscripciones", name: "inscripcionsecciones_copy1_ibfk_7", on_update: :cascade, on_delete: :nullify
  add_foreign_key "inscripcionsecciones_copy1", "tipoasignaturas", name: "inscripcionsecciones_copy1_ibfk_3", on_update: :cascade, on_delete: :nullify
  add_foreign_key "perfiles_restringidas", "perfiles", name: "perfiles_restringidas_perfile_id_fk", on_update: :cascade, on_delete: :cascade
  add_foreign_key "perfiles_restringidas", "restringidas", name: "perfiles_restringidas_restringida_id_fk", on_update: :cascade, on_delete: :cascade
  add_foreign_key "planes", "escuelas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "profesores", "departamentos", name: "profesores_ibfk_1", on_update: :cascade, on_delete: :nullify
  add_foreign_key "profesores", "usuarios", primary_key: "ci", name: "profesores_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "programaciones", "asignaturas", on_update: :cascade, on_delete: :cascade
  add_foreign_key "programaciones", "periodos", on_update: :cascade, on_delete: :cascade
  add_foreign_key "reportepagos", "bancos", column: "banco_origen_id", on_update: :cascade, on_delete: :cascade
  add_foreign_key "seccion_profesores_secundarios", "profesores", primary_key: "usuario_id", name: "seccion_profesores_secundarios_ibfk_1", on_update: :cascade, on_delete: :cascade
  add_foreign_key "seccion_profesores_secundarios", "secciones", name: "seccion_profesores_secundarios_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "secciones", "asignaturas", name: "secciones_ibfk_2", on_update: :cascade, on_delete: :cascade
  add_foreign_key "secciones", "periodos", name: "secciones_ibfk_3", on_update: :cascade, on_delete: :cascade
  add_foreign_key "secciones", "profesores", primary_key: "usuario_id", name: "secciones_ibfk_4", on_update: :cascade, on_delete: :cascade
  add_foreign_key "secciones", "tipo_secciones", name: "secciones_ibfk_1", on_update: :cascade, on_delete: :cascade
end
