class VerificarController < ApplicationController
	layout 'verify'
	def documento
		bita = Bitacora.find params[:id]

		if bita.nil? and bita.objeto.nil?
			flash[:danger] = "No se puede verificar la Constancia de Estudio: No se encontró el recurso solicitado."
			redirect_back fallback_location: root_path
		else
			info_bitacora "Verificada Constancia Estudio ##{bita.objeto.descripcion}", Bitacora::DESCARGA, bita.objeto
			@titulo = 'Validación de documentos'
			@bitacora = bita
		end
	end

	def descargar_documento
		bita = Bitacora.find params[:id]
		if bita.nil? and bita.objeto.nil?
			flash[:danger] = "No se puede encontrar la bitácora del documento."
			redirect_back fallback_location: root_path

		elsif !((bita.descripcion.include? "Descarga Constancia Inscripción") or (bita.descripcion.include? "Descarga Constancia Estudio"))
			flash[:danger] = "El documento al cual hace referencia es inválido para verificar."
			redirect_back fallback_location: root_path
		else
			
			if bita.descripcion.include? 'Descarga Constancia Inscripción'

				if bita.objeto.secciones.map{|s| s.horario}.compact.any?
					pdf = ExportarPdf.hacer_constancia_inscripcion bita.id
				else
					pdf = ExportarPdf.hacer_constancia_inscripcion_sin_horario bita.id
				end

			elsif bita.descripcion.include? 'Descarga Constancia Estudio'

				pdf = ExportarPdf.hacer_constancia_estudio bita.id
				
			end

			respond_to do |format|
				format.pdf do
					send_data pdf.render,
					type: 'application/pdf',
					disposition: 'inline',
					filename: "docuemento_verificado_#{bita.id}.pdf"
				end
			end

		end			
	end


end