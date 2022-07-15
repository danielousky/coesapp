
class ExportarExcel
	include Prawn::View

	def self.to_utf16(valor)
		require 'iconv'
		# Iconv.iconv('ISO-8859-15', 'UTF-8', valor).to_s

		ic_ignore = Iconv.new('ISO-8859-15', 'UTF-8')
		return ic_ignore.iconv(valor).to_s
	end

	def self.listado_estudiantes periodo_id, estado='completo', escuela_id=nil, plan_id=nil, ingreso=nil

		require 'spreadsheet'

		@book = Spreadsheet::Workbook.new
		@sheet = @book.create_worksheet :name => "estudiantes_#{estado}_#{periodo_id}"

		@sheet.row(0).concat ['#', 'ESCUELA', 'PLAN', 'INGRESO','CEDULA', 'ESTADO INSCRIP', 'REGION', 'APELLIDOS', 'NOMBRES', 'NAC.', 'EDO. CIVIL', 'GÉNERO', 'TLF. FIJO', 'TLF. MÓVIL', 'CORREO-E', 'NAC. AÑO', 'NAC. MES', 'NAC. DÍA', 'ESTADO', 'MUNICIPIO', 'CIUDAD', 'URBANIZACIÓN/SECTOR', 'CALLE/AVENIDA', 'TIPO VIVIENDA']

		grados = Grado.iniciados_en_periodo(periodo_id)#.limit(50)
		estado = estado.singularize
		if estado != 'completo'
			unless estado.eql? 'nuevo'
				if estado.eql? 'ucv'
					grados = grados.inscritos_ucv
				elsif estado.eql? 'nuevossinsec'
					grados = grados.no_inscritos_ucv.con_inscripciones#reject{|g| !g.inscripciones.any?}
				else
					indice = Grado.estado_inscripciones[estado]
					grados = grados.where(estado_inscripcion: indice)
				end
			end
			grados = grados.where(escuela_id: escuela_id) if escuela_id
			grados = grados.joins(:plan).where("planes.id = '#{plan_id}'") if plan_id

			unless ingreso.blank?
				indice = Grado.tipos_ingreso[ingreso]
				grados = grados.where(tipo_ingreso: indice)
			end

			if estado.eql? 'nuevo'
				grados = grados.reject{|g| !g.inscripciones.any?}
			end

		end 

		grados.each_with_index do |grado,i|

			estudiante = grado.estudiante
			usuario = estudiante.usuario
			obj = []

			obj.push i+1
			obj.push grado.escuela.descripcion
			obj.push grado.plan_descripcion_corta
			obj.push grado.tipo_ingreso
			obj.push grado.estudiante_id
			obj.push grado.estado_inscripcion
			obj.push grado.region
			obj.push usuario.apellidos
			obj.push usuario.nombres
			obj.push usuario.nacionalidad ? usuario.nacionalidad[0..2] : ''
			obj.push usuario.estado_civil
			obj.push usuario.sexo
			obj.push usuario.telefono_habitacion
			obj.push usuario.telefono_movil
			obj.push usuario.email
			obj.push usuario.fecha_nacimiento ? usuario.fecha_nacimiento.year : ''
			obj.push usuario.fecha_nacimiento ? usuario.fecha_nacimiento.month : ''
			obj.push usuario.fecha_nacimiento ? usuario.fecha_nacimiento.day : ''
			obj.push estudiante.direccion ? estudiante.direccion.estado : ''
			obj.push estudiante.direccion ? estudiante.direccion.municipio : ''
			obj.push estudiante.direccion ? estudiante.direccion.ciudad : ''
			obj.push estudiante.direccion ? estudiante.direccion.sector : ''
			obj.push estudiante.direccion ? estudiante.direccion.calle : ''
			obj.push estudiante.direccion ? estudiante.direccion.nombre_vivienda : ''

			@sheet.row(i+1).concat obj
		end
		file_name = "listado_estudiantes.xls"
		return file_name if @book.write file_name
		
	end

	def self.registro_inscripciones grado_id
		require 'csv'
		
		grado = Grado.find(grado_id)

		csv_data =CSV.generate(headers: true, col_sep: ";") do |csv|

			csv << %w(CEDULA ASIGNATURA DENOMINACION CREDITO NOTA_FINAL NOTA_DEFI TIPO_EXAM PER_LECTI ANO_LECTI SECCION PLAN1)
			insertar_inscripciones csv, grado.inscripciones
		end

		return csv_data
	end


	def self.estudiantes_csv plan_id, periodo_id, seccion_id = nil, estado = false, escuelas_ids = false
		require 'csv'

		csv_data =CSV.generate(headers: true, col_sep: ";") do |csv|

			csv << %w(CEDULA ASIGNATURA DENOMINACION CREDITO NOTA_FINAL NOTA_DEFI TIPO_EXAM PER_LECTI ANO_LECTI SECCION PLAN1)


			if periodo_id and !estado
				plan = Plan.find plan_id
				plan.estudiantes.each do |es|
					insertar_inscripciones csv, (es.inscripcionsecciones.del_periodo periodo_id), plan
				end
			elsif seccion_id
				seccion = Seccion.find seccion_id
				insertar_inscripciones csv, seccion.inscripciones.aprobado
			else
				estado = estado.to_i

				if estado.eql? 1
					registros = Inscripcionseccion.proyectos.del_periodo(periodo_id).de_las_escuelas(escuelas_ids).sin_calificar

					registros.each do |ins|
						plan = ins.grado.ultimo_plan
						insertar_inscripciones csv, ins.estudiante.inscripciones, plan
					end					
				else
					registros = Grado.culminado_en_periodo(periodo_id).de_las_escuelas(escuelas_ids).where(estado: estado)
					registros.each do |g|
						plan = g.ultimo_plan
						insertar_inscripciones csv, g.estudiante.inscripciones, plan
					end
				end
				# 	grados = grados.tesista
				# elsif grado.eql? 2
				# 	grados = grados.posible_graduando
				# elsif grado.eql? 3
				# 	grados = grados.graduando
				# else
				# 	grados = grados.graduado
				# end


				csv << ["TOTAL #{Grado.estados.keys[estado]}", registros.count]

			end
		end
		return csv_data
	end


	def self.inscritos_escuela_periodo periodo_id, escuela_id

		require 'spreadsheet'

		@book = Spreadsheet::Workbook.new
		@sheet = @book.create_worksheet :name => "inscritos_#{periodo_id}_#{escuela_id}"

		@sheet.row(0).concat ['	CEDULA', 'NOMBRES', 'APELLIDOS', 'T. CREDITOS', 'CORREO', 'MOVIL', 'LOCAL']

		escuela = Escuela.find escuela_id

		estudiantes = escuela.inscripcionsecciones.del_periodo(periodo_id).estudiantes_inscritos_con_creditos

		estudiantes.each_with_index do |es,i|
			u = Usuario.find es.first
			creditos =  es.last

			@sheet.row(i+1).concat [u.ci, u.nombres, u.apellidos, creditos, u.email, u.telefono_movil, u.telefono_habitacion]
		end


		file_name = "reporte_escuela_periodo.xls"
		return file_name if @book.write file_name
		
	end

	def self.hacer_acta_excel(seccion_id)
		require 'spreadsheet'

		@seccion = Seccion.find seccion_id
		@book = Spreadsheet::Workbook.new
		@sheet = @book.create_worksheet :name => "Reporte #{seccion_id}"

		@sheet.column(0).width = 12
		# @sheet.column(1).width = 40
		@sheet.column(2).width = 40
		# @sheet.column(3).width = 15

		data = ['Facultad', 'HUMANIDADES Y EDUCACIÓN']
		@sheet.row(0).concat data
		data = ['Escuela', @seccion.escuela.descripcion.upcase]
		@sheet.row(1).concat data
		# data = ['Plan']
		# @sheet.row(2).concat data
		data = ['Materia', @seccion.asignatura.descripcion]
		@sheet.row(2).concat data
		data = ['Código', @seccion.asignatura.id_uxxi]
		@sheet.row(3).concat data
		data = ['Créditos', @seccion.asignatura.creditos]
		@sheet.row(4).concat data
		data = ['Sección', @seccion.numero]
		@sheet.row(5).concat data
		data = ['Profesor', "#{@seccion.profesor.usuario.nombre_completo if @seccion.profesor}"]
		@sheet.row(6).concat data
		@sheet.row(7).concat ['CI. Profesor', @seccion.profesor_id]
		@sheet.row(8).concat ['Periodo', @seccion.periodo.periodo_del_anno]
		@sheet.row(9).concat ['Año', @seccion.periodo.anno]

		data = ['No.', 'Cédula I', 'Nombres y Apellidos', 'Nota_Def', 'Tipo_Ex.']
		@sheet.row(12).concat data

		@seccion.inscripcionsecciones.sort_by{|h| h.estudiante.usuario.apellidos}.each_with_index do |es,i|
			e = es.estudiante
			@sheet.row(i+13).concat [i+1, e.usuario_id, es.nombre_estudiante_con_retiro, es.colocar_nota, es.tipo_convocatoria]
		end

		file_name = "reporte_secciones.xls"
		return file_name if @book.write file_name
	end

	def self.listado_seccion_excel(seccion_id)
		require 'spreadsheet'

		seccion = Seccion.find seccion_id

		@book = Spreadsheet::Workbook.new
		@sheet = @book.create_worksheet :name => "Seccion #{seccion.id}"

		if seccion.periodo_id.eql? '2016-02A'
			inscripcionsecciones = seccion.inscripcionsecciones.no_retirados.confirmados.sort_by{|i_s| i_s.estudiante.usuario.apellidos}
		else
			inscripcionsecciones = seccion.inscripcionsecciones.no_retirados.sort_by{|i_s| i_s.estudiante.usuario.apellidos}
		end

		@sheet.column(0).width = 15 #estudiantes.collect{|e| e.cal_usuario_ci.length if e.cal_usuario_ci}.max+2;
		@sheet.column(1).width = 50	#estudiantes.collect{|e| e.cal_usuario.apellido_nombre.length if e.cal_usuario.apellido_nombre}.max+2;
		@sheet.column(2).width = 15 #estudiantes.collect{|e| e.cal_usuario.correo_electronico.length if e.cal_usuario.correo_electronico}.max+2;
		@sheet.column(3).width = 40
		@sheet.column(4).width = 20

		@sheet.row(0).concat ["Profesor: #{seccion.descripcion_profesor_asignado}"]
		@sheet.row(1).concat ["Sección: #{seccion.descripcion}"]
		@sheet.row(2).concat %w{CI NOMBRES ESTADO CORREO MOVIL}

		data = []
		inscripcionsecciones.each_with_index do |i_s,i|
			usuario = i_s.estudiante.usuario
			@sheet.row(i+3).concat i_s.datos_para_excel
		end

		file_name = "reporte_seccion.xls"
		return file_name if @book.write file_name
	end

	private

	def self.insertar_inscripciones csv, inscripciones, plan = nil
		inscripciones.each do |insc|
			insertar_inscripcion csv, insc, plan
		end
	end

	def self.insertar_inscripcion csv, inscripcion, plan = nil

		est = inscripcion.estudiante
		sec = inscripcion.seccion
		asig = sec.asignatura

		# ============ Mover a Inscripcionseccion =========== #
		nota_def = inscripcion.pi? ? 'PI' : inscripcion.colocar_nota_final
		nota_final = inscripcion.nota_final_para_csv
		nota_def = nota_final if nota_final.eql? 'SN' or asig.absoluta? or asig.forzar_absoluta
		# ============ Mover a Inscripcionseccion =========== #

		
		plan = inscripcion.ultimo_plan unless plan

		csv << [est.usuario_id, asig.id, asig.descripcion, asig.creditos, nota_final, nota_def, 'F', sec.periodo.getPeriodoLectivo, sec.periodo.anno, sec.numero, plan.id]

		if inscripcion.calificacion_posterior
			nota_final = nota_def = inscripcion.colocar_nota_posterior
			csv << [est.usuario_id, asig.id, asig.descripcion, asig.creditos, nota_final, nota_def, inscripcion.tipo_calificacion_id.to_s.last, sec.periodo.getPeriodoLectivo, sec.periodo.anno, sec.numero, plan.id]
		end
		
	end



end