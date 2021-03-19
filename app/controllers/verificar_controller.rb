class VerificarController < ApplicationController

	def constancia_estudio

		bita = Bitacora.find params[:id]

		if bita.nil? and bita.objeto.nil? and !(bita.tipo_objeto.eql? 'Inscripcionescuelaperiodo')
			flash[:danger] = "No se puede verificar la Constancia de Estudio: No se encontró el recurso solicitado."
			redirect_back fallback_location: root_path
		else
			pdf = ExportarPdf.hacer_constancia_estudio bita.id, true

			unless send_data pdf.render, filename: "constancia_estudio_#{params[:id].to_s}.pdf", type: "application/pdf", disposition: "inline"
				flash[:error] = "En estos momentos no se pueden descargar el acta, intentelo más tarde."
			else
				info_bitacora "Verificada Constancia Estudio ##{bita.objeto.descripcion}", Bitacora::DESCARGA, bita.objeto
			end
		end
	end

	def constancia_inscripcion
		bita = Bitacora.find params[:id]
		if bita.nil? and bita.objeto.nil? and !(bita.tipo_objeto.eql? 'Inscripcionescuelaperiodo')
			flash[:danger] = "No se puede verificar la Constancia de Inscripción: No se encontró el recurso solicitado."
			redirect_back fallback_location: root_path
		else

			if bita.objeto.secciones.map{|s| s.horario}.compact.any?
				pdf = ExportarPdf.hacer_constancia_inscripcion bita.id, true
			else
				pdf = ExportarPdf.hacer_constancia_inscripcion_sin_horario bita.id, true
			end

			unless send_data pdf.render, filename: "constancia_estudio_#{params[:id].to_s}.pdf", type: "application/pdf", disposition: "inline"
				flash[:error] = "En estos momentos no se pueden descargar el acta, intentelo más tarde."
			else
				info_bitacora "Verificada Constancia Estudio ##{bita.objeto.descripcion}", Bitacora::DESCARGA, bita.objeto
			end
		end			
	end


end