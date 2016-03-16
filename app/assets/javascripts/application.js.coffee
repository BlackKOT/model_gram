#= require jquery
#= require jquery_ujs
#= require canva
# require_tree .

window.canvas = window.canva()

$ ->
  canvas.init()

  canvas.proceedTablesList window.grid_data.tables
  canvas.proceedRelationsList window.grid_data.rels
  canvas.spacingTables()
