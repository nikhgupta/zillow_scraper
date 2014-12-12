ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc{ I18n.t("active_admin.dashboard") }

  content title: proc{ I18n.t("active_admin.dashboard") } do
    panel "Current Statistics" do
      div id: :dashboard_stat_box do
        table { tbody }
      end
    end
  end

  action_item :scraper, if: proc{ scraper_running? } do
    link_to "Stop Scraper", scraping_task_stop_path, method: :post
  end

  action_item :scraper, if: proc{ scraper_stopped? } do
    link_to "Run Scraper", scraping_task_start_path, method: :post
  end

  page_action :statistics, method: :post do
    stats = Sidekiq::Stats.new

    render json: {
      status: (scraper_running? ? "Running" : "Finished/Stopping.."),
      processed: stats.processed,
      failed: stats.failed,
      queues: stats.queues,
      enqueued: stats.enqueued,
      items: Listing.count,
    }
  end
end
