class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :logged_in?, :current_user
  before_action :require_login
  add_flash_types :success, :danger

  def logged_in?
    !!current_user
  end

  # def logout
  #   session[:user_id] = nil
  #   @current_user = nil
  # end

  # def current_user
  #   @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  # end

  private

  def require_login
    redirect_to login_path, danger: t("defaults.flash_message.require_login") unless logged_in?
  end
end
