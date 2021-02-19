class Reportepago < ApplicationRecord
  belongs_to :inscripcionescuelaperiodo, dependent: :destroy

  enum tipo_transaccion: ['transferencia', 'deposito']

  has_one_attached :respaldo
end
