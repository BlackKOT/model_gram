window.flake_rect = ->
  x1 = 999999
  y1 = 999999
  x2 = -999999
  y2 = -999999
  objs = []
  subrects = []

  update_coords = (nx1, ny1, nx2, ny2) ->
    x1 = Math.min(x1, nx1)
    y1 = Math.min(y1, ny1)

    x2 = Math.max(x2, nx2)
    y2 = Math.max(y2, ny2)

  add_obj = (point, obj) ->
    objs.push(obj)
    update_coords(point.x, point.y, point.x + obj.w, point.y + obj.h)

  add_subrect = (subrect) ->
    if (subrect.has_objects)
      subrects.push(subrect)
      update_coords(subrect.x1, subrect.y1, subrect.x2, subrect.y2)

  w = ->
    return x2 - x1

  h = ->
    return y2 - y1

  has_objects = ->
    return objs.length > 0

  has_subrects = ->
    return subrects.length > 0

  return {
    add_obj: add_obj
    has_objects: has_objects
    objs: objs
    add_subrect: add_subrect
    has_subrects: has_subrects
    subrects: subrects
    w: w
    h: h
    x1: x1
    y1: y1
  }


window.snowflake = ->
  def_link_segment_length = 40
  angleUnit = (limit) -> 6.28 / limit


  calc_parent_blocked_quart = (parent_angle) ->
    min = (Math.round(parent_angle / 1.57) + 2) % 4 * 1.57
    return {min: min, max: min + 1.57}


  calc_circle_points = (radius, points_required, center_point) ->
    block_intervals = [{min: 1.04666, max: 2.093333}, {min: 4.186666, max: 5.23333}]

    limit = if (isNaN(center_point.angle))
      points_required + Math.ceil(points_required / 1.3)
    else
      block_intervals.push(calc_parent_blocked_quart(center_point.angle))
      points_required + points_required / 8 + points_required % 8

#    attrs.links.length + Math.ceil(attrs.links.length / 1.3)
    #      attrs.links.length + attrs.links.length / 12 + attrs.links.length % 12

    points = []
    for i in [0...limit]
      angle = angleUnit(limit) * i
      valid = true
      for interval in block_intervals
        if angle >= interval.min && angle <= interval.max
          valid = false
          break

      if (valid)
        points.push(
          {
            x: Math.cos(angle) * radius + center_point.x
            y: Math.sin(angle) * radius + center_point.y
            angle: angle
          }
        )

    return points


  update_rects = (rects) ->
    max_rect_width = 0
    max_rect_height = 0

    if (rects.length > 0)
      center_rect = rects.shift()
      center_rect_width = center_rect.w()
      center_rect_height = center_rect.h()
      xcorrection = center_rect.x1
      ycorrection = center_rect.y1

      offsetx = center_rect_width / 2
      offsety = center_rect_height / 2

      for rect in rects
        max_rect_width = Math.max(max_rect_width, rect.w())
        max_rect_height = Math.max(max_rect_height, rect.h())
        xcorrection = Math.min(xcorrection, rect.x1)
        ycorrection = Math.min(ycorrection, rect.y1)

      link_width = Math.max(
        offsetx + max_rect_width / 2
        offsety + max_rect_height / 2
      )

      max_rect_width = offsetx + link_width + max_rect_width
      max_rect_height = offsety + link_width + max_rect_height

      # update center rect objs
      ycorrection = Math.abs(ycorrection)

      for obj in center_rect.objs
        obj.x += offsetx
        obj.y += ycorrection + offsety
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


  # params example
  #  objs = {
  #    uniq_obj.name: {obj: uniq_obj, w: 100, h: 100, links: [uniq_obj_names]}
  #  }
  pack = (objs) ->
    sortir = {}
    rects = []

    for key, attrs of objs
      sortir[attrs.links.length] or (sortir[attrs.links.length] = [])
      sortir[attrs.links.length].push(attrs) # need to sort by height

    for key in Object.keys(sortir).reverse()
      for obj in sortir[key]
        base_rect = flake_rect()
        point = {x: 0, y: 0, angle: NaN}

        unless (obj.x)
          base_rect.add_obj(point, obj)

        subrect = bubling(
          objs,
          obj,
          point,
        )
        base_rect.add_subrect(subrect)

        if (base_rect.has_objects() || base_rect.has_subrects())
          rects.push(base_rect)


    max_rect = update_rects(rects)
    return { w: max_rect.w, h: max_rect.h, objs: objs }


  bubling = (hashes, attrs, point) ->
    rect = flake_rect()

    unless attrs.x
      attrs.x = point.x
      attrs.y = point.y
    else
      point.x = attrs.x
      point.y = attrs.y

    radius = Math.max(attrs.w / 2, attrs.h / 2) + Math.max(200, def_link_segment_length * (attrs.links.length + 1))
    points = calc_circle_points(radius, attrs.links.length, point)

    for i in [0...attrs.links.length]
      obj = hashes[attrs.links[i]]
      unless obj.x
        place_point = points.shift()
        rect.add_obj(place_point, obj)

        subrect = bubling(
          hashes
          obj
          place_point
          flake_rect()
        )

        rect.add_subrect(subrect)

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