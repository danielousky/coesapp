class Usuario < ApplicationRecord
	#CONSTANTES:
	has_one_attached :foto_perfil
	has_one_attached :imagen_ci
	ESTADOS_CIVILES = ['Soltero/a.', 'Casado/a.', 'Concubinato', 'Divorciado/a.', 'Viudo/a.']
	NACIONALIDAD = ['Venezolano/a', 'Venezolano/a. Nacionalizado/a', 'Extranjero/a']

	DISCAPACIDADES = ['SENSORIAL VISUAL', 'SENSORIAL AUDITIVA', 'MOTORA MIEMBROS INFERIORES', 'MOTORA MIEMBROS SUPERIORES', 'MOTORA AMBOS MIEMBROS']
	# VARIABLES:
	self.primary_key = :ci
	enum sexo: [:Femenino, :Masculino]
	enum estado_civil: ESTADOS_CIVILES
	enum nacionalidad: NACIONALIDAD
	attr_accessor :password_confirmation

	# ASOCIACIONES:
	has_one :administrador
	has_one :estudiante
	has_one :profesor

	has_many :autorizadas
	has_many :restringidas, through: :autorizadas

	has_many :bitacoras
	accepts_nested_attributes_for :bitacoras

	# TRIGGERS:
	after_initialize :set_default_sexo, if: :new_record?
	# before_save :set_default, if: :new_record?
	before_save :resize_image
	before_validation :set_default, on: :create
	# VALIDACIONES:
	validates :ci, presence: true, uniqueness: true
	validates :nombres, presence: true, unless: :new_record?
	validates :apellidos, presence: true, unless: :new_record?
	validates :sexo, presence: true, unless: :new_record?
	validates :password, presence: true
	validates :password, confirmation: true

	# SCOPES:
	scope :search, lambda { |clave| 
		where("ci LIKE ? OR nombres LIKE ? OR apellidos LIKE ? OR ci LIKE ? OR email LIKE ?","%#{clave}%","%#{clave}%","%#{clave}%", "%#{clave}%", "%#{clave}%")
	}

	# scope :search, lambda { |clave| 
	# 	where("MATCH(ci, nombres, apellidos, email, telefono_habitacion, telefono_movil) AGAINST('#{clave}')")
	# }

	# FUNCIONES:

	require 'mini_magick'
	def resize_image
	end

	def correo_descripcion
		compilado = apellidos ? "#{apellidos.titleize} " : "" 

		compilado += "#{nombres.titleize} " if nombres
		compilado += "<#{email}>"

		compilado
	end

	def datos_incompletos?
		((self.attributes.values.reject{|e| !e.blank?}.any?) or (self.ci.eql? self.password) or (self.foto_perfil.nil? or (self.foto_perfil and !self.foto_perfil.attached?))) ? true : false
	end

	def autorizado? *args 

		if administrador and administrador.ninjas_or_jefe_control_estudio?
			true
		else
			if args[1]
				restringidas.where(controlador: args[0], accion: args[1]).any?
			else
				autorizadas.where(restringida_id: args[0]).any?
			end
		end
	end

    def self.naciones
      require 'json'

      file = File.read("#{Rails.root}/public/countriesToCities.json")

      JSON.parse(file)
    end

	def edad
		if fecha_nacimiento
			hoy = Date.today
			a = hoy.year - fecha_nacimiento.year
			a = a - 1 if (fecha_nacimiento.month >  hoy.month or (fecha_nacimiento.month >= hoy.month and fecha_nacimiento.day > hoy.day))
			return a
		else
			return nil
		end
	end

	def descripcion_nacimiento
		aux = ciudad_nacimiento
		aux += " - #{pais_nacimiento}" if pais_nacimiento
		return aux
	end


	def ultimo_plan
		estudiante ? estudiante.ultimo_plan : '--'
		
	end

	def admin?
		not self.administrador.nil?
	end

	def roles_generales
      aux = []
      aux << "Administrador" if administrador
      aux << "Profesor" if profesor
      aux << "Estudiante" if estudiante

      return aux		
	end

	def sexo_to_s
		aux = 'Mujer' if mujer?
		aux = 'Hombre' if hombre?
		return aux.blank? ? 'Indefinido' : aux
	end

	def mujer?
		return self.sexo.eql? 'Femenino'
	end

	def hombre?
		return self.sexo.eql? 'Masculino'
	end

	def la_el
		mujer? ? 'la' : 'el'
	end

	def genero
		gen = "@"
		gen = "a" if self.mujer?
		gen = "o" if self.hombre?
		return gen
	end

	def primer_nombre
		nombres.split(" ").first
	end

	def primer_apellido
		apellidos.split(" ").first
	end

	def primer_nombre_apellido
		"#{primer_nombre} #{primer_apellido}"
	end

	def descripcion_contacto
		contacto = ""
		contacto += "Correo: #{email.to_s}" if email
		contacto += "| Movil: #{telefono_movil.to_s}" if telefono_movil
		contacto += "| Habitación: #{telefono_habitacion.to_s}" if telefono_habitacion
		contacto = "Sin Información" if contacto.blank?
		return contacto
	end

	def nickname
		# aux = nombres ? nombres.split[0] : ci
		unless nombres.blank? 
			aux = (nombres.split[0].length < 6) ? nombres : nombres.split[0]
		else
			aux = ci
		end
		return aux
	end

	def nombre_completo
		if nombres and apellidos
			"#{nombres} #{apellidos}"
		else
			""
		end
	end

	def apellido_nombre
		if nombres and apellidos
			"#{apellidos}, #{nombres}"
		else
			""
		end

	end

	def roles
		aux = []
		aux << "#{administrador.desc_rol}" if administrador
		aux << "Estudiante" if estudiante
		aux << "Profesor (#{profesor.departamento.descripcion})" if profesor

		return aux
	end

	def descripcion_corta
		"(#{ci}) #{nombres.upcase}"
	end


	def descripcion
		"(#{ci}) #{nombre_completo}"
	end

	def descripcion_apellido
		"(#{ci}) #{apellido_nombre}"		
	end

	def self.autenticar(login,clave)
    	return Usuario.where(ci: login, password: clave).limit(1).first
  	end


	# FUNCIONES PROTEGIDAS:
	protected

	def upcase_nombres
		self.ci.strip!
		self.nombres.strip.upcase! if self.nombres
		self.apellidos.strip.upcase! if self.apellidos
	end

	def set_default
		upcase_nombres
		set_default_password
	end

	def set_default_password
		self.password ||= self.ci
	end

	def set_default_sexo
		self.sexo ||= :Femenino
	end


end
