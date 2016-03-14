#= require fabric.linecap
#= require fabric.canvasex
#= require packer


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
  min_canvas_height = 600
  min_table_width = 80
  min_table_height = 120
  canvas = undefined
  projection_line = undefined
  tables = {}


  pointertoRect = (pointer, width = 1, height = 1) ->
    {
      x: pointer.x
      y: pointer.y
      width: width
      height: height
      center: {
        x: pointer.x + width / 2
        y: pointer.y + height / 2
      }
    }



  proceedRelationsList = (rels) ->
    canvas.renderOnAddRemove = false

    for table_name, table_rels of rels
      console.log('--', table_name)
      main_table = (tables[table_name] || {}).obj
      unless main_table
        console.error(table_name + ' is not exists in tables hash')
      else
        for rel_table_name, rel_params of table_rels
          console.log('----', rel_table_name, rel_params)
          rel_table = (tables[rel_table_name] || {}).obj

          unless rel_table
            console.error('is not exists in tables list')
            continue

          unless rel_params
            console.error('did not has relations params')
            continue

          back_rel_type = rels[rel_table_name] && rels[rel_table_name][table_name] &&
            rels[rel_table_name][table_name].rel_type

          main_table_field = rel_table #if (rel_params.rel_type == 'belongs_to') then rel_table else main_table
          rel_table_field = main_table #if (rels[rel_table_name][table_name].rel_type == 'belongs_to') then main_table else rel_table

          if back_rel_type
            console.warn('@ ', rel_table_field.name, rels[rel_table_name][table_name].key)
            rel_table_field = rel_table_field.findFieldByName(rels[rel_table_name][table_name].key || 'id')

            unless (rel_table_field)
              console.error(
                "@ #{(rels[rel_table_name][table_name].key || 'id')} is not finded in table #{rel_table_name}"
              )
              rel_table_field = rel_table

            back_rel_type = cap_styles[rels[rel_table_name][table_name].rel_type]
            # back relation is excluded from hash for preventing duplications of relations
            delete rels[rel_table_name][table_name]
          else
            back_rel_type = cap_styles.none

          console.warn('! ', main_table_field.name, rel_params.key)
          main_table_field = main_table_field.findFieldByName(rel_params.key || 'id')

          unless (main_table_field)
            console.error("! #{(rel_params.key || 'id')} is not finded in table #{table_name}")
            main_table_field = main_table

          registerRelation(rel_table_field, main_table_field, back_rel_type, cap_styles[rel_params.rel_type])

    canvas.renderOnAddRemove = true
    canvas.renderAll()


  isRelationBegan = ->
    canvas.addChild && canvas.addChild.start


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
    toObject = canvas.getFieldInTable(options.target, options)
    if (!toObject || !toObject.isTableField())
      return

    canvas.off 'object:selected', addRelation
    # add the line
    fromObject = canvas.addChild.start

    registerRelation(fromObject, toObject)

    # undefined instead of delete since we are anyway going to do this many times
    cancelRelation()
    return


  registerRelation = (fromObject, toObject, start_cap = cap_styles.has_many, end_cap = cap_styles.belongs_to) ->
    line = new (fabric.RelArrow)([
      {obj: fromObject, rect: toObject.boundingRect()}
      {obj: toObject, rect: fromObject.boundingRect()}
    ],
      start_cap: start_cap
      end_cap: end_cap
      strokeWidth: 3
      selectable: false #TODO: revert me later
      lockMovementX: true
      lockMovementY: true
      lockRotation: true
      lockScalingX: true
      lockScalingY: true
    )

    canvas.add line
    # so that the line is behind the connected shapes
    line.sendToBack()
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



  redrawRelation = (event) ->
    canvas.on event, (options) ->
      object = options.target
      # udpate lines (if any)

      if object.addChild
        if object.addChild.from
          object.addChild.from.forEach (line_obj) ->
            line_obj.line.updateCoords [
              {obj: line_obj.from, rect: line_obj.to.boundingRect()}
              {obj: line_obj.to, rect: line_obj.from.boundingRect()}
            ]

        if object.addChild.to
          object.addChild.to.forEach (line_obj) ->
            line_obj.line.updateCoords [
              {obj: line_obj.from, rect: line_obj.to.boundingRect()}
              {obj: line_obj.to, rect: line_obj.from.boundingRect()}
            ]

#      canvas.renderAll()
    return


  resize = ->
    canvas.setWidth(window.innerWidth)
    canvas.setHeight(Math.max(min_canvas_height, window.innerHeight))
    canvas.calcOffset()
#    calc_grid()


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
    canvas = new fabric.CanvasEx('c', { selection: false, stateful: false })
    canvas.fireEventForObjectInsideGroup = false

#    canvas.on('object:moving', (options) ->
#      options.target.set({
#        left: Math.round(options.target.left / grid) * grid,
#        top: Math.round(options.target.top / grid) * grid
#      })
#    )

    canvas.on('mouse:move', (options) ->
      if (isRelationBegan())
        to_pointer = canvas.getPointer(options.e)

        if (projection_line)
          projection_line.updateCoords [
            {obj: canvas.addChild.start, rect: pointertoRect(to_pointer)}
            {obj: to_pointer, rect: canvas.addChild.start.boundingRect()}
          ]

          canvas.renderAll()
        else
          projection_line = new (fabric.RelArrow)([
            {obj: canvas.addChild.start, rect: pointertoRect(to_pointer)}
            {obj: to_pointer, rect: canvas.addChild.start.boundingRect()}
          ],
            strokeWidth: 1
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
      else unless(isRelationBegan())
        if curr_obj.isTable()
          canvas.bringToFront(curr_obj)
    )

    canvas.on('mouse:dblclick', (options) ->
      if (options.e.which == 3) # right mouse button
        return cancelRelation()

      curr_obj = canvas.getActiveObject();
      curr_obj = canvas.getFieldInTable(curr_obj, options)

      if (curr_obj && curr_obj.isTableField())
        startRelation(curr_obj)
      else
        cancelRelation()
    )

    ['object:moving', 'object:scaling'].forEach(redrawRelation)
    window.addEventListener('resize', resize, false)
    resize()


  spacingTables = ->
    canvas.setHeight(min_canvas_height)
    packer = new Packer(canvas.width, canvas.height)
    tablesPack = Object.keys(tables).map((key) -> tables[key])
    tablesPack.sort((a, b) ->
#      ax = a.w * a.h
#      bx = b.w * b.h

      ax = a.h
      bx = b.h

      if (ax > bx) then return -1
      if (ax < bx) then return 1
      0
    )

    console.log tablesPack
    packer.fit(tablesPack)

    for table in tablesPack
      if table.fit
        table.obj.left = table.fit.x
        table.obj.top = table.fit.y

    canvas.renderAll()


  addTable = (attrs) ->
    table = new fabric.Table({
      min_table_width: min_table_width
      min_table_height: min_table_height
      attrs: attrs
      left: 150
      top: 100
      lockRotation: true
      lockScalingX: true
      lockScalingY: true
#      angle: -10
    })

    canvas.add(table)
    tables[attrs.table_name] = {obj: table, w: table.width, h: table.height}
    min_canvas_height = Math.max(min_canvas_height, table.height + 100)


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
    spacingTables: spacingTables
    proceedRelationsList: proceedRelationsList
  }
