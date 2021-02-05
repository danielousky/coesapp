
class EstudianteMailer < ActionMailer::Base

  # default :from => "fundeim@ucv.ve"      
  default from: "COES-FHE <fundeimucv@gmail.com>"#, authentication: 'plain'

  def ratificacionEIM201902A(estudiante)
    @nombre = estudiante.usuario.nombres
    @genero = estudiante.usuario.genero
    usuario = estudiante.usuario
    @ratifiacadas = estudiante.inscripciones.del_periodo('2019-02A').ratificados if estudiante
    mail(to: usuario.email, subject: "Ratificación Proceso de Inscripción Idiomas Modernos 2019-02A")
  end

  def bienvenida(usuario)
    @nombre = usuario.nombre_completo     
    @clave = usuario.contrasena
    attachments['folleto_inscripcion_C_2011.pdf'] = File.read("#{Rails.root}/attachments/folleto_inscripcion_C_2011.pdf")
    mail(:to => usuario.correo, :subject => "FUNDEIM Bienvenida - Proceso de Inscripción de los Cursos de Idiomas Modernos")
  end


  def recordatorio(usuario)
    @nombre = usuario.nombre_completo     
    @clave = usuario.contrasena   
    attachments['folleto_inscripcion_A_2012.pdf'] = File.read("#{Rails.root}/attachments/folleto_inscripcion_A_2012.pdf")
    mail(:to => usuario.correo, :subject => "Inscripción de los Cursos de Idiomas Modernos")
  end

  def cambio_aulas_faces(usuario,seccion)
    @nombre = usuario.nombre_completo
    @seccion = seccion
    attachments['cambio_salones_sabado.pdf'] = File.read("#{Rails.root}/attachments/cambio_salones_sabado.pdf")
    mail(:to => usuario.correo, :subject => "FUNDEIM - Cambio de aula de la sección: #{seccion.descripcion}")
  end

  def olvido_clave(usuario)
    @nombre = usuario.nombre_completo
    @clave = usuario.password
    mail(:to => usuario.email, :subject => "COES-FHE - Recordatorio de clave")
  end

  def nivelacion(usuario, historial)
    @nombre = usuario.nombre_completo
    @clave = usuario.contrasena
    @id=historial.tipo_curso.descripcion
    @ni=historial.tipo_nivel.descripcion
    @ho=historial.seccion.horario
    @se=historial.seccion_numero
    @au=historial.seccion.aula
    mail(:to => usuario.correo, :subject => "FUNDEIM - Inscrito por nivelación", :bcc => 'fundeimucv@gmail.com, aceim.development@gmail.com')
  end

end
