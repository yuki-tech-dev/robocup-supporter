class TopController < ApplicationController
  skip_before_action :require_login, only: %i[index]

  def index
    return unless logged_in?

    @schedules = Schedule.all
    @upcoming_schedules = Schedule.where("start_time >= ?", Time.current)
                                   .order(start_time: :asc)
                                   .limit(5)
  end
end
