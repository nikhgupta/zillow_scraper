if Rails.env.production?
  FAYE_SERVER = "http://#{ENV['ZILLOW_FAYE_HOST']}/faye"
else
  FAYE_SERVER = "http://localhost:9292/faye"
end
