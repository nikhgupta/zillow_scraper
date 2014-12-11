#= require active_admin/base
lpad = (value, padding) ->

  zeroes = "0"
  zeroes += "0" for i in [1..padding]

  value = 0 unless value
  (zeroes + value).slice(padding * -1)

update_statistics = ->
  statbox = $("#resultsbox #statistics table tbody")
  $.post "/dashboard/statistics", (data) ->
    html  = "<tr><th>Total Pages Processed</td><td>#{lpad data.processed, 5} pages</td></tr>"
    html += "<tr><th>Failed to Process</td><td>#{lpad data.failed, 5} pages</td></tr>"
    html += "<tr><th>Total Pages in Queue</td><td>#{lpad data.enqueued, 5} pages</td></tr>"
    html += "<tr><th>Total Listings Scraped</td><td>#{lpad data.items, 5} listings</td></tr>"
    html += "<tr><th style='border: none'>Total Listings in Queue</td><td style='border: none'>#{lpad data.queues.zillow_scraper_listing, 5} listings</td></tr>"
    # html += "<tr><td>Updated at</td><td>#{data.timestamp}</td></tr>"
    statbox.html(html)

jQuery ->
  window.client = new Faye.Client('http://localhost:9292/faye')

  boxes = ["statistics", "crawler", "listing"]
  boxes = ($("#resultsbox ##{box}") for box in boxes)
  box.scrollTop(box[0].scrollHeight) for box in boxes

  update_statistics()

  setInterval ->
    update_statistics()
  , 500

  client.subscribe '/scraper/messages', (payload) ->
    box = $("#resultsbox ##{payload.kind}")
    if payload.message
      box.append("<br>" + payload.message)
      box.scrollTop box[0].scrollHeight
