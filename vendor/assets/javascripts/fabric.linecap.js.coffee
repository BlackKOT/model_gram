#= require fabric.min

fabric.Object::isText = ->
  @get('type') == 'text'

fabric.Object::isTable = ->
  @get('type') == 'table'

fabric.Object::isRelation = ->
  @get('type') == 'lineArrow'

fabric.Table = fabric.util.createClass(fabric.Group,
  type: 'table'
  initialize: (element, options) ->
    options or (options = {})
    element.attrs or (element.attrs = {min_table_width: 100, min_table_height: 100})
    element.name = element.attrs.table_name
    ##########################################################

    start_x = 10
    text_height = 25
    text_padding = 20
    start_y = text_height
    max_width = element.min_table_width

    rect = new fabric.Rect({
      left: 0
      top: 0
      width: element.min_table_width
      height: element.min_table_height
      rx: 10
      ry: 10
      fill: 'rgba(0,0,0,0)'
      stroke: 'black'
      strokeWidth: 3
    })

    table_name = new fabric.Text(element.attrs.table_name, {
      left: start_x
      top: 4
      fontSize: 18
      fontWeight: 'bold'
#      originX: 'center'
#      originY: 'center'
    })

    max_width = Math.max(max_width, table_name.width + text_padding)

    table_field_line = new fabric.Line([0, start_y, element.min_table_width, start_y], {
      fill: 'rgba(0,0,0,0)'
      stroke: 'black'
      strokeWidth: 3
    })

    group_elements = [rect, table_name, table_field_line]

    for field in element.attrs.fields
      table_field_line = new fabric.Line([0, start_y, element.min_table_width, start_y], {
        fill: 'rgba(0,0,0,0)'
        stroke: 'black'
        strokeWidth: 1
      })
      table_field_text = new fabric.Text(field.name, {
        left: start_x
        top: start_y + 4
        fontSize: 18
        fontWeight: 'bold'
      })

      max_width = Math.max(max_width, table_field_text.width + text_padding)
      group_elements.push(table_field_line)
      group_elements.push(table_field_text)
      start_y += text_height


    rect.set({ width: max_width, height: start_y })
    for obj in group_elements
      if !obj.isText()
        obj.set({ width: max_width })

    ##########################################################

    @callSuper 'initialize', group_elements, element
    return

  toObject: ->
    fabric.util.object.extend @callSuper('toObject')
)


fabric.LineArrow = fabric.util.createClass(fabric.Line,
  type: 'lineArrow'
  initialize: (element, options) ->
    options or (options = {})
    @callSuper 'initialize', element, options
    return
  toObject: ->
    fabric.util.object.extend @callSuper('toObject')
  _render: (ctx) ->
    @callSuper '_render', ctx
    # do not render if width/height are zeros or object is not visible
    if @width == 0 or @height == 0 or !@visible
      return
    ctx.save()
    xDiff = @x2 - (@x1)
    yDiff = @y2 - (@y1)
    angle = Math.atan2(yDiff, xDiff)
    ctx.translate (@x2 - (@x1)) / 2, (@y2 - (@y1)) / 2
    ctx.rotate angle
    ctx.beginPath()
    #move 10px in front of line to start the arrow so it does not have the square line end showing in front (0,0)
    ctx.moveTo 5, 0
    ctx.lineTo -10, 8
    ctx.lineTo -10, -8
    ctx.closePath()
    ctx.fillStyle = @stroke
    ctx.fill()
    ctx.restore()
    return
)

fabric.LineArrow.fromObject = (object, callback) ->
  callback and callback(new (fabric.LineArrow)([
    object.x1
    object.y1
    object.x2
    object.y2
  ], object))
  return

fabric.LineArrow.async = true