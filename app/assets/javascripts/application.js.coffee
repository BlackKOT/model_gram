#= require jquery
#= require jquery_ujs
#= require canva
# require_tree .

window.json = undefined
window.canvas = window.canva()

$ ->
  canvas.init()

  canvas.proceedTablesList window.grid_data.tables
  canvas.proceedRelationsList window.grid_data.rels
  canvas.spacingTables()

  $('#save_schema').on 'click', ->
    window.json = canvas.save()

  $('#load_schema').on 'click', ->
    canvas.load(window.json)
    console.log window.json
