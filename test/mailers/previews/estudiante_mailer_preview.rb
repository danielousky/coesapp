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
  
  def confirmado
    EstudianteMailer.preinscrito(Usuario.where(ci: 25872065).first, Inscripcionescuelaperiodo.last)
  end

  def cita_horaria
    EstudianteMailer.cita_horaria(Grado.con_cita_horarias.last, '2023-01S')
  end

end