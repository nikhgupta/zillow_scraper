ActiveAdmin.register_page "Scraping Task" do
  menu priority: 10

  controller do
    def index
      unless session[:scraper_running]
        notice = "Scraping is, currently, inactive. Please, click on 'Run Scraper' to start scraping Zillow.com"
        redirect_to dashboard_path, notice: notice
      end
    end
  end

  content title: "Zillow Scraping Task" do
      div id: 'resultsbox' do

        #TODO: get the starting time of the scrape, as well as rate per minute
        div id: "statistics" do
          div(class: "sidebar"){ h3 "Statistics" }
          table { tbody }
        end

        div id: 'crawler' do
          div(class: "sidebar"){ h3 "Crawling Progress" }
          table { tbody }
        end

        div id: "listing" do
          div(class: "sidebar"){ h3 "Scraping Progress" }
          table { tbody }
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

  page_action :start, method: :post do
    session[:scraper_running] = true
    Sidekiq::Queue.confirm_clear(*ZillowScraper::Queues)
    Sidekiq::Stats.new.reset
    Listing.delete_all
    BLOOM_FILTER.clear

    Crawler.perform_async
    redirect_to scraping_task_path, notice: "Scraper has been started."
  end

  # TODO: maybe, a pause scraper method too?
  page_action :stop, method: :post do
    Sidekiq::Queue.confirm_clear(*ZillowScraper::Queues)
    Sidekiq::Stats.new.reset
    Listing.delete_all
    BLOOM_FILTER.clear
    session[:scraper_running] = false
    redirect_to dashboard_path, notice: "Scraper has been stopped."
  end
end
