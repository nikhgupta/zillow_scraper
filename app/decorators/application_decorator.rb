class ApplicationDecorator < Draper::Decorator

  def item_text_for attribute, suffix = nil
    value  = model.send(attribute)
    suffix = suffix.to_s

    return "--" if value.nil? || value == 0
    return "1 #{suffix.singularize}".strip if value == 1

    formatted = h.number_with_delimiter(value.to_i, delimiter: ",")
    return "#{formatted} #{suffix}".strip if value.to_i == value

    formatted = h.number_with_precision(value, delimiter: ",", precision: 1)
    return "#{formatted} #{suffix}".strip
  end

end
