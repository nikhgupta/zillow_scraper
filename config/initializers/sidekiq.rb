require 'sidekiq/api'
# Sidekiq::Priority.priorities = [:godly, :huge, :high, :medium, nil, :low]
Sidekiq::Priority.priorities = [:listing, :street, :zip_code, :county, :state, nil]
ZillowScraper::Queues = Sidekiq::Priority.priorities.map do |priority|
  "zillow_scraper_#{priority}"
end

class Sidekiq::Queue
  def confirm_clear
    clear
    sleep 0.5 while size > 0
  end

  def self.confirm_clear *args
    args.each do |arg|
      self.new(arg.to_s).confirm_clear
    end
  end
end
