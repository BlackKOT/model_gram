#= require fabric.linecap
#= require fabric.canvasex


fabric.Canvas::getObjectsByName = (name) ->
  objectList = []
  objects = @getObjects()
  i = 0
  len = @size()
  while i < len
    if objects[i].name and objects[i].name == name
      objectList.push objects[i]
    i++
  objectList


fabric.Canvas::getObjectByName = (name) ->
  object = null
  objects = @getObjects()
  i = 0
  len = @size()
  while i < len
    if objects[i].name and objects[i].name == name
      object = objects[i]
      break
    i++
  object


fabric.Canvas::getObjectInGroup = (group, e) ->
  pointer = @canvas.getPointer(e, true)
  i = group.objects.length
  normalizedPointer = @canvas._normalizePointer(this, pointer)
  while i--
    if @canvas._checkTarget(normalizedPointer, group.objects[i])
      return group.objects[i]
  null


window.canva = ->
  grid = 25
  min_table_width = 80
  min_table_height = 120
  canvas = undefined


  getObjectPoint = (object) ->
    object.getCenterPoint()


  drawLine = (fromObject, toObject) ->
    from = getObjectPoint(fromObject)
    to = getObjectPoint(toObject)
    line = new (fabric.LineArrow)([
      from.x
      from.y
      to.x
      to.y
    ],
      fill: 'red'
      stroke: 'red'
      strokeWidth: 4
      selectable: true
      lockMovementX: true
      lockMovementY: true
      lockRotation: true
      lockScalingX: true
      lockScalingY: true
    )

    canvas.add line
    # so that the line is behind the connected shapes
    #    line.sendToBack()
    # add a reference to the line to each object
    fromObject.addChild =
      from: fromObject.addChild and fromObject.addChild.from or []
      to: fromObject.addChild and fromObject.addChild.to
    fromObject.addChild.from.push line
    toObject.addChild =
      from: toObject.addChild and toObject.addChild.from
      to: toObject.addChild and toObject.addChild.to or []
    toObject.addChild.to.push line
    # to remove line references when the line gets removed

    line.addChildRemove = ->
      fromObject.addChild.from.forEach (e, i, arr) ->
        if e == line
          arr.splice i, 1
        return
      toObject.addChild.to.forEach (e, i, arr) ->
        if e == line
          arr.splice i, 1
        return
      return


  addChildLine = (options) ->
    canvas.off 'object:selected', addChildLine
    # add the line
    fromObject = canvas.addChild.start
    toObject = options.target

    drawLine(fromObject, toObject)

    # undefined instead of delete since we are anyway going to do this many times
    canvas.addChild = undefined
    return


  addChildMoveLine = (event) ->
    canvas.on event, (options) ->
      object = options.target
      objectCenter = getObjectPoint(object)
      # udpate lines (if any)
      if object.addChild
        if object.addChild.from
          object.addChild.from.forEach (line) ->
            line.set
              'x1': objectCenter.x
              'y1': objectCenter.y
            return
        if object.addChild.to
          object.addChild.to.forEach (line) ->
            line.set
              'x2': objectCenter.x
              'y2': objectCenter.y
            return
      canvas.renderAll()
      return
    return


  resize = ->
    canvas.setWidth(window.innerWidth)
    canvas.setHeight(window.innerHeight)
    canvas.calcOffset()
    calc_grid()


  calc_grid = ->
    for i in [0...canvas.width / grid]
      yline = new fabric.Line([ i * grid, 0, i * grid, canvas.height], { stroke: '#ccc', selectable: false })
      canvas.add(yline)
      yline.sendToBack()

    for j in [0...canvas.height / grid]
      xline = new fabric.Line([ 0, j * grid, canvas.width, j * grid], { stroke: '#ccc', selectable: false })
      canvas.add(xline)
      xline.sendToBack()



  init = ->
    canvas = new fabric.CanvasEx('c', { selection: false })
#    canvas.fireEventForObjectInsideGroup = true

    canvas.on('object:moving', (options) ->
      options.target.set({
        left: Math.round(options.target.left / grid) * grid,
        top: Math.round(options.target.top / grid) * grid
      })
    )

    canvas.on('mouse:dblclick', (options) ->
      curr_obj = canvas.getActiveObject();
      #if (options.e.which === 3)
      #  console.log('Canvas right mouse down.');

      if (curr_obj)
        addRelation()
    )

    #canvas.observe('mouse:down', (options) ->
    #)

    ['object:moving', 'object:scaling'].forEach(addChildMoveLine)

    window.addEventListener('resize', resize, false)
    resize()

#    canvas.add(new fabric.Rect({
#      left: 100,
#      top: 100,
#      width: 50,
#      height: 50,
#      fill: '#faa',
#      originX: 'left',
#      originY: 'top',
#      centeredRotation: true
#    }));
#
#    canvas.add(new fabric.Circle({
#      radius: 20, fill: 'green', left: 100, top: 100
#    }))


  addRelation = ->
    canvas.addChild = start: canvas.getActiveObject()
    # for when addChild is clicked twice
    canvas.off 'object:selected', addChildLine
    canvas.on 'object:selected', addChildLine


  addTable = (attrs) ->
    canvas.add(new fabric.Table({
      min_table_width: min_table_width
      min_table_height: min_table_height
      attrs: attrs
      left: 150
      top: 100
#      angle: -10
    }))



  removeTable = (name) ->
    object = canvas.getObjectByName(name)
    # remove lines (if any)
    if object.addChild
      if object.addChild.from
        i = object.addChild.from.length - 1
        while i >= 0
          from_line = object.addChild.from[i]
          from_line.addChildRemove()
          from_line.remove()
          i--

      if object.addChild.to
        i = object.addChild.to.length - 1
        while i >= 0
          to_line = object.addChild.to[i]
          to_line.addChildRemove()
          to_line.remove()
          i--
    object.remove()


  return {
    init: init
    addTable: addTable
  }
