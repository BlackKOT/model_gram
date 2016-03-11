#= require fabric.min

window.cap_styles = {none: 1, belongs_to: 2, mandatory: 4, has_many: 8, non_mandatory: 16, transitional: 32}
window.cap_styles.through = cap_styles.transitional | cap_styles.has_many

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
      y: (y_offset + @originalTop + mod_height / 2)
    }
  }

fabric.TableField = fabric.util.createClass(fabric.Text,
  type: 'table_field'
  initialize: (element, options) ->
    @callSuper 'initialize', element, options
    @name = element
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

    for fname, params of element.attrs.attributes
      table_field_line = new fabric.Line([0, start_y, element.min_table_width, start_y], {
        fill: 'rgba(0,0,0,0)'
        stroke: 'black'
        strokeWidth: 1
      })
      table_field_text = new fabric.TableField(fname, {
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

  findFieldByName: (name) ->
    i = @size()
    while i--
      item = @item(i)

      if (item.isTableField())
        if item.name and item.name == name
          return item

    undefined
)


fabric.RelArrow = fabric.util.createClass(fabric.Object,
  type: 'relArrow'
  bounds: {}
  points: []
  originPoints: []
  rel_start_type: cap_styles.none
  rel_end_type: cap_styles.none
  tail_width: 20
  tail_height: 8


  initialize: (element, options) ->
    options or (options = {})

    @rel_start_type = if options.start_cap then options.start_cap else (cap_styles.non_mandatory | cap_styles.belongs_to)
    @rel_end_type = if options.end_cap then options.end_cap else (cap_styles.mandatory | cap_styles.has_many)

    @callSuper 'initialize', options
    @updateBounds(element)
    return


  appendObjectPoints: (object, toRect, add_offset) ->
    res = if object.name then object.getCenterPoint() else object

    if (object.isText && object.isText())
      rect = object.boundingRect()

      rel_center = toRect.center
      obj_center = rect.center
      offset = 0

      if (rel_center.x <= obj_center.x)
        res.x = rect.x - 12
        offset = -@tail_width
      else
        res.x = rect.x + rect.width - 12
        offset = @tail_width

      res.y = rect.y + rect.height / 2 - 4 # - 4 is text padding

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


  updateCoords: (sets) ->
    @updateBounds(sets)


  updateDimensions: -> # add paddings
    @setLeft(@bounds.l + 5)
    @setTop(@bounds.t + 5)
    @setWidth(Math.abs(@bounds.l - @bounds.r) - 10)
    @setHeight(Math.abs(@bounds.t - @bounds.b) - 10)
    @setCoords()


  drawCap: (ctx, capType, point1, point2) ->
    xDiff = point2.x - point1.x
    yDiff = point2.y - point1.y

    angle = Math.atan2(yDiff, xDiff)

    if capType & cap_styles.belongs_to
      ctx.save()
      ctx.translate point2.x, point2.y
      ctx.rotate angle
      ctx.beginPath()
      ctx.moveTo 2, 0
      ctx.lineTo -@tail_width / 2, @tail_height
      ctx.lineTo -@tail_width / 2, -@tail_height
      ctx.closePath()
#      ctx.strokeStyle = @stroke
#      ctx.stroke()
      ctx.fillStyle = @stroke
      ctx.fill()
      ctx.restore()

    if capType & cap_styles.mandatory
      ctx.save()
      ctx.translate point2.x, point2.y
      ctx.rotate angle
      ctx.beginPath()
      ctx.moveTo -@tail_width / 2, @tail_height
      ctx.lineTo -@tail_width / 2, -@tail_height
      ctx.strokeStyle = @stroke
      ctx.stroke()
      ctx.restore()

    if capType & cap_styles.non_mandatory
      ctx.save()
      ctx.translate point2.x, point2.y
      ctx.rotate angle
      ctx.beginPath()
      ctx.arc -@tail_width / 1.2, 0, @tail_width / 4, 0, 2 * Math.PI, false
      ctx.strokeStyle = @stroke
      ctx.stroke()
      ctx.fillStyle = 'rgba(255,255,255,255)'
      ctx.fill()
      ctx.restore()

    if capType & cap_styles.has_many
      ctx.save()
      ctx.translate point2.x, point2.y
      ctx.rotate angle
      ctx.beginPath()
      ctx.moveTo -@tail_width / 2, 0
      ctx.lineTo 0, @tail_height
      ctx.moveTo -@tail_width / 2, 0
      ctx.lineTo 0, -@tail_height
      ctx.moveTo -@tail_width / 2, 0
      ctx.lineTo 0, 0
      ctx.strokeStyle = @stroke
      ctx.stroke()
      ctx.restore()


  toObject: ->
    fabric.util.object.extend @callSuper('toObject')
  _render: (ctx) ->
#    @callSuper '_render', ctx
    # do not render if width/height are zeros or object is not visible

    if !@visible
      return

    ctx.save()

    if @rel_start_type & cap_styles.transitional || @rel_end_type & cap_styles.transitional
      @fill = 'blue'
      @stroke = 'blue'
      ctx.setLineDash([5, 5])
    else
      @fill = 'red'
      @stroke = 'red'

    ctx.beginPath()
    ctx.moveTo @points[0].x, @points[0].y
    for point in @points[1...]
      ctx.lineTo point.x, point.y

    ctx.stroke()
    ctx.restore()

    @drawCap(ctx, @rel_start_type, @points[1], @points[0])
    @drawCap(ctx, @rel_end_type, @points[@points.length - 2], @points[@points.length - 1])

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