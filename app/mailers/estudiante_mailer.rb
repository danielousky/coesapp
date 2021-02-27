
class EstudianteMailer < ActionMailer::Base
    
  default from: "COES-FHE <controlestfheucv@gmail.com>"#, authentication: 'plain'
  layout 'mailer'
  def ratificacionEIM201902A(estudiante)
    @nombre = estudiante.usuario.nombres
    @genero = estudiante.usuario.genero
    usuario = estudiante.usuario
    @ratifiacadas = estudiante.inscripciones.del_periodo('2019-02A').ratificados if estudiante
    mail(to: usuario.email, subject: "Confirmación Proceso de Inscripción Idiomas Modernos 2019-02A")
  end

  def olvido_clave(usuario)
    @nombre = usuario.nombre_completo
    @clave = usuario.password
    mail(:to => usuario.email, :subject => "COES-FHE - Recordatorio de clave")
  end

  def bienvenida(usuario)
    @monto = "Bs. 1.500.000."
    

    @nombre = usuario.primer_nombre_apellido
    @genero = usuario.genero
    mail(to: usuario.email, subject: "¡Bienvenidos a COES-FHE!")
  end


end
