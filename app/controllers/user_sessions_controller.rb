class UserSessionsController < ApplicationController
  skip_before_action :require_login, only: %i[new create]

  def new; end

  def create
    @user = login(params[:email], params[:password])

    if @user
      remember_me! if params[:remember_me] == "1"
      redirect_to root_path, success: t("user_sessions.create.success")
    else
      flash.now[:danger] = t("user_sessions.create.failure")
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    logout
    redirect_to root_path, success: t("user_sessions.destroy.success")
  end
end
