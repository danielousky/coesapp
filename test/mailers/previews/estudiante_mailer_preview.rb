class EstudianteMailerPreview < ActionMailer::Preview
  def bienvenido
    EstudianteMailer.bienvenida(Grado.last)
  end

  def asignados_opsu_2020
    EstudianteMailer.asignados_opsu_2020(Grado.last)
  end

  def preinscrito
    EstudianteMailer.preinscrito(Usuario.where(ci: 25872065).first, Inscripcionescuelaperiodo.last)
  end

end