module ApplicationHelper
  def scraper_running?
    Sidekiq::Stats.new.enqueued > 0 || session[:scraper_running]
  end

  def scraper_stopped?
    !scraper_running?
  end
end
