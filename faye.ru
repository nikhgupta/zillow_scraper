require 'faye'
Faye::WebSocket.load_adapter('thin')

app = Faye::RackAdapter.new(mount: '/faye', timeout: 25)

run app
