class ListingsScraper
  include Sidekiq::Worker

  sidekiq_options queue: :zillow_scraper

  def perform url
    page = Mechanize::AGENT.get url

    # update faye
    broadcast_listing page
  end

  private

  def broadcast_listing page
    faye    = URI.parse "http://localhost:9292/faye"
    message = "Found Listing: #{page.search("title").text}"
    message = { channel: "/scraper/messages", data: message }

    Net::HTTP.post_form faye, message: data.to_json
  end
end
