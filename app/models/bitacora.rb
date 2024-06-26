class Bitacora < ApplicationRecord
  # CONSTANTES
  GENERAL = 0
  CREACION = 1
  ACTUALIZACION = 2
  ELIMINACION = 3
  DESCARGA = 4
  ESPECIAL = 5
  CLONACION = 5

  #SCOPE
  scope :search, lambda {|value| where("descripcion LIKE ? OR comentario LIKE ? OR id_objeto LIKE ?", "%#{value}%", "%#{value}%", "%#{value}%")}
  scope :search_by_type, lambda {|type| where(tipo_objeto: type)}
  scope :search_by_id, lambda {|id| where(id_objeto: id)}

  # VARIABLES
  enum tipo: [:general, :creacion, :actualizacion, :eliminacion, :descarga, :especial]

  #TRIGGERS
  before_create :set_default_tipo, if: :new_record?

  # RELACIONES
  belongs_to :usuario, primary_key: :ci, optional: true
  belongs_to :seccion, primary_key: :ci, optional: true

  def objeto
    (id_objeto and tipo_objeto) ? tipo_objeto.constantize.find(id_objeto) : nil
  end

  protected

  def set_default_tipo
    tipo ||= :generales
  end

end
