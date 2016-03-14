#= require jquery
#= require jquery_ujs
#= require canva
#= require packer
# require_tree .

window.canvas = window.canva()

$ ->
  canvas.init()

  for table_name, table_attrs of window.grid_data.tables
    canvas.addTable(
      table_name: table_name,
      attributes: table_attrs.attributes
    )

  canvas.proceedRelationsList window.grid_data.rels

  canvas.spacingTables()
