#= require active_admin/base

jQuery ->
  window.client = new Faye.Client('http://localhost:9292/faye')
  window.resultbox = $("#resultsbox")
  client.subscribe '/scraper/messages', (message) ->
    if message
      resultbox.append("<br>" + message)
      resultbox.scrollTop resultbox[0].scrollHeight
