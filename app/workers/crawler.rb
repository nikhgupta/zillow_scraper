class Crawler
  include Sidekiq::Worker

  sidekiq_options queue: :zillow_scraper

  STARTING_URL = "http://www.zillow.com/browse/homes/"

  # keep a queue to remove duplicates
  def perform url = nil
    url ||= STARTING_URL

    return if BLOOM_FILTER.include?(url)
    BLOOM_FILTER.insert(url)

    page  = Mechanize::AGENT.get url
    links = page.links.map(&:href).compact

    # crawlable links
    links = links.select{ |link| link =~ /\/browse\/homes\// }
    links.each{ |link| self.class.perform_async link }

    # listings
    links = links.select{ |link| link =~ /\/b\// }
    links.each{ |link| ListingsScraper.perform_async link }

    # update faye
    broadcast_crawl url
  end

  private

  def broadcast_crawl url
    faye    = URI.parse "http://localhost:9292/faye"
    message = "Crawled URL: #{url}"
    message = { channel: "/scraper/messages", data: message }

    Net::HTTP.post_form faye, message: message.to_json
  end
end
