module Admin
  class ParametrosGeneralesController < ApplicationController
    before_action :set_parametro_general, only: [:edit, :update]

    def index
      @titulo = 'Parámetros Generales del Sistema'
      @parametros_generales = ParametroGeneral.all
    end


    # PATCH/PUT /parametros_generales/1
    # PATCH/PUT /parametros_generales/1.json
    def update
      if @parametro_general.update(parametro_general_params)
        flash[:success] = 'Parámetro Actualizado'
      else
        flash[:error] = "Error al intentar guardar el Parámetro: #{@parametro_general.errors.full_messages.to_sentence}"
      end
      redirect_to parametros_generales_path
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_parametro_general
        @parametro_general = ParametroGeneral.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def parametro_general_params
        params.require(:parametro_general).permit(:id, :valor)
      end
  end
end 