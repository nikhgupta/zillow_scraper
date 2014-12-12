class ListingDecorator < ApplicationDecorator
  delegate_all

  def description
    model.description.html_safe
  end

  def link
    h.link_to model.title, model.url
  end
  alias :listing :link

  def realtor_link
    return "--" if realtor_url.blank?
    h.link_to realtor_title, realtor_url
  end
  alias :realtor :realtor_link

  def bedroom suffix = "Beds"
    item_text_for :bedroom, suffix
  end

  def bathroom suffix = "Baths"
    item_text_for :bathroom, suffix
  end

  def area suffix = "sq.ft."
    item_text_for :area, suffix
  end

  def status
    model.status.to_s.titleize
  end

  def price
    return "--" if model.price.to_i == 0
    "$" + h.number_with_delimiter(model.price, delimiter: ',')
  end

  def to_table_row
    fields = %w[link area bedroom bathroom area status price ]
    fields = fields.map{|field| "<td>#{send(field)}</td>"}
    "<tr>#{fields}</tr>"
  end

  def facts
    "#{area} area with #{bedroom(:bedrooms)} and #{bathroom(:bathrooms)}"
  end

  def price_with_status
    return status unless model.price > 0
    "#{status} at #{price}"
  end

  def address
    fields = %w[street neighborhood city state zip]
    fields = fields.map{|field| model.send(field)}.compact
    fields.join(", ")
  end

  def updated
    return "Never" if updated_at.blank?
    h.time_ago_in_words(updated_at) + " ago"
  end
end
