$ ->
  $.progressbar = $("progress#statusbar")
  $.progressbar.hide()
  $.fresh = true
  updateStatusBar()

updateStatusBar = ->
  $.getJSON "progress", (data)->
    $.progressbar.attr "value", data.complete
    $.progressbar.attr "max", data.incomplete + data.complete
    if data.incomplete > 0
      $.fresh = false
      setTimeout updateStatusBar, 3000
      $.progressbar.show()
    else
      location.reload() unless $.fresh
