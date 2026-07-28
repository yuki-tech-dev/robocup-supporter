class PagesController < ApplicationController
  skip_before_action :require_login, only: %i[terms privacy_policy]

  def terms; end

  def privacy_policy; end
end
