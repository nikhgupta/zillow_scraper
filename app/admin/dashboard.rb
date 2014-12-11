ActiveAdmin.register_page "Dashboard" do

  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    if session[:scraper_running]
      div id: 'resultsbox' do
        h3 class: :emphasize do
          "Zillow Scraper"
        end
        span " - Scraper started on #{Time.now}"
      end
    else
      div class: "blank_slate_container", id: "dashboard_default_message" do
        span class: "blank_slate" do
          span I18n.t("active_admin.dashboard_welcome.welcome")
          small I18n.t("active_admin.dashboard_welcome.call_to_action")
        end
      end
    end
  end

  page_action :run_scraper, method: :post do
    session[:scraper_running] = true
    Crawler.perform_async
    redirect_to dashboard_path, notice: "Scraper has been started."
  end

  page_action :stop_scraper, method: :post do
    Sidekiq::Queue.confirm_clear(*ZillowScraper::Queues)
    BLOOM_FILTER.clear
    session[:scraper_running] = false
    redirect_to dashboard_path, notice: "Scraper has been stopped."
  end

  action_item :scraper do
    if session[:scraper_running]
      link_to "Stop Scraper", dashboard_stop_scraper_path, method: :post
    else
      link_to "Run Scraper", dashboard_run_scraper_path, method: :post
    end
  end
end
