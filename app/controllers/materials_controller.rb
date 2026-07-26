class MaterialsController < ApplicationController
  def new
    @material = Material.new
  end

  def create
    @material = Material.new(material_params)
    if @material.save
      # TODO: Issue #42で教材一覧画面が実装されたら、一覧へのリダイレクトに変更する
      redirect_to root_path, success: t("materials.create.success")
    else
      flash.now[:danger] = t("materials.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  private

  def material_params
    params.require(:material).permit(:title, :description, :file)
  end
end
