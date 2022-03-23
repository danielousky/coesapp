class Restringida < ApplicationRecord
	GRUPOS = %w(Generales Estructurales Informacionales Inscripciones Importaciones Usuarios Calificaciones Programaciones Descargables)
			#    0              1              2             3             4            5           6            7
	has_many :autorizadas, dependent: :delete_all
	has_many :usuarios, through: :autorizadas

	validates :nombre_publico, presence: true

	has_many :perfiles_restringidas, class_name: 'PerfilRestringida'

	has_many :perfiles,  through: :perfiles_restringidas, class_name: 'Perfil'

	enum grupo: GRUPOS 

	def descripcion_completa
		"#{controlador} - #{accion} - #{nombre_publico} #{grupo}"
	end

end
