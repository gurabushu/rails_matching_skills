class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  # 認証は各コントローラーで個別に設定
  before_action :configure_permitted_parameters, if: :devise_controller?
  
  # ログアウト後のリダイレクト先を設定
  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

  private

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: [:name, :skill, :description])
    devise_parameter_sanitizer.permit(:account_update, keys: [:name, :skill, :description])
  end
end
