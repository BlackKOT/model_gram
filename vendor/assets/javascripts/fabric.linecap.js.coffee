#= require fabric.min

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