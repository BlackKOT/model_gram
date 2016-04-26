#= require fabric.linecap
#= require fabric.canvasex
#= require snowflake

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
  table_aliases = {}
  relations = {}

  save = ->
    JSON.stringify(canvas)

  load = (json) ->
    canvas.loadFromJSON json, ->
      alert ' this is a callback. invoked when canvas is loaded! '

  objIsArray = (obj) ->
    obj instanceof Array

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

    # prepare polymorph relations :(
    for _, trels of rels
      for rtable_name, trel of trels
        unless tables[rtable_name]
          if table_aliases[rtable_name]
            proto = trel
            proto.poly = true

            for alias in table_aliases[rtable_name]
              trels[alias] = proto

            delete trels[rtable_name]
    ######################################


    for table_name, table_rels of rels
#      console.log('--', table_name)
      main_table = (tables[table_name] || {}).obj
      unless main_table
        console.error(table_name + ' is not exists in tables hash')
      else
        for rel_table_name, rel_params of table_rels
#          console.log('----', rel_table_name, rel_params)
          rel_table = (tables[rel_table_name] || {}).obj
          to_yourself = false

          unless rel_table
            console.error('is not exists in tables list')
            continue

          unless rel_params
            console.error('did not has relations params')
            continue

          unless objIsArray(rel_params) then rel_params = [rel_params]
          for rel in rel_params
            back_rel_type = if rel_table_name == table_name
              'belongs_to'
            else
              rels[rel_table_name] && rels[rel_table_name][table_name] &&
              rels[rel_table_name][table_name].rel_type

            main_table_field = rel_table #if (rel.rel_type == 'belongs_to') then rel_table else main_table
            rel_table_field = main_table #if (rels[rel_table_name][table_name].rel_type == 'belongs_to') then main_table else rel_table

            if back_rel_type
  #            console.warn('@ ', rel_table_field.name, rels[rel_table_name][table_name].key)
              rel_table_field = rel_table_field.findFieldByName(rels[rel_table_name][table_name].key || 'id')

              unless (rel_table_field)
  #              console.error(
  #                "@ #{(rels[rel_table_name][table_name].key || 'id')} is not finded in table #{rel_table_name}"
  #              )
                rel_table_field = rel_table

              back_rel_type = cap_styles[back_rel_type]
              if rels[rel_table_name][table_name].poly
                back_rel_type |= cap_styles['poly']
              # back relation is excluded from hash for preventing duplications of relations
              unless rel_table_name == table_name
                delete rels[rel_table_name][table_name]
              else
                to_yourself = true
            else
              back_rel_type = cap_styles.none

  #          console.warn('! ', main_table_field.name, rel.key)
            main_table_field = main_table_field.findFieldByName(rel.key || 'id')

            unless (main_table_field)
  #            console.error("! #{(rel.key || 'id')} is not finded in table #{table_name}")
              main_table_field = main_table

            registerRelation(rel_table_field, main_table_field, back_rel_type, cap_styles[rel.rel_type] | if rel.poly then cap_styles['poly'] else 0)

    canvas.renderOnAddRemove = true
    canvas.renderAll()


  limitateRelationVisibility = (name, states) ->
    for relation_name, object of relations
      if relation_name == name

        object.obj.addChild.from.forEach (line_obj) ->
#          console.log(line_obj.to.group.name)
          line_obj.line.visible = states[line_obj.to.group.name]

        object.obj.addChild.to.forEach (line_obj) ->
          line_obj.line.visible = states[name]

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


  registerRelation = (fromObject, toObject, start_cap = cap_styles.belongs_to, end_cap = cap_styles.has_many) ->
    fObject = if fromObject.isTable() then fromObject else fromObject.group
    tObject = if toObject.isTable() then toObject else toObject.group
    relations[fObject.name].links.push(tObject.name)
    relations[tObject.name].links.push(fObject.name)

    line = new (fabric.RelArrow)([
      {obj: fromObject, rect: toObject.boundingRect()}
      {obj: toObject, rect: fromObject.boundingRect()}
    ],
      start_cap: start_cap
      end_cap: end_cap
      strokeWidth: 2
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


  redrawRelationForObject = (object) ->
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


  redrawRelation = (event) ->
    canvas.on event, (options) ->
      redrawRelationForObject(options.target)


  resize = (o, w, h) ->
    canvas.setWidth(w ||= window.innerWidth)
    canvas.setHeight(h ||= Math.max(min_canvas_height, window.innerHeight))
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
    res = snowflake().pack(canvas, relations)
    console.log(res)
    resize(undefined, res.w, res.h)
    for key, attrs of res.objs
      attrs.obj.set({left: attrs.x, top: attrs.y})
      attrs.obj.setCoords()
      redrawRelationForObject(attrs.obj)

    canvas.renderAll()


  proceedTablesList = (hash) ->
    for table_name, table_attrs of hash
      if objIsArray(table_attrs)
        table_aliases[table_name] = table_attrs
      else
        addTable(
          table_name: table_name,
          attributes: table_attrs.attributes
        )


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
    relations[table.name] = {obj: table, w: table.width, h: table.height, links: []}
    min_canvas_height = Math.max(min_canvas_height, table.height + 100)

    $checkbox = $("<input type='checkbox' class='table_marks' value='#{attrs.table_name}' checked>#{attrs.table_name}")
    $('.tables_list').append($("<div>#{attrs.table_name}</div>").prepend($checkbox));

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
    proceedTablesList: proceedTablesList
    proceedRelationsList: proceedRelationsList
    limitateRelationVisibility: limitateRelationVisibility
    save: save
    load: load
  }
