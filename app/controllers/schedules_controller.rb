class SchedulesController < ApplicationController
  # before_action :set_schedule
  # skip_before_action :set_schedule, only: %i[new create]
  before_action :set_schedule, only: %i[show edit update destroy]

  def new
    @schedule = Schedule.new
  end

  def create
    @schedule = Schedule.new(schedule_params)
    if @schedule.save
      # TODO: Issue #35でカレンダーUIが実装されたら、一覧（カレンダー）へのリダイレクトに変更する
      redirect_to root_path, success: t("schedules.create.success")
    else
      flash.now[:danger] = t("schedules.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @schedule.update(schedule_params)
      redirect_to root_path, success: t("schedules.update.success")
    else
      flash.now[:danger] = t("schedules.update.failure")
      render :edit, status: :unprocessable_entity
    end
  end

  def show; end

  def edit; end

  def destroy
    @schedule.destroy!
    redirect_to root_path, danger: t("schedules.destroy.success")
  end

  private

  def set_schedule
    @schedule = Schedule.find(params[:id])
  end

  def schedule_params
    params.require(:schedule).permit(:title, :start_time, :end_time, :location, :description)
  end
end
