class MaterialsController < ApplicationController
  def index
    # N+1問題対策: 一覧で各資料の添付ファイル情報を都度取得しないよう、事前に一括読み込みしておく
    @materials = Material.with_attached_file.order(created_at: :desc)
  end

  def new
    @material = Material.new
  end

  def create
    @material = Material.new(material_params)
    if @material.save
      redirect_to materials_path, success: t("materials.create.success")
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
