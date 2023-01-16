class Historialplan < ApplicationRecord
	# self.table_name = 'historiales_planes'

	belongs_to :periodo
	belongs_to :plan

	belongs_to :grado
	has_one :estudiante, through: :grado
	has_one :escuela, through: :grado

	# OJO: Esta debe ser la validación: Que un estudiante no tenga más de un plan para un mismo periodo
	validates_uniqueness_of :grado_id, scope: [:periodo_id], message: 'El estudiante ya tiene un plan para el periodo y escuela', field_name: false

	validates :grado_id, presence: true

	scope :por_escuela, lambda { |escuela_id| joins(:plan).where("planes.escuela_id = '#{escuela_id}'")}

	def descripcion
		"#{plan.descripcion_completa} - Desde #{periodo_id}"
	end

	def self.carga_inicial
		begin
			Estudiante.where("plan IS NOT NULL").each do |e|
				if e.plan and e.plan.include? '290'
					plan_id = Plan.where("id LIKE '%290%'").limit(1).first.id
				elsif e.plan and e.plan.include? '280'
					plan_id = Plan.where("id LIKE '%280%'").limit(1).first.id
				else
					plan_id = Plan.where("id LIKE '%270%'").limit(1).first.id
				end

				print "ID: #{e.id}--- Plan: #{plan_id} .#{e.plan}."
				HistorialPlan.create(estudiante_id: e.id, plan_id: plan_id)
			end			
		rescue Exception => e
			return e
		end
	end

end
