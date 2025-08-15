class V1::UserSettingController < ApplicationController
  def update
    dto = UserSettingDto.new(user_setting_params)
  end

  private

  def user_setting_params
    params.require(:user_setting).permit(:theme, :notifications_enabled, :language)
  end
end
