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
    start_x = 10
    start_y = 25
    text_height = 25

    rect = new fabric.Rect({
      left: 0
      top: 0
      width: min_table_width
      height: min_table_height
      rx: 10
      ry: 10
      fill: 'rgba(0,0,0,0)'
      stroke: 'black'
      strokeWidth: 3
    })
    table_name = new fabric.Text(attrs.name, {
      left: start_x
      top: 4
      fontSize: 18
      fontWeight: 'bold'
#      originX: 'center'
#      originY: 'center'
    })

    table_field_line = new fabric.Line([0, start_y, min_table_width, start_y], {
      fill: 'rgba(0,0,0,0)'
      stroke: 'black'
      strokeWidth: 3
    })

    group_elements = [rect, table_name, table_field_line]

    for field in attrs.fields
      table_field_line = new fabric.Line([0, start_y, min_table_width, start_y], {
        fill: 'rgba(0,0,0,0)'
        stroke: 'black'
        strokeWidth: 1
      })
      table_field_text = new fabric.Text(field.name, {
        left: start_x
        top: start_y + 4
        fontSize: 18
        fontWeight: 'bold'
#        originX: 'center'
  #      originY: 'center'
      })

      group_elements.push(table_field_line)
      group_elements.push(table_field_text)
      start_y += text_height


    canvas.add(new fabric.Group(group_elements, {
      name: name,
      left: 150,
      top: 100,
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
