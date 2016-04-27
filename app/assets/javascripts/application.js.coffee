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


  $('#save_schema').on 'click', ->
    json = canvas.save()
    canvas.load(json)

  $('body').on 'change', '.table_marks', ->
    states = {}
    $('.table_marks').each((i, e) ->
      states[$(e).val()] = $(e).is(':checked')
      true
    )
    canvas.limitateRelationVisibility($(@).val(), states)
