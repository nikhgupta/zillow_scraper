Mechanize::AGENT = Mechanize.new do |agent|
  agent.user_agent_alias = 'Mac Safari'
  agent.open_timeout = 5
  agent.read_timeout = 25
end
