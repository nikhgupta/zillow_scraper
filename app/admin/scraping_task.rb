ActiveAdmin.register_page "Scraping Task" do
  menu priority: 2

  controller do
    def index
      if scraper_stopped?
        notice = "Scraping is, currently, inactive. Please, click on 'Run Scraper' to start scraping Zillow.com"
        redirect_to dashboard_path, notice: notice
      end
    end
  end

  content title: "Zillow Scraping Task" do
      div id: 'resultsbox' do

        containers = {
          statistics: :statistics,
          crawler: :crawling_progress,
          listing: :scraping_progress
        }

        #TODO: get the starting time of the scrape, as well as rate per minute
        containers.each do |id, heading|
          div id: id do
            div(class: "sidebar"){ h3 heading }
            table { tbody }
          end
        end
      end
  end

  action_item :scraper, if: proc{ scraper_running? } do
    link_to "Stop Scraper", scraping_task_stop_path, method: :post
  end

  action_item :scraper, if: proc{ scraper_stopped? } do
    link_to "Run Scraper", scraping_task_start_path, method: :post
  end

  page_action :start, method: :post do
    session[:scraper_running] = true
    ZillowScraper.stop_scraper_and_reset_everything!
    ZillowCrawler.perform_async
    redirect_to scraping_task_path, notice: "Scraper has been started."
  end

  # TODO: maybe, a pause scraper method too?
  page_action :stop, method: :post do
    ZillowScraper.stop_scraper_and_reset_everything!
    session[:scraper_running] = false
    redirect_to dashboard_path, notice: "Scraper has been stopped."
  end
end
