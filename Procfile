web: thin start -e production -p 36794
faye: rackup faye.ru -s thin -E production -p 36795
sidekiq: bundle exec sidekiq -C config/sidekiq.yml
