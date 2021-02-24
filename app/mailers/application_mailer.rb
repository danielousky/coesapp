class ApplicationMailer < ActionMailer::Base
  default from: "COES-FHE <controlestfheucv@gmail.com>"
  layout 'mailer'

  def olvido_clave(usuario)
    @nombre = usuario.nombre_completo
    @clave = usuario.password
    mail(:to => usuario.email, :subject => "COES-FHE - Recordatorio de clave")
  end  
end
