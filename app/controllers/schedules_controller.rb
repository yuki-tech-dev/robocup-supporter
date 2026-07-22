class SchedulesController < ApplicationController
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

  private

  def schedule_params
    params.require(:schedule).permit(:title, :start_time, :end_time, :location, :description)
  end
end
