class EstudianteMailer < ActionMailer::Base
    
  default from: "COES-FHE <controlestfheucv@gmail.com>"#, authentication: 'plain'
  layout 'mailer'
  def ratificacionEIM201902A(estudiante)
    @nombre = estudiante.usuario.nombres
    @genero = estudiante.usuario.genero
    usuario = estudiante.usuario
    @confirmadas = estudiante.inscripciones.del_periodo('2019-02A').en_curso if estudiante
    mail(to: usuario.email, subject: "Confirmación Proceso de Inscripción Idiomas Modernos 2019-02A")
  end

  def preinscrito(usuario, inscripcionperiodo)
    @asignaturas = inscripcionperiodo.inscripcionsecciones.map { |ins| ins.asignatura}
    @escuela = inscripcionperiodo.escuela
    @escuela_desc = inscripcionperiodo.escuela.descripcion
    @periodo_id = inscripcionperiodo.periodo.id
    @nombre = usuario.primer_nombre_apellido
    @genero = usuario.genero
    mail(to: usuario.email, subject: "¡Preinscripción Exitosa en #{@escuela_desc} para el Período #{@periodo_id} COES-FHE! ")    
  end

  def confirmado(estudiante, inscripcionescuelaperiodo)
    usuario = estudiante.usuario
    escuela = inscripcionescuelaperiodo.escuela
    inscripcionsecciones = inscripcionescuelaperiodo.inscripcionsecciones
    @secciones = inscripcionsecciones.map { |ins| ins.seccion}

    @escuela_desc = escuela.descripcion
    @periodo_id = inscripcionescuelaperiodo.periodo.id
    @nombre = usuario.primer_nombre_apellido
    @genero = usuario.genero
    mail(to: usuario.email, subject: "¡Confirmación de Asignaturas en #{@escuela_desc} para el Período #{@periodo_id} COES-FHE!")
  end

  def bienvenida(grado)
    @nombre = grado.estudiante.usuario.primer_nombre_apellido
    @genero = grado.estudiante.usuario.genero
    @escuela = grado.escuela
    @asignado = grado.asignado?
    mail(to: grado.estudiante.usuario.email, subject: "¡Bienvenidos a COES-FHE!")
  end
  # No se están enviando los email por este método.
  # Falta revisar por qué
  # handle_asynchronously :bienvenida

  def asignados_opsu_2020(grado)
    @grado = grado
    mail(to: grado.estudiante.usuario.email, subject: "PREINSCRIPCIONES ASIGNADOS #{@grado.iniciado_periodo_id}")
  end


  # handle_asynchronously :asignados_opsu_2020
end
