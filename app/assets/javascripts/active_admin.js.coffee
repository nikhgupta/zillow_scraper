#= require active_admin/base

jQuery ->
  window.client = new Faye.Client('http://localhost:9292/faye')
  client.subscribe '/scraper/messages', (message) ->
    console.log message
    $("#resultsbox").append("<br>" + message) if message
