class EstudianteMailerPreview < ActionMailer::Preview
  def bienvenida
    EstudianteMailer.bienvenida(Grado.last)
  end
  def asignados_opsu_2020
    EstudianteMailer.asignados_opsu_2020(Grado.last)
  end
  
end