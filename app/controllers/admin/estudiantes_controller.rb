module Admin
  class EstudiantesController < ApplicationController
    # Privilegios

    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :set_escuela, only: [:index]

    def index
      @estudiantes = @escuela.estudiantes
    end

    private

      def set_escuela
        if params[:escuela_id]
          @escuela = Escuela.find(params[:escuela_id])
        else
          flash[:danger] = 'Por favor seleccione una escuela en el menú'
          redirect_back fallback_location: principal_admin_index_path
        end
      end
  end
end