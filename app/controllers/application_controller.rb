class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  include SessionsHelper
  def default_url_options
    { locale: I18n.locale }
  end
  before_action :set_locale
  def set_locale
    I18n.locale = params[:locale]
  end
end
