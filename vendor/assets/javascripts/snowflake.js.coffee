window.snowflake = ->
  def_link_segment_length = 30
  angleUnit = (limit)-> 6.28 / limit

  #  objs = {
  #    uniq_obj.name: {obj: uniq_obj, w: 100, h: 100, links: [uniq_obj_names]}
  #  }

  update_rects = (rects) ->
    max_rect_width = 0
    max_rect_height = 0
    if (rects.length > 0)
      xcorrection = 0
      ycorrection = 0

      center_rect = rects.shift()
      center_rect_width = center_rect.w
      center_rect_height = center_rect.h
      ycorrection = Math.min(ycorrection, center_rect.y1)

      offsetx = center_rect_width / 2
      offsety = center_rect_height / 2

      for rect in rects
        max_rect_width = Math.max(max_rect_width, rect.w)
        max_rect_height = Math.max(max_rect_height, rect.h)
        ycorrection = Math.min(ycorrection, rect.y1)

      link_width = Math.max(
        offsetx + max_rect_width / 2 + def_link_segment_length,
        offsety + max_rect_height / 2 + def_link_segment_length
      )

      max_rect_width = offsetx + link_width + max_rect_width
      max_rect_height = offsety + link_width + max_rect_height

      # update center rect objs
      ycorrection = Math.abs(ycorrection)

      for obj in center_rect.objs
        obj.x += offsetx
        obj.y += ycorrection
        obj.ch = true

      limit = rects.length
      for i in [0...limit]
        rect = rects[i]
        offsetxx = Math.cos(angleUnit(limit) * i) * link_width + offsetx
        offsetyy = Math.sin(angleUnit(limit) * i) * link_width + offsety + ycorrection

        for obj in rect.objs
          if (obj.ch) then continue;
          obj.x += offsetxx
          obj.y += offsetyy

    {w: max_rect_width, h: max_rect_height}

#  update_rects = (rects) ->
#    max_rect_width = 0
#    max_rect_height = 0
#    if (rects.length > 0)
#      center_rect = rects.shift()
#      center_rect_width = center_rect.w
#      center_rect_height = center_rect.h
#
#      offsetx = center_rect_width / 2
#      offsety = center_rect_height / 2
#
#      for rect in rects
#        max_rect_width = Math.max(max_rect_width, rect.w)
#        max_rect_height = Math.max(max_rect_height, rect.h)
#
#      link_width = Math.max(
#        offsetx + max_rect_width / 2 + def_link_segment_length,
#        offsety + max_rect_height / 2 + def_link_segment_length
#      )
#
#      max_rect_width = offsetx + link_width + max_rect_width
#      max_rect_height = offsety + link_width + max_rect_height
#
#
#      # update center rect objs
#
#      for obj in center_rect.objs
#        obj.x += offsetx
#        obj.y += offsety
#
#
#      # update other rects objs
#      limit = rects.length
#      for i in [0...limit]
#        rect = rects[i]
#        offsetx = Math.cos(angleUnit(limit) * i) * link_width
#        offsety = Math.sin(angleUnit(limit) * i) * link_width
#
#        for obj in rect.objs
#          obj.x += offsetx
#          obj.y += offsety
#
#    {w: max_rect_width, h: max_rect_height}



  pack = (objs) ->
    sortir = {}
    rects = []
#    arr = prepare_hash(objs)

    for key, attrs of objs
      sortir[attrs.links.length] or (sortir[attrs.links.length] = [])
      sortir[attrs.links.length].push(attrs) # need to sort by height

    for key in Object.keys(sortir).reverse()
      for obj in sortir[key]
        rect = bubling(objs, obj, {x: -obj.w / 2, y: -obj.h / 2}, {x1: 99999, y1: 99999, x2: -99999, y2: -99999, objs: []})
        if (rect.objs.length > 0)
          rect.w = rect.x2 - rect.x1
          rect.h = rect.y2 - rect.y1
          rects.push(rect)


    max_rect = update_rects(rects)
    return { w: max_rect.w, h: max_rect.h, objs: objs }


  bubling = (hashes, attrs, point, rect) ->
    unless attrs.x
      rect.objs.push(attrs)

      rect.x1 = Math.min(rect.x1, point.x)
      rect.y1 = Math.min(rect.y1, point.y)

      rect.x2 = Math.max(rect.x2, point.x + attrs.w)
      rect.y2 = Math.max(rect.y2, point.y + attrs.h)

      attrs.x = point.x
      attrs.y = point.y
    else
      point.x = attrs.x
      point.y = attrs.y

    limit = attrs.links.length # need to add + 1 node for ignoring direction of linking with parent
    centerx = point.x
    centery = point.y
    radius = Math.max(attrs.w, attrs.h) + def_link_segment_length * limit

    for i in [0...attrs.links.length]
      # if direction to parent link then continue # need t oprecalc points for exclusion of some
      obj = hashes[attrs.links[i]]
      unless obj.x
#        sec_table_radius = def_link_segment_length * obj.links.length + Math.max(obj.w, obj.h) / 2
        bubling(
          hashes
          hashes[attrs.links[i]]
          {
            x: Math.cos(angleUnit(limit) * i) * radius + centerx - obj.w / 2,
            y: Math.sin(angleUnit(limit) * i) * radius + centery - obj.h / 2
          }
          rect
        )

    rect


  return {
    pack: pack
  }


#    tablesPack.sort((a, b) ->
#      ax = a.h
#      bx = b.h
#
#      if (ax > bx) then return -1
#      if (ax < bx) then return 1
#      0
#    )