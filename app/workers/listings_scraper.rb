class ListingsScraper
  include Sidekiq::Worker

  sidekiq_options queue: :zillow_scraper

  def perform url
    page = Mechanize::AGENT.get url

    # update faye
    broadcast_listing url, page
  end

  private

  def broadcast_listing url, page
    faye    = URI.parse "http://localhost:9292/faye"

    title   = page.search("title").text.gsub(/ - Zillow$/, '')
    message = "<span class='listings'>- Found Listing: <a href='#{url}'>#{title}</a></span>"
    message = { channel: "/scraper/messages", data: message }

    Net::HTTP.post_form faye, message: message.to_json
  end
end
