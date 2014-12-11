class Crawler
  include Sidekiq::Worker

  sidekiq_options queue: :zillow_scraper

  STARTING_URL = "http://www.zillow.com/browse/homes/"

  # FIXME: mechanize error pages
  def perform url = nil
    url ||= STARTING_URL

    return if BLOOM_FILTER.include?(url)
    BLOOM_FILTER.insert(url)

    page  = Mechanize::AGENT.get(url)
    links = page.links.map(&:href).compact
    links = links.map do |link|
      link[0] == "/" ? "http://www.zillow.com#{link}" : link
    end

    # crawlable links
    links.select do |link|
      link.include?(url) && link != url
    end.each do |link|
      priority = job_priority_for(link)
      self.class.perform_with_priority priority, link
    end

    # listings
    links.select do |link|
      link =~ /\/(?:b|homedetails)\//
    end.each do |link|
      ListingsScraper.perform_with_priority :listing, link
    end

    # update faye
    broadcast_crawl url, page
  end

  private

  def job_priority_for url
    match = url.match(/\/browse\/homes\/(.*)$/)
    return :medium unless match
    parts = match[1].split("/")
    case parts.length
    when 1 then :state
    when 2 then :county
    when 3 then :zip_code
    when 4 then :street
    end
  end

  def broadcast_crawl url, page
    faye    = URI.parse "http://localhost:9292/faye"
    title   = extract_meaningful_title_from(url, page)
    message = "<span class='crawl'>- Crawled URL: <a href='#{url}'>#{title}</a></span>"
    message = { kind: :crawler, message: message }
    message = { channel: "/scraper/messages", data: message }

    Net::HTTP.post_form faye, message: message.to_json
  end

  def extract_meaningful_title_from zillow_url, page
    match = zillow_url.match(/\/browse\/homes\/(.*)$/)
    return "<No Title Found>" unless match

    parts = match[1].split("/")
    title  = page.search("title").text
    breads = page.search("ol.zsg-breadcrumbs li").map(&:text)
    breads = breads.join(" > ")

    return "States in United States" if parts.blank?

    match = title.match(/homes on (.*) in/i)
    match = title.match(/in (.*) -/i) unless match
    "#{breads} > #{match[1]}"
  end
end
