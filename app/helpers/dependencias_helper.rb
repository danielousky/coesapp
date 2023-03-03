module DependenciasHelper
	def render_haml(haml, locals = {})
		Haml::Engine.new(haml.strip_heredoc, format: :html5).render(self, locals)
	end

	def badge_orden_asignatura(asignatura)

		render_haml <<-HAML, asignatura: asignatura
			- if asignatura.anno.eql? 0
				- aux = asignatura.tipoasignatura ? asignatura.tipoasignatura.descripcion.titleize : 0
			- else
				- aux = asignatura.anno

			%span.badge.badge-info.tooltip-btn{'data-toggle': :tooltip, title: 'Orden'}= aux

		HAML
	end

	def descripcion_arbol(dep, adelante)

		render_haml <<-HAML, dep: dep, adelante: adelante
			- if (current_admin and current_admin.autorizado? 'Dependencias', 'destroy')
				= btn_eliminar_prelacion(dep)
			- asig = adelante ? dep.asignatura_dependiente : dep.asignatura

			= simple_toggle asignatura_path(asig) + "?dependencias=true", nil, "Ir al detalle de " + asig.descripcion, :primary, 'zoom-in'

			= badge_orden_asignatura(asig)
			|
			= asig.descripcion_id

		HAML
	end



	def btn_eliminar_prelacion(dep)

		link_to dependencia_path(dep), class: "tooltip-btn text-danger", 'data_toggle': :tooltip, title: 'Eliminar prelación', method: :delete do
			capture_haml{glyph :trash}
		end
	end
end
