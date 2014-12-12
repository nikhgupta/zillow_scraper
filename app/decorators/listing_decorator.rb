class ListingDecorator < ApplicationDecorator
  delegate_all

  def link
    h.link_to model.title, model.url
  end

  def realtor_link
    return "--" if realtor_url.blank?
    h.link_to realtor_title, realtor_url
  end

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
    model.status.titleize
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
end
