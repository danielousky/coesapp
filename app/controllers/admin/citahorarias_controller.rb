module Admin
  class CitahorariasController < ApplicationController
    # Privilegios
    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado

    def index
      @escuela = Escuela.find params[:escuela_id] if params[:escuela_id]
      @grados = @escuela.grados.no_preinscrito
    end
  end
end