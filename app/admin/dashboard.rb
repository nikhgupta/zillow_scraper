ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    div class: "blank_slate_container", id: "dashboard_default_message" do
      span class: "blank_slate" do
        span I18n.t("active_admin.dashboard_welcome.welcome")
        small I18n.t("active_admin.dashboard_welcome.call_to_action")
      end
    end
  end

  action_item :scraper do
    if session[:scraper_running]
      link_to "Stop Scraper", scraping_task_stop_path, method: :post
    else
      link_to "Run Scraper", scraping_task_start_path, method: :post
    end
  end

  page_action :statistics, method: :post do
    stats = Sidekiq::Stats.new

    render json: {
      processed: stats.processed,
      failed: stats.failed,
      queues: stats.queues,
      enqueued: stats.enqueued,
      items: Listing.count,
    }
  end
end
