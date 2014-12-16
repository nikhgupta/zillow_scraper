module Faye
  def self.broadcast channel, data
    faye = URI.parse FAYE_SERVER
    message = { channel: channel, data: data }.to_json
    Net::HTTP.post_form faye, message: message
  end
end
