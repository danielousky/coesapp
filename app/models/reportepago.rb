class Reportepago < ApplicationRecord
  belongs_to :inscripcionescuelaperiodo, dependent: :destroy

  belongs_to :banco_origen, foreign_key: 'banco_origen_id', class_name: 'Banco'
  
  enum tipo_transaccion: ['transferencia', 'deposito']

  has_one_attached :respaldo
end
