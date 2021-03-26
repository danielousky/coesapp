class Banco < ApplicationRecord
	has_many :reportepagos, foreign_key: 'banco_origen_id'

	def self.crear_bancos_iniciales
		Banco.create(id: '0134', nombre: 'Banesco')
		Banco.create(id: '0102', nombre: 'Banco De Venezuela')
		Banco.create(id: '0163', nombre: 'Banco Del Tesoro')
		Banco.create(id: '0105', nombre: 'Banco Mercantil')
		Banco.create(id: '0108', nombre: 'Banco Provincial')
		Banco.create(id: '0104', nombre: 'Banco Venezolano de Crédito')
	end

	def descripcion
		"#{nombre} (#{id})"
	end
end
