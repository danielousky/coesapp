module Admin
  class BitacorasController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador
    before_action :filtro_autorizado
    # before_action :filtro_ninjas_or_jefe_control_estudio!, only: [:destroy, :delete_rol]

    before_action :set_usuario

    def index
    end


    private
      # Use callbacks to share common setup or constraints between actions.
      # def set_usuario
      #   @usuario = Usuario.find(params[:id])
      # end

      # Never trust parameters from the scary internet, only allow the white list through.
      # def usuario_params
      #   params.require(:usuario).permit(:ci, :nombres, :apellidos, :email, :telefono_habitacion, :telefono_movil, :password, :sexo, :password_confirmation, :nacionalidad, :estado_civil, :fecha_nacimiento, :pais_nacimiento, :ciudad_nacimiento)
      # end


  end
end