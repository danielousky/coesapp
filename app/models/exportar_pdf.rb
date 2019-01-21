
class ExportarPdf
	include Prawn::View

	def self.hacer_kardex id

		pdf = Prawn::Document.new(top_margin: 20)

		estudiante = Estudiante.find id
		periodos = Periodo.order("id ASC").all
		inscripcionsecciones = estudiante.inscripcionsecciones.joins(:seccion).order("asignatura_id ASC, numero DESC")

		pdf.image "app/assets/images/logo_ucv.png", position: :center, height: 50, valign: :top
		pdf.move_down 5
		pdf.text "UNIVERSIDAD CENTRAL DE VENEZUELA", align: :center, size: 12
		pdf.move_down 5
		pdf.text "FACULTAD DE HUMANIDADES Y EDUCACIÓN", align: :center, size: 12
		pdf.move_down 5
		pdf.text "CONTROL DE ESTUDIOS DE PREGRADO", align: :center, size: 12
		pdf.move_down 5
		pdf.text "Historia Académica", align: :center, size: 12, style: :bold

		pdf.move_down 5
	# 	#titulo
		pdf.text "<b>Cédula:</b> #{estudiante.usuario_id}", size: 9, inline_format: true
		pdf.text "<b>Plan:</b> #{estudiante.ultimo_plan}", size: 9, inline_format: true
		pdf.text "<b>Alumno:</b> #{estudiante.usuario.apellido_nombre.upcase}", size: 9, inline_format: true
		pdf.move_down 10

		periodos.each do |periodo|
			pdf.text "<b>Periodo:</b> #{periodo.id}", size: 10, inline_format: true
			pdf.move_down 5

			# secciones_periodo = inscripcionsecciones.joins(:seccion).where("secciones.periodo_id": periodo.id)
			secciones_periodo = inscripcionsecciones.del_periodo periodo.id

			if secciones_periodo.count > 0
				data = [["<b>Código</b>", "<b>Asignatura</b>", "<b>Convocatoria</b>", "<b>Créditos</b>", "<b>Final</b>", "<b>Final_alfa</b>", "<b>Sección</b>"]]

				secciones_periodo.each do |h|
					sec = h.seccion
					asig = sec.asignatura
					aux = asig.descripcion
					nota_final = h.calificacion_para_kardex
					data << [asig.id_uxxi, h.descripcion, sec.tipo_convocatoria, asig.creditos, nota_final, h.tipo_calificacion, h.seccion.numero]
				end

			end
			t = pdf.make_table(data, header: true, row_colors: ["F0F0F0", "FFFFFF"], width: 540, position: :center, cell_style: { inline_format: true, size: 9, align: :center })
			t.draw

      		t = Time.new

      	# pdf.start_page_numbering(250, 15, 7, nil, to_utf16("#{t.day} / #{t.month} / #{t.year}       Página: <PAGENUM> de <TOTALPAGENUM>"), 1)

		pdf.move_down 20
		pdf.text "<b>NOTA:</b> CUANDO EXISTA DISCREPANCIA ENTRE LOS DATOS CONTENIDOS EN LAS ACTAS DE EXAMENES Y ÉSTE COMPROBANTE, LOS PRIMEROS SE TENDRÁN COMO AUTÉNTICOS PARA CUALQUIER FIN.", size: 11, inline_format: true, align: :justify
		pdf.move_down 10
		pdf.text "* ÉSTE COMPROBANTE ES DE CARACTER INFORMATIVO, NO TIENE VALIDEZ LEGAL *", font_size: 11, align: :center
		pdf.move_down 15
		pdf.text "________________", size: 11, align: :right
		pdf.move_down 5
		pdf.text "Firma Autorizada", size: 11, align: :right

		end

		return pdf
	end


end