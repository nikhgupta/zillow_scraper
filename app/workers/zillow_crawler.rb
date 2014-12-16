class ZillowCrawler
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
      link =~ /\/b\// || ( link.include?(url) && link != url )
    end.each do |link|
      priority = job_priority_for(link)
      self.class.perform_with_priority priority, link
    end

    # listings
    links.select do |link|
      link =~ /\/homedetails\//
    end.each do |link|
      ListingsScraper.perform_with_priority :listing, link
    end

    # update faye
    broadcast_crawl url, page
  end

  private

  def job_priority_for url
    match = url.match(/\/browse\/homes\/(.*)$/)
    return :street unless match
    parts = match[1].split("/")
    case parts.length
    when 1 then :state
    when 2 then :county
    when 3 then :zip_code
    when 4 then :street
    end
  end

  def broadcast_crawl url, page
    title    = extract_meaningful_title_from(url, page)
    (5 - title.length).times{ title.push("&nbsp; " * 5) }

    message  = "<tr>"
    message += "<td><a href='#{url}'>#{page.search("title").text.gsub(/ - Zillow$/, '')}</a></td>"
    message += "<td>#{title.join("</td><td>")}</td>"
    message += "</tr>"

    data  = { kind: :listing, html: listing.decorate.to_table_row }
    Faye.broadcast "/scraper/messages", data
  end

  def extract_meaningful_title_from zillow_url, page
    match = zillow_url.match(/\/browse\/homes\/(.*)$/)
    return ["APARTMENT"] unless match

    parts = match[1].split("/")
    title  = page.search("title").text
    breads = page.search("ol.zsg-breadcrumbs li").map(&:text)
    # breads = breads.join(" > ")

    return [ "United States" ] if parts.blank?

    match = title.match(/homes on (.*) in/i)
    match = title.match(/in (.*) -/i) unless match
    breads.push(match[1])
    # "#{breads} > #{match[1]}"
  end
end
