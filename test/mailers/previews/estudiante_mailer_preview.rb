<<<<<<< HEAD
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

=======
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

>>>>>>> 7050be81cac4498c00dca402ed6e2dcdaed2406e
end