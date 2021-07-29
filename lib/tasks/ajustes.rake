
desc "Envio de correos a estudiantes Asignados 2020 por Opsu"
task :send_email_asignados => :environment do
	Grado.asignado.where("created_at > ?", Date.today).each do |grado|
		if grado.enviar_correo_asignados_opsu_2020('15573230', '0.0.0.0')
			p "  <#{grado.descripcion}> ".center(200, "#")
		else
			p "  <NO AGREGADO: #{grado.error.full_messages.to_sentence}> ".center(200, "#")
		end
	end
end


desc "Envio de correos a estudiantes Asignados 2020-02S y 2020-02A"
task :send_email_asignados => :environment do
	Grado.asignado.each do |grado|
		if grado.enviar_correo_bienvenida('15573230', '0.0.0.0')
			p "  <#{grado.descripcion}> ".center(200, "#")
		else
			p "  <NO AGREGADO: #{grado.error.full_messages.to_sentence}> ".center(200, "#")
		end
	end
end



desc "Actualización de inscripciones_secciones a nil en caso errado de 2021-01S"
task :update_inscripcionsecciones_no_202101S => :environment do
	begin
			
		total_actualizaciones = 0
		arrs = Inscripcionseccion.joins(:seccion).group('inscripcionescuelaperiodo_id').having('count(*) > 4').order("count(*) DESC").count

		arrs.each do |arr|
			if !arr[0].nil?
				insper = Inscripcionescuelaperiodo.find arr[0] 
				inscripciones = insper.inscripcionsecciones.joins(:seccion).where("secciones.periodo_id != ?", '2021-01S')
				total_actualizaciones += inscripciones.update_all(inscripcionescuelaperiodo_id: nil)
			end
		end
		p total_actualizaciones
	

	rescue Exception => e
		p "Error General: #{e}"
	end
	total_actualizaciones
end


desc 'Agrega cita horaria 2019-02A'
task :add_cita_horaria_201902a => :environment do

	begin
		print 'Iniciando'
		Citahoraria.create(fecha: DateTime.new(2019,12,10,8,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,9,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,9,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,10,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,10,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,11,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,13,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,13,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,14,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,14,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,15,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,10,15,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,11,8,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,11,9,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,11,9,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,11,10,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,11,10,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,11,11,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,12,8,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,12,9,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,12,9,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,12,10,0))
		Citahoraria.create(fecha: DateTime.new(2019,12,12,10,30))
		Citahoraria.create(fecha: DateTime.new(2019,12,12,11,0))

	rescue Exception => e
		print e
	end
end


desc 'Actualizacion de grados, se asocia al plan del estudiante-escuela'
task :update_grado_to_last_plain => :environment do

	begin
		print 'Iniciando'
		total_grados = Grado.sin_plan.count
		total_cambiados = 0
		Grado.sin_plan.each do |g|
			print '.  '
			if aux = g.estudiante.ultimo_plan_de_escuela(g.escuela_id)
				print 'x'
				g.plan_id = aux.id
				if g.save
					total_cambiados += 1
				end
			end
		end
		p "       Total Grados: #{total_grados}      ".center(200, '#')
		p "    Total Cambiados: #{total_cambiados}   ".center(200, '#')		
	rescue Exception => e
		print e
	end
end


desc 'Actualizacion para asignar a Inscripcionseccion una grado'

task :actualizar_estado_grado_a_posible_graduando => :environment do
	Inscripcionseccion.proyectos.aprobado.each do |ins|
		if Grado.where(escuela_id: ins.escuela_id, estudiante_id: ins.estudiante_id).update_all(estado: 4, culminacion_periodo_id: ins.periodo.id)
			print '.'
		else
			print 'x'
		end
	end

end

desc 'Actualizacion asociacion escuela con inscripciones y pci'

task :asociar_inscripcionseccion_a_grado => :environment do

	p 'Iniciando actualizacion de asociacion entre inscripciones y grado...'
	# count = 0
	# nuevos = 0



	begin
		Inscripcionseccion.where("pci_escuela_id IS NOT NULL").update_all("pci = TRUE, escuela_id =  pci_escuela_id")
		Inscripcionseccion.joins(:escuela).where("pci_escuela_id IS NULL").update_all("inscripcionsecciones.escuela_id =  escuelas.id")
		# Inscripcionseccion.all.each do |ins|
		# 	escuela_id = ins.pci_escuela_id ? ins.pci_escuela_id : ins.escuela.id

		# 	#ee = Grado.where(escuela_id: escuela_id, estudiante_id: estudiante_id).first
		# 	grado = ins.estudiante.grados.where(escuela_id: escuela_id).first
		# 	nuevos +=1 if grado.nil? and grado = Grado.create(escuela_id: escuela_id, estudiante_id: ins.estudiante_id)

		# 	ins.grado_id = grado.id
		# 	p ins
		# 	p grado
		# 	if ins.save!
		# 		count +=1 
		# 		p '.'
		# 	else
		# 		p '-'
		# 		break
		# 	end
		# end
	rescue Exception => e
		p e
	end
	p 'Finalizado'
end


desc "Actualizacion de inscripciones_secciones a la estructura nueva"
task :ajuste_inscripcionsecciones => :environment do
	puts 'Iniciando Ajuste a Inscripciones Secciones con valores en TipoEstadoCalificacion...'
	begin
		puts 'Iniciando...'

		inscrip = Inscripcionseccion.joins(:escuela).where("tipo_estado_calificacion_id IS NOT NULL and escuela_id = 'IDIO'")
		total_ins = inscrip.count

		total_pi = 0
		total_a = 0
		total_ap = 0
		total_ret = 0

		p "=".center(180, "=")
		p "=".center(180, "=")
		p "   INICIO:   ".center(180, "=")
		p "     TOTAL_INS: #{total_ins}.    ".center(180, "=")
		p "     TOTAL_PI: #{total_pi}.    ".center(180, "=")
		p "     TOTAL_A: #{total_a}.    ".center(180, "=")
		p "     TOTAL_AP: #{total_ap}.    ".center(180, "=")
		p "     TOTAL_RET: #{total_ret}.    ".center(180, "=")
		p "=".center(180, "=")
		p "=".center(180, "=")

		inscrip.each do |ins|
			# p ins 
			if ins.tipo_estado_calificacion_id.eql? 'PI' and ins.calificacion_final == 0
		 		print "-PI-"
				ins.tipo_estado_calificacion_id = nil
			 	ins.tipo_calificacion_id = 'PI'
		 		ins.estado = :aplazado
		 		total_pi += 1
				print '.' if ins.save
			elsif ins.tipo_estado_calificacion_id.eql? 'A' and ins.estado.eql? 'sin_calificar'
		 		print "-A-"
				ins.tipo_estado_calificacion_id = nil
				ins.tipo_calificacion_id = 'NF'
				ins.estado = :aprobado
				total_a += 1
				print '.' if ins.save
			elsif ins.tipo_estado_calificacion_id.eql? 'AP' and ins.estado.eql? 'sin_calificar'
		 		print "-AP-"
				ins.tipo_estado_calificacion_id = nil
				ins.tipo_calificacion_id = 'NF'
				ins.estado = :aplazado
				total_ap += 1
				print '.' if ins.save
			elsif ins.tipo_estado_inscripcion_id.eql? 'RET' and ins.tipo_calificacion_id.nil? and ins.estado.eql? 'sin_calificar'
		 		print "-RET-"
				ins.tipo_estado_calificacion_id = nil
				ins.tipo_calificacion_id = 'NF'
				ins.estado = :retirado
				total_ret += 1
				print '.' if ins.save
			else
				print "x"
			end


		end
		p ' Vamos con la secciones '.center(180, "=")
		secciones = inscrip.group(:seccion_id).count
		p "inicio de secciones"
		secciones.each_pair do |k,v|
			s = Seccion.find k
			s.abierta = false
			print "s" if s.save
		end
		p "fin de secciones"


		p "=".center(180, "=")
		p "=".center(180, "=")
		p "   RESULTADOS:   ".center(180, "=")
		p "     TOTAL_INS: #{total_ins}.    ".center(180, "=")
		p "     TOTAL_PI: #{total_pi}.    ".center(180, "=")
		p "     TOTAL_A: #{total_a}.    ".center(180, "=")
		p "     TOTAL_AP: #{total_ap}.    ".center(180, "=")
		p "     TOTAL_RET: #{total_ret}.    ".center(180, "=")
		p "=".center(180, "=")
		p "=".center(180, "=")

	rescue Exception => e
		p = "Error: #{e.message}"
	end
end


desc "Genera las programaciones de todos los periodos si las asignaturas tiene al menos una seccion"
task :generar_programaciones => :environment do
	p 'Iniciando generación de programaciones...'
	begin
		p 'Iniciando...'
		total = 0
		Periodo.all.each do |pe|
			pe.escuelas.each do |e|
				e.asignaturas.each do |a|
					if a.secciones.where(periodo_id: pe.id).count > 0
						if a.programaciones.create(periodo_id: pe.id)
							total += 1
							p '.'
						end
					end
				end
			end
		end

		puts "Total de programaciones creadas: #{total}."
	rescue Exception => e
		puts = "Error: #{e.message}"
	end
end

desc "Genera las programaciones del periodo 2019-01S de las asignaturas activas"
task :generar_programaciones_201901S => :environment do
	puts 'Iniciando generación de programaciones...'
	begin
		creadas = 0
		existentes = 0
		pe = Periodo.last

		pe.asignaturas.where("activa IS TRUE").each do |a| 
			if a.programaciones.find_by(periodo_id: pe.id)
				existentes += 1
				p 'x'
			elsif a.programaciones.create(periodo_id: pe.id)
				creadas = 0
				p '.' 
			end

		end


		puts "Total de programaciones creadas: #{creadas}. Existente: #{existentes}"
	rescue Exception => e
		puts = "Error: #{e.message}"
	end
end

desc 'Migrar Estudiantes a EscuelaEstudiante'
task estudiantes_a_escuela_estudiantes: :environment do
	p 'Iniciando migracion de Estudiante a EscuelaEstudiante'

	Estudiante.all.each do |es|
		if es.escuela_id
			print '.' if es.grados.create!(escuela_id: es.escuela_id)
		end
	end

	p "Total de nuevos EscuelaEstudiantes Creados: #{Escuelaestudiante.count}"

end

