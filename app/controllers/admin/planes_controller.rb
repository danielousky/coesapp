module Admin 
  class PlanesController < ApplicationController
    before_action :filtro_logueado
    before_action :filtro_administrador    
    before_action :set_plan, only: [:show, :edit, :update, :destroy]

    # GET /planes
    # GET /planes.json
    def index
      @titulo = "Planes de Estudio"
      @planes = Plan.all
    end

    # GET /planes/1
    # GET /planes/1.json
    def show
      @titulo = "Detalle del Plan de Estudio: #{@plan.descripcion_completa}"      
    end

    # GET /planes/new
    def new
      @titulo = "Detalle del Plan de Estudio: #{@plan.descripcion_completa}"
      @plan = Plan.new
    end

    # GET /planes/1/edit
    def edit
      @titulo = "Editnado Plan de Estudio: #{@plan.descripcion_completa}"

    end

    # POST /planes
    # POST /planes.json
    def create
      @plan = Plan.new(plan_params)

      respond_to do |format|
        if @plan.save
          format.html { redirect_to @plan, notice: 'Plan was successfully created.' }
          format.json { render :show, status: :created, location: @plan }
        else
          format.html { render :new }
          format.json { render json: @plan.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /planes/1
    # PATCH/PUT /planes/1.json
    def update
      respond_to do |format|
        if @plan.update(plan_params)
          format.html { redirect_to @plan, notice: 'Plan was successfully updated.' }
          format.json { render :show, status: :ok, location: @plan }
        else
          format.html { render :edit }
          format.json { render json: @plan.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /planes/1
    # DELETE /planes/1.json
    def destroy
      @plan.destroy
      respond_to do |format|
        format.html { redirect_to planes_url, notice: 'Plan was successfully destroyed.' }
        format.json { head :no_content }
      end
    end

    private
      # Use callbacks to share common setup or constraints between actions.
      def set_plan
        @plan = Plan.find(params[:id])
      end

      # Never trust parameters from the scary internet, only allow the white list through.
      def plan_params
        params.require(:plan).permit(:id, :description)
      end
  end
end