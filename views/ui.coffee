$ ->
  $.status = $ ".status"
  $.progressbar = $ "#statusbar"
  $.fresh = true
  initializeRowToggling()
  initializeToolTips()
  updateStatusBar()

updateStatusBar = ->
  $.getJSON "progress", (data)->
    $.progressbar.attr "value", data.complete
    $.progressbar.attr "max", data.incomplete + data.complete
    if data.incomplete > 0
      $.blockUI(message: $.status) if $.fresh
      $.fresh = false
      setTimeout updateStatusBar, 3000
    else
      $.unblockUI()
      location.reload() unless $.fresh

initializeRowToggling = ->
  $('.day-record.row').bind('click', toggleRows)

toggleRows = (event) ->
  row_interval = $(this).attr("data-interval")
  $.each $(".day-item.row[data-interval=\"#{row_interval}\"]"), (index, elem) ->
    $(elem).toggle()
  
initializeToolTips = ->
  $("table.topten a").tooltip
    bodyHandler: ->
      uri = $(this).attr("data-uri")
      $(".tooltip[data-uri=\"#{uri}\"]").html()
    showURL: false
    showBody: " - "
    track: true
