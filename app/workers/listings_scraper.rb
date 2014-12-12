class ListingsScraper
  include Sidekiq::Worker

  sidekiq_options queue: :zillow_scraper

  def perform url
    page = Mechanize::AGENT.get url
    property_id = page.search("li#save-menu").attr("data-zpid").text.strip.to_i

    main = page.search("#hdp-content div.notranslate")[0]
    description = main.text.strip
    unwanted_el = main.elements.last
    description = description.gsub(unwanted_el.text, '').strip if unwanted_el

    selector = ".zsg-content-header .addr_bbs"
    bedroom, bathroom, area = page.search(selector).map do |el|
      el.text.strip.gsub(/[^\d+\.]/, '').to_f
    end

    status = page.search("#listing-icon").attr("data-icon-class").text.gsub(/^zsg-icon-/, '').titleize
    price  = page.search(".estimates .main-row").text
    price  = price.match(/\$((\d+\,)*\d+)\s*/)
    price  = price ? price[1].gsub(/[^\d+]/, '').to_i : 0

    state, city, neighborhood, _ = page.search("ol.zsg-breadcrumbs li").map{|a| a.text.strip}
    location = page.search(".addr h1")
    zip_code = location.search("span.addr_city").remove
    street   = location.text.gsub(/\,\s*$/, '').strip
    zip_code = zip_code.text.strip.gsub(/[^\d+]/, '')
    city = nil if city =~ /^\d+$/

    realtor_url, realtor_title = find_realtor(page)

    ActiveRecord::Base.transaction do
      listing = Listing.find_or_create_by(property_id: property_id)
      listing.update_attributes({
        url: url,
        realtor_url: realtor_url,
        realtor_title: realtor_title,
        description: description,

        bedroom: bedroom,
        bathroom: bathroom,
        area: area,
        price: price,
        status: status,

        state: state,
        city: city,
        neighborhood: neighborhood,
        zip: zip_code,
        street: street
      })
    end

    # update faye
    broadcast_listing url, page
  end

  private

  def find_realtor(page)
    regex = /ajaxURL:\"(.*?)\",divId:\"listing-provided-by-module\"/
    data  = page.body.scan(/k\.load\((.*?)\);/).flatten
    data  = data.detect{|a| a.include?("listing-provided-by-module")}
    return if data.blank?

    data = data.match(regex)
    url  = data[1]
    return if url.blank?

    page = Mechanize::AGENT.get(url)
    data = JSON.parse page.body

    html = Nokogiri::HTML(data["html"])
    el   = html.search("a.listing-website-track-link")
    link = URI.decode(el.attr("href").text.match(/\&url=(.*)$/)[1]) rescue nil

    [ link, el.text ]
  end

  def find_status(selector, statuses)
    classes = page.search(selector).children.map{|a| a.attr("class")}
    classes = classes.compact.join(" ")
    classes = classes.gsub(/\s*(-row|template|hide)/, '')
    classes = classes.split(" ").compact.uniq

    statuses.detect{|klass| classes.include?(klass)}.to_s.titleize
  end

  def broadcast_listing url, page
    faye    = URI.parse "http://localhost:9292/faye"

    title   = page.search("title").text.gsub(/ - Zillow$/, '')
    message = "<span class='listings'>- Found Listing: <a href='#{url}'>#{title}</a></span>"
    message = { kind: :listing, message: message }
    message = { channel: "/scraper/messages", data: message }

    Net::HTTP.post_form faye, message: message.to_json
  end
end
