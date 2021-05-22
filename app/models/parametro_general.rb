class ParametroGeneral < ApplicationRecord
  # SET GLOBALES:
  self.table_name = 'parametros_generales'

  # FECHA TOPE INGRESO
  def self.max_fecha_ingreso_nuevos
    ParametroGeneral.where(id: "MAX_FECHA_INGRESO_NUEVOS").first
  end

  def self.max_fecha_ingreso_nuevos_valor
    max_fecha_ingreso_nuevos.present? ? max_fecha_ingreso_nuevos.valor : 'POR DEFINIR'
  end

  # JEFE CONTROL ESTUDIO
  def self.jefe_control_estudio
    ParametroGeneral.where(id: "JEFE_CONTROL_ESTUDIO").first
  end

  def self.jefe_control_estudio_valor
    jefe_control_estudio.present? ? jefe_control_estudio.valor : 'Prof. PEDRO CORONADO'
  end

  # DIRECTOR ACADEMICO
  def self.director_academico_estudio
  	ParametroGeneral.where(id: "DIRECTOR_ACADEMICO").first
  end

  def self.director_academico_estudio_valor
  	director_academico_estudio.present? ? director_academico_estudio.valor : 'Prof. PEDRO BARRIOS MOTA'
  end


  def self.arancel_ingreso_facultad
    ParametroGeneral.where(id: "ARANCEL_INGRESO_FACULTAD").first
  end

  def self.arancel_ingreso_facultad_valor
    arancel_ingreso_facultad.present? ? arancel_ingreso_facultad.valor : 'Por definir'
  end

  # BANCO
  def self.cuenta_facultad_banco
    ParametroGeneral.where(id: "CUENTA_FACULTAD_BANCO").first
  end

  def self.cuenta_facultad_banco_valor
    cuenta_facultad_banco.present? ? cuenta_facultad_banco.valor : 'Banco de Venezuela'
  end

  # TIPO
  def self.cuenta_facultad_tipo
    ParametroGeneral.where(id: "CUENTA_FACULTAD_TIPO").first
  end

  def self.cuenta_facultad_tipo_valor
    cuenta_facultad_tipo.present? ? cuenta_facultad_tipo.valor : 'Cuenta corriente'
  end

  # NUMERO
  def self.cuenta_facultad_numero
    ParametroGeneral.where(id: "CUENTA_FACULTAD_NUMERO").first
  end

  def self.cuenta_facultad_numero_valor
    cuenta_facultad_numero.present? ? cuenta_facultad_numero.valor : '0102-0491-71000-938567-4'
  end

  # TITULAR
  def self.cuenta_facultad_titular
    ParametroGeneral.where(id: "CUENTA_FACULTAD_TITULAR").first
  end

  def self.cuenta_facultad_titular_valor
    cuenta_facultad_titular.present? ? cuenta_facultad_titular.valor : 'Ingresos Propios-Facultad Humanidades y Educación'
  end

  # RIF
  def self.rif_facultad
    ParametroGeneral.where(id: "RIF_FACULTAD").first
  end

  def self.rif_facultad_valor
    rif_facultad.present? ? rif_facultad.valor : 'G20000062-7'
  end

end 
