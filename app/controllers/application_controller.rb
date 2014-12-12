class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  def scraper_running?
    view_context.scraper_running?
  end

  def scraper_stopped?
    view_context.scraper_stopped?
  end
end
