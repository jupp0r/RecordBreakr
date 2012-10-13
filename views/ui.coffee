$ ->
  $.status = $ ".status"
  $.progressbar = $ "#statusbar"
  $.fresh = true
  initializeRowToggling()
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
  
