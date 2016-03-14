window.snowflake = ->
  def_link_segment_length = 20

  getIndexIfObjWithOwnAttr = (hash, value) ->
    i = 0
    for key in Object.keys(hash)
      if key == value
        return i
      i++
    -1

#  getIndexIfObjWithOwnAttr = (array, attr, value) ->
#    i = 0
#    while i < array.length
#      if array[i].hasOwnProperty(attr) and array[i][attr] == value
#        return i
#      i++
#    -1


#  prepare_hash = (hash) ->
#    res = []
#    for obj, attrs of hash
#      res.push(attrs)
#      new_links = []
#      for link in attrs.links
#        index = getIndexIfObjWithOwnAttr(hash, link)
#        if (index == -1)
#          console.log('Pidec')
#        else
#          new_links.push(index)
#
#      res[res.length - 1].links = new_links
#    res


  #  objs = {
  #    uniq_obj.name: {obj: uniq_obj, w: 100, h: 100, links: [uniq_obj_names]}
  #  }

  pack = (objs) ->
    sortir = {}
    rects = []
#    arr = prepare_hash(objs)

    for key, attrs of objs
      sortir[attrs.links.length] or (sortir[attrs.links.length] = [])
      sortir[attrs.links.length].push(attrs) # need to sort by height

    for key in Object.keys(sortir).reverse()
      for obj in sortir[key]
        rect = bubling(objs, obj, {x: obj.w / 2, y: obj.h / 2}, {x1: 99999, y1: 99999, x2: -99999, y2: -99999, objs: []})
        if (rect.objs.length > 0)
          rect.max = {w: rect.x2 - rect.x1, h: rect.y2 - rect.y1}
          rects.push(rect)



    max_rect_width = 0
    max_rect_height = 0
    if (rects.length > 0)
      center_rect = rects.shift()
      center_rect_width = center_rect.max.w
      center_rect_height = center_rect.max.h

      link_width = Math.max(center_rect_width, center_rect_height) + 30

      limit = rects.length
      angleUnit = 6.28 / limit

      for rect in rects
        max_rect_width = Math.max(max_rect_width, rect.max.w)
        max_rect_height = Math.max(max_rect_height, rect.max.h)

      max_rect_width += link_width
      max_rect_height += link_width


      # update center rect objs
      offsetx = center_rect_width / 2
      offsety = center_rect_height / 2

      for obj in center_rect.objs
        obj.x += offsetx
        obj.y += offsety


      # update other rects objs
      for i in [0...limit]
        rect = rects[i]
        offsetx = rect.max.x + Math.cos(angleUnit * i) * link_width + max_rect_width / 2
        offsety = rect.max.y + Math.sin(angleUnit * i) * link_width + max_rect_height / 2

        for obj in rect.objs
          obj.x += offsetx
          obj.y += offsety

    return { w: max_rect_width, h: max_rect_height, objs: objs }





  bubling = (hashes, attrs, point, rect) ->
    unless attrs.x
      rect.objs.push(attrs)

      rect.x1 = Math.min(rect.x1, point.x)
      rect.y1 = Math.min(rect.y1, point.y)

      rect.x2 = Math.max(rect.x2, point.x)
      rect.y2 = Math.max(rect.y2, point.y)

      attrs.x = point.x
      attrs.y = point.y
    else
      point.x = attrs.x
      point.y = attrs.y

    limit = attrs.links.length # need to add + 1 node for ignoring direction of linking with parent
    shiftx = point.x
    shifty = point.y
    scale = Math.max(def_link_segment_length * limit, Math.max(attrs.w, attrs.h)) + 20
    angleUnit = 6.28 / limit

    for i in [0...attrs.links.length]
      # if direction to parent link then continue
      obj = hashes[attrs.links[i]]
      unless obj.x
        bubling(
          hashes
          hashes[attrs.links[i]]
          {x: Math.cos(angleUnit * i) * scale + shiftx + obj.w / 2, y: Math.sin(angleUnit * i) * scale + shifty + obj.h / 2}
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