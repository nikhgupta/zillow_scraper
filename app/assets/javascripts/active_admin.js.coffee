#= require active_admin/base
lpad = (value, padding) ->

  zeroes = "0"
  zeroes += "0" for i in [1..padding]

  value = 0 unless value
  (zeroes + value).slice(padding * -1)

update_statistics = (selectors) ->
  $.post "/dashboard/statistics", (data) ->
    html  = "<tr><th>Scraper Status</td><td>#{data.status}</td></tr>"
    html += "<tr><th>Total Pages Processed</td><td>#{lpad data.processed, 5} pages</td></tr>"
    html += "<tr><th>Failed to Process</td><td>#{lpad data.failed, 5} pages</td></tr>"
    html += "<tr><th>Total Pages in Queue</td><td>#{lpad data.enqueued, 5} pages</td></tr>"
    html += "<tr><th>Total Listings in Database</td><td>#{lpad data.items, 5} listings</td></tr>"
    html += "<tr><th>Total Listings in Queue</td><td>#{lpad data.queues.zillow_scraper_listing, 5} listings</td></tr>"
    # html += "<tr><td>Updated at</td><td>#{data.timestamp}</td></tr>"
    for index, selector of selectors
      statbox = $("#{selector} table tbody")
      statbox.html(html) if statbox

update_all_stat_boxes = ->
  boxes = ["#resultsbox #statistics", "#dashboard_stat_box"]
  update_statistics boxes
  setInterval ->
    update_statistics boxes
  , 500

jQuery ->
  window.client = new Faye.Client('http://localhost:9292/faye')

  for index, box in ["statistics", "crawler", "listing"]
    box = $("#resultsbox ##{box}")
    box.scrollTop(box[0].scrollHeight) if box[0]

  update_all_stat_boxes()

  client.subscribe '/scraper/messages', (payload) ->
    box = $("#resultsbox ##{payload.kind}")
    if box[0] && payload.html
      box.find("table tbody").append(payload.html)
      box.scrollTop box[0].scrollHeight
