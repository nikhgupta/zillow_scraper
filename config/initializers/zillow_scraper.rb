module ZillowScraper
  def self.stop_scraper_and_reset_everything!
    # clear sidekiq queues
    Sidekiq::Queue.confirm_clear(*sidekiq_queues)
    Sidekiq::RetrySet.new.clear
    Sidekiq::ScheduledSet.new.clear

    # clear stats
    Sidekiq::Stats.new.reset
    BLOOM_FILTER.clear

    # clear listings in database
    # Listing.delete_all
  end

  def self.sidekiq_queues
    Sidekiq::Priority.priorities.map do |priority|
      "zillow_scraper_#{priority}"
    end.push("zillow_scraper")
  end
end
