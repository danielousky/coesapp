module Admin
  class DependenciasController < ApplicationController
    # Privilegios
    before_action :filtro_logueado

    before_action :filtro_administrador
    before_action :filtro_autorizado

    def index
    end

    def create
      total_saved = 0
      (params[:dependencia]['asignatura_dependiente_id']).reject!(&:empty?)
      params[:dependencia]['asignatura_dependiente_id'].each do |a_d_id|
        dependiente = Dependencia.new(asignatura_id: params[:dependencia]['asignatura_id'])
        dependiente.asignatura_dependiente_id = a_d_id
        total_saved+= 1 if dependiente.save
      end
      if total_saved > 0
        flash[:success] = "Se guardaron con éxito #{total_saved} dependencias."
      else
        flash[:danger] = 'No fue posible guardar ninguna dependencia. Por favor revise e inténtelo nuevamente.'
      end
      redirect_to "#{asignatura_path(params[:dependencia]['asignatura_id'])}?dependencias=true"
    end

    def destroy
      @dependencia = Dependencia.find params[:id]
      return_asig_id = @dependencia.asignatura_id

      if @dependencia.destroy
        flash[:info] = 'Dependencia Eliminada'
      else
        flash[:danger] = "Inconvenientes al intentar eliminar la relación de dependencia: #{@dependencia.errors.full_messages.to_sentence}"
      end
      redirect_to "#{asignatura_path(return_asig_id)}?dependencias=true"

    end

    # private

    # def dependencia_params
    #   params.require(:dependencia).permit(:asignatura_id, :asignatura_dependiente_id)
    # end

  end
end