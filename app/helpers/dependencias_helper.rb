module DependenciasHelper

	def badge_orden_asignatura(asignatura)

		if asignatura.anno.eql? 0
			aux = asignatura.tipoasignatura ? asignatura.tipoasignatura.descripcion.titleize : 0
		else
			aux = asignatura.anno
		end

		"<span class='badge badge-info tooltip-btn' data_toggle='tooltip', title='Orden'>#{aux}</span>"
	end

	def descripcion_arbol(dep, adelante)

		if (current_admin and current_admin.autorizado? 'Dependencias', 'destroy')
			out = btn_eliminar_prelacion(dep)
		end

		asig = adelante ? dep.asignatura_dependiente : dep.asignatura

		out += simple_toggle asignatura_path(asig) + "?dependencias=true", nil, "Ir al detalle de " + asig.descripcion, :primary, 'zoom-in'

		out += badge_orden_asignatura(asig)
		out += " | "
		out += asig.descripcion_id

		return asig
	end



	def btn_eliminar_prelacion(dep)
		link_to dependencia_path(dep), class: "tooltip-btn text-danger", 'data_toggle': :tooltip, title: 'Eliminar prelación', method: :delete do
			capture_haml{glyph :trash}
		end
	end
end
