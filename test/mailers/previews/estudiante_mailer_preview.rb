class EstudianteMailerPreview < ActionMailer::Preview
  def bienvenida
    EstudianteMailer.bienvenida(Grado.last)
  end
end