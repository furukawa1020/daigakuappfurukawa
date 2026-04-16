class Admin::MokoTemplatesController < Admin::BaseController
  def index
    @moko_templates = MokoTemplate.all
  end

  def new
    @moko_template = MokoTemplate.new
  end

  def create
    @moko_template = MokoTemplate.new(moko_template_params)
    if @moko_template.save
      redirect_to admin_moko_templates_path, notice: "Moko Template created successfully!"
    else
      render :new
    end
  end

  def edit
    @moko_template = MokoTemplate.find(params[:id])
  end

  def update
    @moko_template = MokoTemplate.find(params[:id])
    if @moko_template.update(moko_template_params)
      redirect_to admin_moko_templates_path, notice: "Moko Template updated successfully!"
    else
      render :edit
    end
  end

  def destroy
    @moko_template = MokoTemplate.find(params[:id])
    @moko_template.destroy
    redirect_to admin_moko_templates_path, notice: "Moko Template deleted."
  end

  private

  def moko_template_params
    params.require(:moko_template).permit(:name, :rarity, :description, :evolution_stage)
  end
end
