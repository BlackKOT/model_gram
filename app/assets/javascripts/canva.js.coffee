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


fabric.Canvas::getFieldInTable = (table, options) ->
  if (!table || !table.isTable())
    return table

  pointer = @getPointer(options.e, true)
  i = table.size()
  while i--
    item = table.item(i)

    if (item.isText())
      item_rect = item.boundingRect()

      if (pointer.x >= item_rect.x && pointer.x <= item_rect.x + item_rect.width)
        if (pointer.y >= item_rect.y && pointer.y <= item_rect.y + item_rect.height)
          return item
  null


window.canva = ->
  grid = 25
  min_table_width = 80
  min_table_height = 120
  canvas = undefined
  projection_line = undefined


  getObjectPoint = (object) ->
    res = object.getCenterPoint()

    if (object.isText())
      rect = object.boundingRect()
      res.x = rect.x + rect.width / 2
      res.y = rect.y + rect.height / 2

    res


  startRelation = (startObject) ->
    canvas.addChild = start: startObject
    # for when addChild is clicked twice
    canvas.off 'object:selected', addRelation
    canvas.on 'object:selected', addRelation


  cancelRelation = ->
    canvas.addChild = undefined
    canvas.off 'object:selected', addRelation
    if (projection_line)
      canvas.remove(projection_line)
      projection_line = undefined


  addRelation = (options) ->
    canvas.off 'object:selected', addRelation
    # add the line
    fromObject = canvas.addChild.start
    toObject = canvas.getFieldInTable(options.target, options)

    registerRelation(fromObject, toObject)

    # undefined instead of delete since we are anyway going to do this many times
    cancelRelation()
    return


  registerRelation = (fromObject, toObject) ->
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

    fromContainer = if fromObject.group then fromObject.group else fromObject
    toContainer = if toObject.group then toObject.group else toObject


    fromContainer.addChild =
      from: fromContainer.addChild and fromContainer.addChild.from or []
      to: fromContainer.addChild and fromContainer.addChild.to or []
    fromContainer.addChild.from.push {from: fromObject, to: toObject, line: line}

    toContainer.addChild =
      from: toContainer.addChild and toContainer.addChild.from or []
      to: toContainer.addChild and toContainer.addChild.to or []
    toContainer.addChild.to.push {from: fromObject, to: toObject, line: line}

    # to remove line references when the line gets removed

    line.unlink = ->
      fromObject.addChild.from.forEach (e, i, arr) ->
        if e.line == line
          arr.splice i, 1

      toObject.addChild.to.forEach (e, i, arr) ->
        if e.line == line
          arr.splice i, 1

      return



  redrawRelation = (event) -> # need to update checking of line existance
    # at this moment lines existance checked only for table - not for table fields :(
    canvas.on event, (options) ->
      object = options.target
      # udpate lines (if any)

      if object.addChild
        if object.addChild.from
          object.addChild.from.forEach (line_obj) ->
            objectCenter = getObjectPoint(line_obj.from)
            line_obj.line.set
              'x1': objectCenter.x
              'y1': objectCenter.y

        if object.addChild.to
          object.addChild.to.forEach (line_obj) ->
            objectCenter = getObjectPoint(line_obj.to)
            line_obj.line.set
              'x2': objectCenter.x
              'y2': objectCenter.y

      canvas.renderAll()
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
    canvas.fireEventForObjectInsideGroup = true

    canvas.on('object:moving', (options) ->
      options.target.set({
        left: Math.round(options.target.left / grid) * grid,
        top: Math.round(options.target.top / grid) * grid
      })
    )

    canvas.on('mouse:move', (options) ->
      if (canvas.addChild && canvas.addChild.start)
        to_pointer = canvas.getPointer(options.e)
        from_pointer = getObjectPoint(canvas.addChild.start)

        if (projection_line)
          projection_line.set
            'x2': to_pointer.x
            'y2': to_pointer.y
          canvas.renderAll()
        else
          projection_line = new (fabric.LineArrow)([
            from_pointer.x
            from_pointer.y
            to_pointer.x
            to_pointer.y
          ],
            fill: 'red'
            stroke: 'red'
            strokeWidth: 2
            selectable: false
          )
          canvas.add projection_line
    )

    canvas.on('mouse:down', (options) ->
      if (options.e.which == 3) # right mouse button
        return cancelRelation()

      curr_obj = canvas.getActiveObject();
      if (!curr_obj)
        cancelRelation()
    )

    canvas.on('mouse:dblclick', (options) ->
      if (options.e.which == 3) # right mouse button
        return cancelRelation()

      curr_obj = canvas.getActiveObject();
      curr_obj = canvas.getFieldInTable(curr_obj, options)
      console.log(curr_obj)

      if (curr_obj)
        startRelation(curr_obj)
      else
        cancelRelation()
    )

    ['object:moving', 'object:scaling'].forEach(redrawRelation)
    window.addEventListener('resize', resize, false)
    resize()



  addTable = (attrs) ->
    table = new fabric.Table({
      min_table_width: min_table_width
      min_table_height: min_table_height
      attrs: attrs
      left: 150
      top: 100
#      angle: -10
    })

    canvas.add(table)

#    group.addWithUpdate(new fabric.Rect({
#      width: 20,
#      height: 20,
#      fill: 'yellow',
#      left: group.get('left'),
#      top: group.get('top')
#    }));



  removeTable = (name) ->
    object = canvas.getObjectByName(name)
    # remove lines (if any)
    if object.addChild
      if object.addChild.from
        i = object.addChild.from.length - 1
        while i >= 0
          from_line = object.addChild.from[i]
          from_line.unlink()
          from_line.remove()
          i--

      if object.addChild.to
        i = object.addChild.to.length - 1
        while i >= 0
          to_line = object.addChild.to[i]
          to_line.unlink()
          to_line.remove()
          i--
    object.remove()


  return {
    init: init
    addTable: addTable
  }
