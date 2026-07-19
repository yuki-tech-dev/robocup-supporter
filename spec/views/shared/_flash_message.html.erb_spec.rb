require 'rails_helper'

RSpec.describe "shared/_flash_message.html.erb", type: :view do
  it "フラッシュメッセージが表示されること" do
    flash[:notice] = "success"
    render
    expect(rendered).to include("success")
  end
end
