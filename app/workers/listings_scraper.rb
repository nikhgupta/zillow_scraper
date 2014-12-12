# A sidekiq worker to crawl various webpages on Zillow.com.
#
# If the web pages found are not a listing, they are queued at the end of this
# worker, otherwise, they are sent to the ListingsScraper worker.
#
# Web pages are crawled on priority basis, such that a DFS crawl is initiated.
# Pages that respond to a street have higher priority than zips, cities,
# counties or states, and so on respectively. This allows us to fetch listings
# details very early, as opposed to a BFS alogirthm.
#
class ListingsScraper
  include Sidekiq::Worker

  sidekiq_options queue: :zillow_scraper

  def perform url
    page    = Mechanize::AGENT.get url
    data    = extract_listing_details(url, page)
    listing = migrate_listing_with_data(data)
    broadcast_listing listing
  end

  private

  def extract_listing_details(url, page)
    @tmp, @url, @page = {url: url}, url, page

    fields  = %w[ property_id title description bedroom bathroom area ]
    fields |= %w[ status price city state neighborhood street zip ]
    fields |= %w[ url realtor_url realtor_title ]

    return if rental_listing?

    groups  = %w[ location bed_bath_area realtor]
    groups.map{|group| send("extract_#{group}_fields")}

    fields = fields.map(&:to_sym).map do |field|
      value  = @tmp[field] if @tmp.has_key?(field)
      method = "extract_field_#{field}"
      value  = send(method) if value.nil? && respond_to?(method, true)
      [field, value]
    end

    Hash[fields]
  end

  def rental_listing?
    extract_field_status == :for_rent
  end

  def extract_field_property_id
    @page.search("li#save-menu").attr("data-zpid").text.strip.to_i
  end

  def extract_field_title
    @page.search("title").text.gsub(/ - Zillow$/, '')
  end

  def extract_field_description
    main  = @page.search("#hdp-content div.notranslate")[0]
    desc  = main.text.strip if main.elements.blank?
    desc  = main.text.gsub(main.elements.last.text, '').strip unless desc
    desc  = "<p>#{desc}</p>"
    desc += @page.search(".hdp-facts .top-facts").map do |node|
      node.inner_html.gsub(/\s*class=".*?"/, '').gsub(/\n+/, '')
    end.join
  end

  def extract_field_status
    return @tmp[:status] if @tmp[:status]
    @tmp[:status] = @page.search("#listing-icon").attr("data-icon-class")
    @tmp[:status] = @tmp[:status].text.gsub(/^zsg-icon-/, '')
    @tmp[:status] = @tmp[:status].parameterize.underscore.to_sym
  end

  def extract_field_price
    price  = @page.search(".estimates .main-row").text
    price  = price.match(/\$((\d+\,)*\d+)\s*/)
    price ? price[1].gsub(/[^\d+]/, '').to_i : 0
  end

  def extract_bed_bath_area_fields
    selector = ".zsg-content-header .addr_bbs"

    fields = @page.search(selector).map do |field|
      field = field.text.split(" ")
      [ field[1].singularize.to_sym, field[0].gsub(/[^\d+\.]/, '').to_f]
    end

    fields = Hash[fields]
    fields = fields[:bed], fields[:bath], fields[:sqft]
    @tmp[:bedroom], @tmp[:bathroom], @tmp[:area] = fields
  end

  def extract_location_fields
    fields = @page.search("ol.zsg-breadcrumbs li").map{|a| a.text.strip}
    state, city, neighborhood, _ = fields

    location = @page.search(".addr h1")
    zip_code = location.search("span.addr_city").remove.text.strip
    street   = location.text.gsub(/\,\s*$/, '').strip

    city     = zip_code.gsub(/\,\s+[A-Z]{2}\s+\d+$/, '') if city =~ /^\d+$/
    city     = nil if city == zip_code
    zip_code = zip_code.gsub(/[^\d+]/, '')
    neighborhood = nil if neighborhood == street

    @tmp = @tmp.merge({
      street: street, zip: zip_code,
      neighborhood: neighborhood,
      city: city, state: state
    })
  end

  def extract_realtor_fields
    regex = /ajaxURL:\"(.*?)\",divId:\"listing-provided-by-module\"/
    data  = @page.body.scan(/k\.load\((.*?)\);/).flatten
    data  = data.detect{|a| a.include?("listing-provided-by-module")}
    return if data.blank?

    data = data.match(regex)
    url  = data[1]
    return if url.blank?

    page = Mechanize::AGENT.get(url)
    data = JSON.parse page.body

    html = Nokogiri::HTML(data["html"])
    el   = html.search("a.listing-website-track-link")
    return if el.blank?

    link = el.attr("href").text.match(/\&url=(.*)$/)
    link = URI.decode(link[1]).to_s if link

    @tmp[:realtor_url], @tmp[:realtor_title] = [ link, el.text ] if link
  end

  def migrate_listing_with_data(data)
    property_id = data.delete(:property_id)

    ActiveRecord::Base.transaction do
      listing = Listing.find_or_create_by(property_id: property_id)
      listing.update_attributes(data)
      listing
    end
  end

  def broadcast_listing listing
    data  = { kind: :listing, html: listing.decorate.to_table_row }
    Faye.broadcast "/scraper/messages", data
  end
end
