
class ExportarPdf
	include Prawn::View


	def self.listado_seccion seccion, profesor = false
  		asig = seccion.asignatura
		# Variable Locales
		pdf = Prawn::Document.new(top_margin: 20)

		#titulo
		encabezado_central_con_logo pdf, "Coordinación Académica"

		tabla_descripcion_seccion pdf, seccion

		pdf.move_down 10

		if profesor and seccion.profesores.ids.include? profesor.id 
			pdf.text "Profesor Secundario: #{profesor.descripcion_usuario}", size: 10
		else
			pdf.text "Profesor: #{seccion.descripcion_profesor_asignado}", size: 10
		end
	 
		pdf.move_down 10

		inscripciones = seccion.inscripcionsecciones.sort_by{|h| h.estudiante.usuario.apellidos}

		data = [["<b>#</b>", "<b>Cédula</b>", "<b>Nombre</b>"]]

		inscripciones.each_with_index do |h,i|
			data << [i+1, 
			h.estudiante_id,
			h.estudiante.usuario.apellido_nombre]
		end
		
		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :justify, padding: 3, border_color: '818284'}, :column_widths => {1 => 250})
		t.draw

		return pdf
	end


	def self.acta_seccion seccion_id
		# Variable Locales
		seccion = Seccion.find seccion_id
		escuela = seccion.escuela
		escuela = nil unless escuela.id.eql? 'POST'
		pdf = Prawn::Document.new(top_margin: 275, bottom_margin: 100)

		inscripciones = seccion.inscripcionsecciones.sort_by{|h| h.estudiante.usuario.apellidos}
		
		pdf.repeat(:all, dynamic: true) do
			pdf.bounding_box([0, 660], :width => 540, :height => 265) do
				self.encabezado_central_con_logo pdf, "PLANILLA DE EXÁMENES", escuela
				self.tabla_descripcion_convocatoria pdf, seccion
				self.tabla_descripcion_seccion pdf, seccion
 				pdf.transparent(0) { pdf.stroke_bounds }
			end
			pdf.bounding_box([0, -10], :width => 540, :height => 90) do
				self.acta_firmas pdf, seccion
 				pdf.transparent(0) { pdf.stroke_bounds }
			end
		end
		self.insertar_tabla_convocados pdf, inscripciones
		pdf.number_pages "PÁGINA: <b> <page> / <total> </b>", {at: [pdf.bounds.right - 230, 524], size: 9, inline_format: true}
		return pdf
	end


	def self.hacer_constancia_estudio bita_id, verificando = false
		# Variable Locales
		bita = Bitacora.find bita_id
		inscripcionperiodo = Inscripcionescuelaperiodo.find bita.id_objeto
		estudiante = inscripcionperiodo.estudiante
		usuario = estudiante.usuario
		escuela = inscripcionperiodo.escuela
		periodo_id = inscripcionperiodo.periodo.id
		inscripciones = inscripcionperiodo.inscripcionsecciones
		
		total = inscripciones.count 
		# pdf = Prawn::Document.new(top_margin: 20)

		pdf = Prawn::Document.new(top_margin: 20, bottom_margin: 10, background: "app/assets/images/bg_validacion.png")

		#titulo
		encabezado_central_con_logo pdf, "CONSTANCIA DE ESTUDIO", escuela, nil, estudiante

		pdf.move_down 5

		# pdf.start_page_numbering(50, 800, 500, nil, "<b><PAGENUM>/<TOTALPAGENUM></b>", 1)

		pdf.text "Quien suscribe, Jefe de Control de Estudios de la Facultad de HUMANIDADES Y EDUCACIÓN, de la Universidad Central de Venezuela, por medio de la presente hace constar que #{usuario.la_el} BR. <b>#{estudiante.usuario.apellido_nombre}</b>, titular de la Cédula de Identidad <b>#{estudiante.id}</b> es estudiante regular de la Escuela de <b>#{escuela.descripcion.titleize}</b> y está cursando en el periodo <b>#{periodo_id}</b> #{'la'.pluralize(total)} #{'siguiente'.pluralize(total)} #{'asignatura'.pluralize(total)}:", size: 10, inline_format: true, align: :justify

		pdf.move_down 20

		data = [["<b>Código</b>", "<b>Asignatura</b>", "<b>Sección</b>", "<b>Créditos</b>", "<b>Estado</b>"]]

		total_creditos = 0

		inscripciones.each do |inscripcion|
			seccion = inscripcion.seccion
			asignatura = seccion.asignatura
			total_creditos += asignatura.creditos
			data << [asignatura.id_uxxi,
				asignatura.descripcion_pci(seccion.periodo_id).upcase,
				seccion.numero,
				asignatura.creditos,
				inscripcion.estado_inscripcion]
		end
		
		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {1 => 160})
		t.draw

		pdf.move_down 20

		data = [["<b>Clave</b>", "<b>Créditos</b>", "<b>Estado</b>"]]

		data << ["<i>Número total de créditos matriculados:</i>", total_creditos, ""]

		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {1 => 160})
		t.draw

		pdf.move_down 20

		pdf.text "Constancia que se expide a solicitud de la parte interesada en la Ciudad Universitaria en Caracas, el día #{I18n.l(bita.created_at, format: "%d de %B de %Y")}.", size: 10
		pdf.move_down 30
		pdf.text "<b> --Válida para el período actual--</b>", size: 11, inline_format: true, align: :center
		pdf.move_down 40

		enlace = verificando ? nil : "https://coesfhe.com/verificar/#{bita.id}/documento"

		colocar_qr_y_firmas pdf, enlace 

		return pdf

	end



	def self.hacer_constancia_preinscripcion_facultad bita_id, verificando = false

		bita = Bitacora.find bita_id
		grado = Grado.find bita.id_objeto
		estudiante = grado.estudiante
		usuario = estudiante.usuario
		escuela = grado.escuela
		pdf = Prawn::Document.new(top_margin: 20, background: "app/assets/images/bg_validacion.png")

		encabezado_central_con_logo pdf, "CONSTANCIA DE PREINSCRIPCIÓN POR FACULTAD", escuela, nil, estudiante

		pdf.move_down 5


		pdf.text "Quien suscribe, Jefe de Control de Estudios de la Facultad de HUMANIDADES Y EDUCACIÓN, de la Universidad Central de Venezuela, por medio de la presente hace constar que #{usuario.la_el} BR. <b>#{usuario.apellido_nombre}</b>, titular de la Cédula de Identidad <b>#{usuario.id}</b> realizó su proceso de preinscripción en la facultad de Humanidades y Educación para ingresar en la escuela de <b>#{escuela.descripcion.upcase}</b>.", size: 10, inline_format: true, align: :justify

		pdf.move_down 20

		pdf.text "Constancia que se expide a solicitud de la parte interesada en la Ciudad Universitaria en Caracas, el día #{I18n.l(bita.created_at, format: "%d de %B de %Y")}.", size: 10

		pdf.move_down 80
		enlace = verificando ? nil : "https://coesfhe.com/verificar/#{bita.id}/documento"
		colocar_qr_y_firmas pdf, enlace
		return pdf
	end

	def self.hacer_constancia_inscripcion_sin_horario bita_id, verificando = false
		# Variable Locales
		
		bita = Bitacora.find bita_id
		inscripcionperiodo = bita.objeto
		estudiante = inscripcionperiodo.estudiante
		usuario = estudiante.usuario
		escuela = inscripcionperiodo.escuela
		periodo_id = inscripcionperiodo.periodo.id
		inscripciones = inscripcionperiodo.inscripcionsecciones

		if escuela.id.eql? 'POST'
    		pdf = Prawn::Document.new(top_margin: 20)
    	else
    		pdf = Prawn::Document.new(top_margin: 20, background: "app/assets/images/bg_validacion.png")
    	end


		#titulo
		encabezado_central_con_logo pdf, "CONSTANCIA DE INSCRIPCIÓN", escuela, nil, estudiante

		pdf.move_down 5

		if escuela.id.eql? 'POST'
			grado = Grado.where(escuela_id: escuela.id, estudiante_id: estudiante.id).first
			plan = grado.ultimo_plan
			plan = grado.ultimo_plan.descripcion if plan
			plan ||= 'Sin Plan de Estudio o Maestría Asociada' 


			pdf.text "Quien suscribe, Director(a) de la Comisión de Estudios de Postgrado de la Facultad de HUMANIDADES Y EDUCACIÓN, de la Universidad Central de Venezuela, por medio de la presente hace constar que #{usuario.la_el} ciudadan#{usuario.genero} <b>#{estudiante.usuario.apellido_nombre}</b>, titular de la Cédula de Identidad <b>#{estudiante.id}</b> está inscrit#{usuario.genero} el (la) <b>#{plan.upcase}</b> para el período lectivo <b>#{periodo_id}</b> con las siguientes asignaturas:", size: 10, inline_format: true, align: :justify
		else
			pdf.text "Quien suscribe, Jefe de Control de Estudios de la Facultad de HUMANIDADES Y EDUCACIÓN, de la Universidad Central de Venezuela, por medio de la presente hace constar que #{usuario.la_el} BR. <b>#{estudiante.usuario.apellido_nombre}</b>, titular de la Cédula de Identidad <b>#{estudiante.id}</b> está inscrit#{usuario.genero} en la Escuela de <b>#{escuela.descripcion.upcase}</b> para el período <b>#{periodo_id}</b> con las siguientes asignaturas:", size: 10, inline_format: true, align: :justify
		end

		pdf.move_down 20

		data = [["<b>Código</b>", "<b>Asignatura</b>", "<b>Sección</b>", "<b>Créditos</b>", "<b>Estado</b>"]]

		total_creditos = 0

		inscripciones.each do |inscripcion|
			seccion = inscripcion.seccion
			asignatura = seccion.asignatura
			total_creditos += asignatura.creditos
			data << [asignatura.id_uxxi,
				asignatura.descripcion_pci(seccion.periodo_id).upcase,
				seccion.numero,
				asignatura.creditos,
				inscripcion.estado_inscripcion]
		end
		

		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 400, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {1 => 160})
		t.draw
		
		pdf.move_down 20

		data = [["<b>Clave</b>", "<b>Créditos</b>", "<b>Estado</b>"]]

		data << ["<i>Número total de créditos matriculados:</i>", total_creditos, ""]

		u = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {1 => 160})
		
		u.draw
		# pdf.table([[t,u]], width: 540)
		pdf.move_down 20

		pdf.text "Constancia que se expide a solicitud de la parte interesada en la Ciudad Universitaria en Caracas, el día #{I18n.l(bita.created_at, format: "%d de %B de %Y")}.", size: 10
		pdf.move_down 30
		pdf.text "<b> --Válida para el período actual--</b>", size: 11, inline_format: true, align: :center
		pdf.move_down 50

		# enlace = verificando ? nil : "#{Rails.application.routes.default_url_options[:host]}/verificar/#{bita.id}/documento"
		enlace = verificando ? nil : "https://coesfhe.com/verificar/#{bita.id}/documento"


		if escuela.id.eql? 'POST'
			colocar_qr_y_firmas pdf, enlace, nil, true
		else
			colocar_qr_y_firmas pdf, enlace
		end

		return pdf
	end


	def self.hacer_constancia_inscripcion bita_id, verificando = false

		bita = Bitacora.find bita_id
		inscripcionperiodo = bita.objeto
		estudiante = inscripcionperiodo.estudiante
		usuario = estudiante.usuario
		escuela = inscripcionperiodo.escuela
		periodo_id = inscripcionperiodo.periodo.id
		inscripciones = inscripcionperiodo.inscripcionsecciones

		grado = Grado.find [estudiante.id,escuela.id]
		# pdf = Prawn::Document.new(top_margin: 20)
    	pdf = Prawn::Document.new(top_margin: 20, background: "app/assets/images/bg_validacion.png")

		contenido_inscripcion_horario pdf, estudiante, usuario, escuela, grado, inscripciones, periodo_id, bita, verificando
		
		pdf.start_new_page
		
		contenido_inscripcion_horario pdf, estudiante, usuario, escuela, grado, inscripciones, periodo_id, bita, verificando

		return pdf
	end

	def self.paintHorario secciones_ids, pdf
		bloques = Bloquehorario.where(horario_id: secciones_ids)
		
		v = pdf.make_table(printHorarioVacio(pdf), header: true, width: 200, cell_style: {inline_format: true, size: 9, overflow: :expand }, column_widths: {0 => 35}) do
			cells.border_width = 0.5
			cells.border_color = "faf7f7"
			# cells.overflow = "expand"
			cells.padding = 2
			cells.style(overflow: :visible)
			row(0).height = 20

			row(0).border_top_color = "000000"
			row(1).border_top_color = "000000"
			row(-1).border_bottom_color = "000000"
			row([5,9,13,17,21, 25, 29, 33, 37, 41, 45, 49]).border_top_color = "9c9b98"
			column([0,1]).border_left_color = "000000"
			column([2,3,4,5]).border_left_color = "9c9b98"
			column(-1).border_right_color = "000000"

			bloques.each do |bh|
				dia_index = Bloquehorario.dias[bh.dia]+1
				horaEntrada, minutoEntrada = bh.entrada_to_schedule.split(":")
				horaSalida, minutoSalida = bh.salida_to_schedule.split(":")
				
				inicio = (horaEntrada.to_i*4)+(minutoEntrada.to_i/15)+1
				final = (horaSalida.to_i*4)+(minutoSalida.to_i/15)

				rows(inicio..final).columns(dia_index).background_color = bh.horario.color_rgb_to_hex 2
				# rows([inicio,final]).columns(dia_index).border_width = 1

				rows(inicio..final).columns(dia_index).border_left_color = bh.horario.color_rgb_to_hex
				rows(inicio..final).columns(dia_index).border_left_width = 1.7
				rows(inicio..final).columns(dia_index).border_right_width = 1.7
				rows(inicio..final).columns(dia_index).border_right_color = bh.horario.color_rgb_to_hex
				rows(inicio).columns(dia_index).border_top_color = bh.horario.color_rgb_to_hex
				rows(inicio).columns(dia_index).border_top_width = 1.7
				rows(final).columns(dia_index).border_bottom_color = bh.horario.color_rgb_to_hex
				rows(final).columns(dia_index).border_bottom_width = 1.7
				# rows(inicio..final).columns(dia_index).content = "x"

				# columns(dia_index).rowspan = 3
				rows(final).columns(dia_index).size = 7
				rows(final).columns(dia_index).height = 10
				rows(final).columns(dia_index).rotate = 90
				tope = bh.horario.seccion.asignatura_id.length
				rows(final).columns(dia_index).content = "#{bh.horario.seccion.asignatura_id[tope-4..tope]}"

				# v.rows(inicio).columns(dia_index).borders = [:top]
				# v.rows(inicio).columns(dia_index).border_widths = [0,1,1,0]
			end
		end
		return v

	end

	def self.printHorarioVacio pdf

		data = %w(Lunes Martes Miércoles Jueves Viernes)
		data.unshift("")
		data.map!{|a| "<b>"+a[0..2]+"</b>"}
		data = [data]

		for i in 7..19 do
			aux = i < 12 ? "#{i} am" : "#{i - 12} pm"
			aux = "12 m" if i.eql? 12
			data << [{:content => "<b>#{aux}</b>", :rowspan => 4} ,"","","","",""] # En blanco
			data << [""]*5
			data << [""]*5
			data << [""]*5

		end
		data
	end

	def self.hacer_kardex id, alfabetico=false

		pdf = Prawn::Document.new(top_margin: 20)

		grado = Grado.find id
		estudiante = grado.estudiante #Estudiante.find id
		# periodos = estudiante.escuela.periodos.order("inicia DESC")
		escuela = grado.escuela #Escuela.find escuela_id

		inscripciones = grado.inscripciones#estudiante.inscripcionsecciones.joins(:escuela).where("escuelas.id = :e or pci_escuela_id = :e", e: escuela_id)

		periodo_ids = inscripciones.joins(:seccion).group("secciones.periodo_id").count.keys
		periodos = Periodo.where(id: periodo_ids)

		encabezado_central_con_logo pdf, "Historia Académica", escuela, nil, estudiante 
		#titulo
		pdf.text "<b>Fecha de Emisión:</b> #{I18n.l(Time.zone.now, format: '%a, %d / %B / %Y (%I:%M%p)')}", size: 9, inline_format: true
		pdf.text "<b>Cédula:</b> #{estudiante.usuario_id}", size: 9, inline_format: true
		# hplan = grado.ultimo_plan #estudiante.ultimo_plan_de_escuela(escuela_id)
		# hplan = grado.ultimo_plan ? grado.ultimo_plan.descripcion_completa : "--"
		pdf.text "<b>Plan:</b> #{grado.plan_descripcion}", size: 9, inline_format: true
		pdf.text "<b>Alumno:</b> #{estudiante.usuario.apellido_nombre.upcase}", size: 9, inline_format: true

		periodos.each do |periodo|
			pdf.move_down 15
			pdf.text "<b>Periodo:</b> #{periodo.id}", size: 10, inline_format: true
			pdf.move_down 5	

			# inscripciones_del_periodo = inscripcionsecciones.joins(:seccion).where("secciones.periodo_id": periodo.id).order("secciones.asignatura_id")
			if alfabetico
				inscripciones_del_periodo = inscripciones.joins(:seccion).where("secciones.periodo_id": periodo.id).sort {|a,b| a.descripcion(periodo.id) <=> b.descripcion(periodo.id)}
			else
				inscripciones_del_periodo = inscripciones.joins(:seccion).where("secciones.periodo_id": periodo.id).sort {|a,b| a.asignatura.id <=> b.asignatura.id}
			end
			# inscripciones_del_periodo = inscripcionsecciones.del_periodo periodo.id

			if inscripciones_del_periodo.count > 0
				data = [["<b>Código</b>", "<b>Asignatura</b>", "<b>Créditos</b>", "<b>Sección</b>", "<b>Convocatoria</b>", "<b>Calif. Num.</b>", "<b>Calif. alfa</b>"]]

				inscripciones_del_periodo.each do |h|

					sec = h.seccion
					asig = sec.asignatura
					nota = h.valor_calificacion(false, 'F')
					data << [asig.id_uxxi, h.descripcion_asignatura_pdf, asig.creditos, h.seccion.numero, h.tipo_convocatoria('F'), nota, h.tipo_calificacion_to_cod]

					if h.tiene_calificacion_posterior?
						nota = h.valor_calificacion(false, 'P')
						data << [asig.id_uxxi, h.descripcion(sec.periodo_id), asig.creditos, h.seccion.numero, h.tipo_convocatoria('R'), nota, h.tipo_calificacion_to_cod]
					end
				end

			end
			if data
				t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {1 => 160})
				t.columns(1..1).position = 'left'
				# t.columns(1..1).width = '100px'
				t.draw
			end

			t = Time.new
		end

		pdf.move_down 10

		resumen pdf, inscripciones
		# pdf.start_page_numbering(250, 15, 7, nil, to_utf16("#{t.day} / #{t.month} / #{t.year}       Página: <PAGENUM> de <TOTALPAGENUM>"), 1)

		pdf.move_down 20
		pdf.text "<b>NOTA:</b> CUANDO EXISTA DISCREPANCIA ENTRE LOS DATOS CONTENIDOS EN LAS ACTAS DE EXAMENES Y ÉSTE COMPROBANTE, LOS PRIMEROS SE TENDRÁN COMO AUTÉNTICOS PARA CUALQUIER FIN.", size: 11, inline_format: true, align: :justify
		pdf.move_down 10
		pdf.text "* ÉSTE COMPROBANTE ES DE CARACTER INFORMATIVO, NO TIENE VALIDEZ LEGAL *", font_size: 11, align: :center
		pdf.move_down 15
		pdf.text "________________", size: 11, align: :right
		pdf.move_down 5
		pdf.text "Firma Autorizada", size: 11, align: :right

		return pdf
	end


	private

	def self.colocar_qr_y_firmas pdf, enlace, tamano=120, post=false

		if enlace

			if post
				pdf.text "Profa.  María Eugenia Martínez", size: 11, align: :center
				pdf.text "Directora (E)", size: 11, align: :center
			else
				imagen_qr = generar_codigo_qr enlace
				pdf.image imagen_qr, width: 120, at: [10, (pdf.y)+40]
				pdf.text "Prof. Pedro Coronado", size: 11, align: :center
				pdf.text "Jefe(a) de Control de Estudio", size: 11, align: :center
				pdf.image "app/assets/images/sellos_firmas/firma_jefe_coes.png", width: 150, at: [190, (pdf.y)+60]
				pdf.image "app/assets/images/sellos_firmas/sello_coesfhe_azul.png", width: 120, at: [210, (pdf.y)-30]
				pdf.move_down 60
				pdf.text "<b>ATENCIÓN:</b> Para verificar la autenticidad del presente documento escanee el código QR, haga clic <a href='#{enlace}' target='_blank'>AQUÍ</a> ó escriba la siguiente dirección web en su navegador: #{enlace}." , align: :justify, size: 11, inline_format: true
			end

			
		else

			pdf.move_down 20
			pdf.text "Prof. Pedro Coronado", size: 11, align: :center
			pdf.text "Jef(a) de Control de Estudio", size: 11, align: :center
			pdf.image "app/assets/images/sellos_firmas/firma_jefe_coes.png", width: 150, at: [190, (pdf.y)+60]
			pdf.image "app/assets/images/sellos_firmas/sello_coesfhe_azul.png", width: 120, at: [210, pdf.y-30]
		end

		# El presente documento ha sido "firmado electrónicamente", cumpliendo con el Decreto Ley de mensaje de Datos y Firma Electrónica, de fecha 10 de Febrero de 2001, publicado en la *Gaceta Oficial** Nro 37.148, del 28 de febrero de 2001.
	end

	def self.generar_codigo_qr enlace

		require 'rqrcode'
		
		qrcode = RQRCode::QRCode.new(enlace)

		png = qrcode.as_png(
			bit_depth: 1,
			border_modules: 4,
			color_mode: ChunkyPNG::COLOR_GRAYSCALE,
			color: 'black',
			file: "tmp/barcode.png",
			fill: 'white',
			module_px_size: 6,
			resize_exactly_to: false,
			resize_gte_to: false,
			size: 200
		)

		return "#{Rails.root.to_s}/tmp/barcode.png"

	end


	def self.contenido_inscripcion_horario pdf, estudiante, usuario, escuela, grado, inscripciones, periodo_id, bita, verificando
		total = inscripciones.count

		#titulo
		encabezado_central_con_logo pdf, "CONSTANCIA DE INSCRIPCIÓN Y HORARIO", escuela, 9, estudiante

		pdf.move_down 5

		pdf.text "Quien suscribe, Jefe de Control de Estudios de la Facultad de HUMANIDADES Y EDUCACIÓN, de la Universidad Central de Venezuela, por medio de la presente hace constar que #{usuario.la_el} BR. <b>#{estudiante.usuario.apellido_nombre}</b>, titular de la Cédula de Identidad <b>#{estudiante.id}</b> está inscrit#{usuario.genero} en la Escuela de <b>#{escuela.descripcion.upcase}</b> para el período <b>#{periodo_id}</b> con #{'la'.pluralize(total)} #{'siguiente'.pluralize(total)} #{'asignatura'.pluralize(total)} y en el siguiente horario:", size: 10, inline_format: true, align: :justify

		# pdf.move_down 10

		data = [["", "<b>Código</b>", "<b>Asignatura</b>", "<b>Sec</b>", "<b>Créd</b>", "<b>Estado</b>"]]

		total_creditos = 0

		inscripciones.each do |inscripcion|
			seccion = inscripcion.seccion
			asignatura = seccion.asignatura
			total_creditos += asignatura.creditos
			data << ["", asignatura.id_uxxi,
				asignatura.descripcion_pci(seccion.periodo_id).upcase,
				seccion.numero,
				asignatura.creditos,
				inscripcion.estado_inscripcion]
		end

		data << [{:content => "<b>Número Total de Créditos Matriculados: </b>", :colspan => 4} ,total_creditos,""]

		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 300, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {0 => 5, 2 => 120})

		inscripciones.each_with_index do |inscripcion, i|
			t.rows(i+1).columns(0).background_color = inscripcion.seccion.horario.color_rgb_to_hex if inscripcion.seccion and inscripcion.seccion.horario
		end
		# t.row(0).width = 3
		# t.row(-1).width = 30

		secciones_ids = grado.secciones.where(periodo_id: periodo_id).ids 
		bloques = Bloquehorario.where(horario_id: secciones_ids)
		v = paintHorario secciones_ids, pdf

		pdf.move_down 10
		pdf.table([[t,v]], width: 560, cell_style: {border_width: 0})

		data = [["<b>Clave</b>", "<b>Créditos</b>", "<b>Estado</b>"]]
		data << ["<i>Número total de créditos matriculados:</i>", total_creditos, ""]

		# u = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 320, position: :left, cell_style: { inline_format: true, size: 9, align: :center, padding: 3, border_color: '818284'}, :column_widths => {1 => 60})
		
		# u.draw

		pdf.move_down 10

		pdf.text "Constancia que se expide a solicitud de la parte interesada en la Ciudad Universitaria en Caracas, el día #{I18n.l(bita.created_at, format: "%d de %B de %Y")}.", size: 10
		pdf.move_down 10
		pdf.text "<b> --Válida para el período actual--</b>", size: 11, inline_format: true, align: :center
		pdf.move_down 40

		# enlace = verificando ? nil : "#{Rails.application.routes.default_url_options[:host]}/verificar/#{bita.id}/documento"
		enlace = verificando ? nil : "https://coesfhe.com/verificar/#{bita.id}/documento"

		colocar_qr_y_firmas pdf, enlace, 100
	end

	def self.insertar_contenido_constancia_preinscripcion pdf, grado
		estudiante = grado.estudiante
		usuario = estudiante.usuario
		escuela = grado.escuela
		
		encabezado_central_con_logo pdf, "CONSTANCIA DE PREINSCRIPCIÓN", nil, 8

		# Opcion 1:
		pdf.image "app/assets/images/foto-perfil.png", at: [430, 395], height: 100

		pdf.move_down 20

		pdf.text "El departamento de Control de Estudios de la Facultad de HUMANIDADES Y EDUCACIÓN, por medio de la presente hace constar que #{usuario.la_el} BR. <b>#{estudiante.usuario.apellido_nombre}</b>, titular de la Cédula de Identidad <b>#{estudiante.id}</b> está <b>preinscrit#{usuario.genero}</b> en la Escuela de <b>#{escuela.descripcion.upcase}</b> de la Universidad Central de Venezuela.", size: 10, inline_format: true, align: :justify

		pdf.move_down 5

		pdf.text "El estudiante debe consignar esta planilla ante el Dpto de Control de Estudios para su firma y sello en una carpeta marrón tamaño oficio con sus respectivos ganchos.", size: 10, inline_format: true, align: :justify
		pdf.move_down 10
		pdf.text "<b>Fecha de Emisión:</b> #{I18n.l(Date.today, format: '%A, %d de %B de %Y')}.", size: 10, inline_format: true
		
		pdf.move_down 60

		pdf.text "Nombre y Firma del funcionario receptor                                                                  Firma del Estudiante", size: 10, align: :center

	end

	def self.resumen pdf, inscripcion

		cursados = inscripcion.total_creditos_cursados
		aprobados = inscripcion.total_creditos_aprobados
		eficiencia = (cursados and cursados > 0) ? (aprobados.to_f/cursados.to_f).round(4) : 0.0

		aux = inscripcion.cursadas
		promedio_simple = (aux and aux.count > 0 and aux.average('calificacion_final')) ? aux.average('calificacion_final').round(4) : 0.0

		aux = inscripcion.aprobadas
		promedio_simple_aprob = (aux and aux.count > 0 and aux.average('calificacion_final')) ? aux.average('calificacion_final').round(4) : 0.0

		aux = inscripcion.ponderado_aprobadas
		ponderado_apro = aprobados > 0 ? (aux.to_f/aprobados.to_f).round(4) : 0.0

		aux = inscripcion.ponderado
		ponderado = cursados > 0 ? (aux.to_f/cursados.to_f).round(4) : 0.0

		pdf.text "<b>Resumen Académico:</b>", size: 10, inline_format: true

		data = [["<b>Créditos Inscritos:</b>", inscripcion.total_creditos], 
				["<b>Créditos Cursados:</b>", cursados], 
				["<b>Créditos Aprobados (Sin Equivalencias):</b>", inscripcion.sin_equivalencias.total_creditos_aprobados],
				["<b>Créditos Equivalencia:</b>", inscripcion.por_equivalencia.total_creditos],
				["<b>Total Créditos Aprobados:</b>", aprobados],
				["<b>Eficiencia:</b>", eficiencia],
				["<b>Promedio Simple:</b>", promedio_simple],
				["<b>Promedio Simple Aprobado:</b>", promedio_simple_aprob],
				["<b>Promedio Ponderado Aprobado:</b>", ponderado_apro],
				["<b>Promedio Ponderado:</b>", ponderado]
			]

		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 300, cell_style: { inline_format: true, size: 9, padding: 3, border_color: '818284'})
		t.columns(1..1).position = 'right'
		t.draw


	end


	def self.insertar_tabla_convocados pdf, inscripciones#, k

		if inscripciones.first.seccion.asignatura.absoluta?
			data = [["<b>N°</b>", "<b>CÉDULA DE IDENTIDAD</b>", "<b>APELLIDOS Y NOMBRES</b>", "<b>COD. PLAN</b>", "<b>CALIF. DESCR.</b>", "<b>TIPO</b>", "<b>CALIF. EN LETRAS</b>"]]
		else
			data = [["<b>N°</b>", "<b>CÉDULA DE IDENTIDAD</b>", "<b>APELLIDOS Y NOMBRES</b>", "<b>COD. PLAN</b>", "<b>CALIF. DESCR.</b>", "<b>TIPO</b>","<b>CALIF. NUM.</b>", "<b>CALIF. EN LETRAS</b>"]]
		end

		i = 1
		inscripciones.each do |h|

			plan = h.grado ? h.grado.ultimo_plan : nil
			plan = plan.id if plan 
			if h.tiene_calificacion_posterior?
				estado_a_letras = 'AP'
				tipo_calificacion_id = 'NF'
				cali_a_letras = (h.calificacion_en_letras 'final')
			else
				tipo_calificacion_id = h.tipo_calificacion_id
				estado_a_letras = h.estado_a_letras
				cali_a_letras = h.calificacion_en_letras
			end

			if h.seccion.asignatura.absoluta?
				data << [i, 
				h.estudiante_id,
				h.estudiante.usuario.apellido_nombre,
				plan,
				estado_a_letras,
				tipo_calificacion_id,
				cali_a_letras
				]
			else
				data << [i, 
				h.estudiante_id,
				h.estudiante.usuario.apellido_nombre,
				plan,
				estado_a_letras,
				tipo_calificacion_id,
				h.colocar_nota_final,
				cali_a_letras
				]
			end

			if h.tiene_calificacion_posterior?
				i += 1
				data << [i, 
				h.estudiante_id,
				h.estudiante.usuario.apellido_nombre,
				plan,
				h.estado_a_letras,
				h.tipo_calificacion_id,
				h.colocar_nota_posterior,
				h.calificacion_en_letras
				]
			end
			i += 1
		end

		pdf.table data do |t|
			t.width = 540
			t.position = :center
			t.header = true
			t.row_colors = ["F0F0F0", "FFFFFF"]
			t.column_widths = {1 => 60, 2 => 220, 5 => 30, 7 => 70}
			t.cell_style = {:inline_format => true, :size => 9, align: :center, padding: 3, border_color: '818284' }
			t.column(2).style(:align => :justify)
			t.row(0).style(:align => :center)
			# t.column(1).style(:font_style => :bold)
		end

	end


	def self.tabla_descripcion_convocatoria pdf, seccion
		# pdf.number_pages "<page> in a total of <total>", [bounds.right - 50, 0]
    # pdf.start_page_numbering(, 9, nil, , 1)

		data = [["FECHA DE LA EMISIÓN: <b>#{Time.now.strftime('%d/%m/%Y %I:%M %p')}</b>", ""]]
		data << ["EJERCICIO: <b>#{seccion.ejercicio}</b>", "ACTA No.: <b>#{seccion.acta_no.upcase}</b>" ]
		if seccion.escuela.id.eql? 'POST'
			
			plan_id = seccion.asignatura.id[0..3]
			if plan = Plan.where(id: plan_id).first 
				descripcion = plan.descripcion.upcase
			else
				descripcion = seccion.asignatura.descripcion.upcase
			end

			data << ["<b>#{descripcion}</b>", "PERÍODO ACADÉMICO: <b>#{seccion.periodo.anno}</b>" ]

		else
			data << ["ESCUELA: <b>#{seccion.escuela.descripcion.upcase}</b>", "PERÍODO ACADÉMICO: <b>#{seccion.periodo.anno}</b>" ]
		end

		t = pdf.make_table(data, header: false, width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :left, padding: 1, border_color: 'FFFFFF'})
		t.draw
	end


	def self.acta_firmas pdf, seccion

		data = [["<b>JURADO EXAMINADOR</b>", "<b>SECRETARÍA</b>"]]
		t = pdf.make_table(data, header: false, width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 1, border_color: 'FFFFFF'}, :column_widths => {0 => 360})
		t.draw

		pdf.move_down 5

		prof_aux = seccion.profesor ? seccion.profesor.usuario.apellido_nombre.upcase : "___________________________" 
		data = [["APELLIDOS Y NOMBRES", "FIRMAS", ""]]
		data << ["#{prof_aux}", "___________________________", "NOMBRE: _______________________"]
		data << ["___________________________", "___________________________", "FIRMA:     _______________________"]
		data << ["___________________________", "___________________________", "FECHA:    _______________________"]

		t = pdf.make_table(data, header: false, width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center, padding: 1, border_color: 'FFFFFF'})
		t.draw

	end


	def self.tabla_descripcion_seccion pdf, seccion
		pdf.move_down 10

		asig = seccion.asignatura

		data = [["<b>Código</b>", "<b>Asignatura</b>", "<b>Sección</b>", "<b>Período</b>", "<b>Créditos</b>"]]

		data << [ "#{asig.id}", "#{asig.descripcion}", "#{seccion.numero}", "#{seccion.periodo_id}", "#{asig.creditos}"]

		t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 10, align: :center, padding: 3, border_color: '818284'}, column_widths: {1 => 300})
		t.draw
		pdf.move_down 10		
	end

	def self.encabezado_central_con_logo pdf, titulo, escuela = nil, size = nil, estudiante = nil

		size_logo = size ? size*4 : 50 
		size ||= 12
		pdf.image "app/assets/images/logo_ucv.png", position: :center, height: size_logo, valign: :top
		pdf.move_down 5
		pdf.text "UNIVERSIDAD CENTRAL DE VENEZUELA", align: :center, size: size 
		pdf.move_down 5
		pdf.text "FACULTAD DE HUMANIDADES Y EDUCACIÓN", align: :center, size: size
		pdf.move_down 5
		if escuela and escuela.id.eql? 'POST'
			pdf.text "CONTROL DE ESTUDIOS DE POSTGRADO", align: :center, size: size
		else
			pdf.text "CONTROL DE ESTUDIOS DE PREGRADO", align: :center, size: size
			if escuela
				pdf.move_down 5
				pdf.text escuela.descripcion.upcase, align: :center, size: size
			end
		end

		if estudiante and estudiante.usuario and estudiante.usuario.foto_perfil and estudiante.usuario.foto_perfil.attached?
			require 'open-uri'
			pdf.image open(estudiante.usuario.foto_perfil.service_url), at: [450, 720], height: 80 
		end

		pdf.move_down 5
		pdf.text titulo, align: :center, size: size, style: :bold

		pdf.move_down 5

		# return pdf
	end


end