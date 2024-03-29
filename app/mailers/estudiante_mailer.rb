class EstudianteMailer < ActionMailer::Base
    
  default from: "COES-FHE <controlestfheucv@gmail.com>"#, authentication: 'plain'
  layout 'mailer'

  def prueba
    mail(to: 'danielmoros@mailinator.com', subject: "Correo de Prueba de COESFHE")
  end

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

  def cita_horaria(grado, periodo_id)
    @nombre = grado.estudiante.usuario.primer_nombre_apellido
    @genero = grado.estudiante.usuario.genero
    @periodo_id = periodo_id
    @cita_horaria = I18n.l(grado.citahoraria, format: "%d/%m/%Y") if grado.citahoraria
    @escuela_nombre = grado.escuela.descripcion.upcase
    @desde = I18n.l(grado.citahoraria, format: '%I:%M %P') if grado.citahoraria
    @hasta = I18n.l(grado.citahoraria+grado.duracion_franja_horaria.minutes, format: '%I:%M %P') if grado.citahoraria
    mail(to: grado.estudiante.usuario.email, subject: "¡Cita horaria para el procesos de inscripción #{periodo_id} en COES-FHE!")
  end  
  # No se están enviando los email por este método.
  # Hay que personalizar el método, Custom Jobs https://github.com/collectiveidea/delayed_job#custom-jobs
  # Esto para serealizar los valores ya que no es compatible con el método por defecto.

  # handle_asynchronously :bienvenida

  def asignados_opsu_2020(grado)
    @grado = grado
    mail(to: grado.estudiante.usuario.email, subject: "PREINSCRIPCIONES ASIGNADOS #{@grado.iniciado_periodo_id}")
  end


  # handle_asynchronously :asignados_opsu_2020
end
