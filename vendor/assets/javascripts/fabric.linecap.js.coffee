#= require fabric.min

fabric.Object::isText = ->
  @get('type') == 'text' || @get('type') == 'table_field'

fabric.Object::isTable = ->
  @get('type') == 'table'

fabric.Object::isTableField = ->
  @get('type') == 'table_field'

fabric.Object::isRelation = ->
  @get('type') == 'relArrow'

fabric.Object::boundingRect = ->
  table = @group
  x_offset = if table then table.left else 0
  y_offset = if table then table.top else 0
  mod_width = if table && @isText() then table.width else @width
  mod_height = @height

  {
    x: x_offset + @originalLeft
    y: y_offset + @originalTop
    width: mod_width #* @scaleX # are scale needs ?
    height: mod_height # * @scaleY  # are scale needs ?
    center: {
      x: x_offset + @originalLeft + mod_width / 2
      y: y_offset + @originalTop + mod_height / 2
    }
  }

fabric.TableField = fabric.util.createClass(fabric.Text,
  type: 'table_field'
  initialize: (element, options) ->
    @callSuper 'initialize', element, options
    return

  toObject: ->
    fabric.util.object.extend @callSuper('toObject')
)


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
      fill: 'rgba(255,255,255,192)'
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
      table_field_text = new fabric.TableField(field.name, {
        left: start_x
        top: start_y + 4
        fontSize: 18
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


fabric.RelArrow = fabric.util.createClass(fabric.Object,
  type: 'relArrow'
  bounds: {}
  points: []
  originPoints: []

  initialize: (element, options) ->
    options or (options = {})
    @callSuper 'initialize', options
    @updateBounds(element)
    return


  appendObjectPoints: (object, toRect, add_offset) ->
#    console.log(toRect, object)

    res = if object.name then object.getCenterPoint() else object

    if (object.isText && object.isText())
      rect = object.boundingRect()

      rel_center = toRect.center
      obj_center = rect.center
      offset = 0

      if (rel_center.x <= obj_center.x)
        res.x = rect.x - 12
        offset = -20
      else
        res.x = rect.x + rect.width - 12
        offset = 20

      res.y = rect.y + rect.height / 2

      if add_offset
        if add_offset == 1
          @originPoints.push({x: res.x, y: res.y})
          @originPoints.push({x: res.x + offset, y: res.y})
        else
          @originPoints.push({x: res.x + offset, y: res.y})
          @originPoints.push({x: res.x, y: res.y})

        return

    @originPoints.push({x: res.x, y: res.y})


  updateBounds: (sets) ->
    @originPoints = []
    @bounds = {l: 9999, t: 9999, r: -9999, b: -9999}
    @points = []

    for i in [0...sets.length]
      @appendObjectPoints(
        sets[i].obj,
        sets[i].rect,
        if i == 0 then 1 else if i == (sets.length - 1) then 2 else undefined
      )

    for point in @originPoints
      @bounds.l = Math.min(@bounds.l, point.x)
      @bounds.r = Math.max(@bounds.r, point.x)

      @bounds.t = Math.min(@bounds.t, point.y)
      @bounds.b = Math.max(@bounds.b, point.y)

    w = Math.abs(@bounds.l - @bounds.r) / 2
    h = Math.abs(@bounds.t - @bounds.b) / 2

    for i in [0...@originPoints.length]
      @points.push(
        x: (@originPoints[i].x - @bounds.l) - w
        y: (@originPoints[i].y - @bounds.t) - h
      )

    @updateDimensions()
#    if @canvas
#      @sendToBack()


  updateCoords: (sets) ->
    @updateBounds(sets)


  updateDimensions: ->
    @setLeft(@bounds.l + 5)
    @setTop(@bounds.t + 5)
    @setWidth(Math.abs(@bounds.l - @bounds.r) - 10)
    @setHeight(Math.abs(@bounds.t - @bounds.b) - 10)
    @setCoords()


  toObject: ->
    fabric.util.object.extend @callSuper('toObject')
  _render: (ctx) ->
#    @callSuper '_render', ctx
    # do not render if width/height are zeros or object is not visible

    if !@visible
      return
#
#
    ctx.save()

    ctx.beginPath()
    ctx.moveTo @points[0].x, @points[0].y
    for point in @points[1...]
      ctx.lineTo point.x, point.y

    ctx.stroke()

    point2 = @points[@points.length - 1]
    point1 = @points[@points.length - 2]

    xDiff = point2.x - point1.x
    yDiff = point2.y - point1.y

    angle = Math.atan2(yDiff, xDiff)
    ctx.translate point2.x, point2.y
    ctx.rotate angle

    ctx.beginPath()
    ctx.moveTo 5, 0
    ctx.lineTo -10, 8
    ctx.lineTo -10, -8
    ctx.closePath()

    ctx.fillStyle = @stroke
    ctx.fill()
    ctx.restore()
    return
)

fabric.RelArrow.fromObject = (object, callback) ->
  callback and callback(new (fabric.RelArrow)([
    object.x1
    object.y1
    object.x2
    object.y2
  ], object))
  return

fabric.RelArrow.async = true