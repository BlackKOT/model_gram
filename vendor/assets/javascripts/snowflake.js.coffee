window.snowflake = ->
  def_link_segment_length = 40
  angleUnit = (limit) -> 6.28 / limit

  rect_draw = (canvas, rect) ->
#    canvas.add new fabric.Rect({
#      left: rect.x1
#      top: rect.y1
#      width: rect.w || rect_width(rect)
#      height: rect.h || rect_height(rect)
#      fill: 'rgba(0,0,0,0)'
#      stroke: 'red'
#      strokeWidth: 1
#    })
#
#    for sub in rect.subrects
#      rect_draw(canvas, sub)

    return true


  rect_intersection = (rect1, rect2) ->
    x = Math.max(rect1.x1, rect2.x1)
    num1 = Math.min(rect1.x1 + rect_width(rect1), rect2.x1 + rect_width(rect2))
    y = Math.max(rect1.y1, rect2.y1)
    num2 = Math.min(rect1.y1 + rect_height(rect1), rect2.y1 + rect_height(rect2))
    if num1 >= x && num2 >= y
      {
        x1: x, y1: y, x2: num1, y2: num2,
        w: if (rect2.x1 + rect_width(rect2) / 2 > rect1.x1 + rect_width(rect1) / 2) then rect1.x2 - rect2.x1 + 1 else rect1.x1 - rect2.x2 - 1
        h: if (rect2.y1 + rect_height(rect2) / 2 > rect1.y1 + rect_height(rect1) / 2) then rect1.y2 - rect2.y1 + 1 else rect1.y1 - rect2.y2 - 1
      }
    else
      undefined

  rect_proc_subrect_intersection = (rect, subrect) ->
    rect_proc_intersection(rect.base, subrect)

    for sub in rect.subrects
      rect_proc_intersection(sub, subrect)


  rect_proc_intersection = (rect, subrect) ->
    i = 0
    while(i++ < 10)
      intersect_rect = rect_intersection(rect, subrect)
      if (intersect_rect)
        console.log('^', rect, subrect, intersect_rect)

        if Math.abs(intersect_rect.w) < Math.abs(intersect_rect.h)
          w = intersect_rect.w
          h = 0
        else
          w = 0
          h = intersect_rect.h

        console.log('**** start move')
        rect_move_objects(subrect, w, h)
        console.log('**** end move')
        console.log('!', rect_intersection(rect, subrect))
      else
        break


  rect_generate = (obj, point) ->
    rect = {
      x1: 99999, y1: 99999, x2: -99999, y2: -99999, objs: [], subrects: [], name: obj.obj.name
      base: {x1: point.x, y1: point.y, x2: point.x + obj.w, y2: point.y + obj.h}
    }
    if obj && !!!obj.x
      rect_add_obj(rect, obj, point)
    rect

  rect_width = (rect) ->
    Math.abs(rect.x2 - rect.x1)

  rect_height = (rect) ->
    Math.abs(rect.y2 - rect.y1)

  rect_init_max = (rect) ->
    rect.w = rect_width(rect)
    rect.h = rect_height(rect)

  rect_recalc_bounds = (rect, xn1, yn1, xn2, yn2) ->
    rect.x1 = Math.min(rect.x1, xn1)
    rect.y1 = Math.min(rect.y1, yn1)

    rect.x2 = Math.max(rect.x2, xn2)
    rect.y2 = Math.max(rect.y2, yn2)


  rect_add_obj = (rect, obj, point) ->
    rect.objs.push(obj)
    rect_recalc_bounds(
      rect,
      point.x, point.y
      point.x + obj.w, point.y + obj.h
    )


  rect_move_objects = (rect, offsetx, offsety, mark) ->
    rect.x1 = 99999
    rect.y1 = 99999
    rect.x2 = -99999
    rect.y2 = -99999

    for obj in rect.objs
      unless obj.ch
        console.log('*', obj.obj.name)
        obj.x += offsetx
        obj.y += offsety
        obj.ch = !!mark

      rect_recalc_bounds(rect, obj.x, obj.y, obj.x + obj.w, obj.y + obj.h)

    for subrect in rect.subrects
      console.log('**', subrect.name)
      rect_move_objects(subrect, offsetx, offsety, mark)
      rect_recalc_bounds(rect, subrect.x1, subrect.y1, subrect.x2, subrect.y2)



  rect_add_subrect = (rect, subrect) ->
    rect.subrects.push(subrect)
#    rect.objs = rect.objs.concat(subrect.objs)
    rect_recalc_bounds(
      rect,
      subrect.x1, subrect.y1
      subrect.x2, subrect.y2
    )


  calc_parent_blocked_quart = (parent_angle) ->
    min = (Math.round(parent_angle / 1.57) + 2) % 4 * 1.57
    return {min: min, max: min + 1.57}


  calc_circle_points = (radius, points_required, center_point) ->
#    block_intervals = [{min: 1.04666, max: 2.093333}, {min: 4.186666, max: 5.23333}]
    block_intervals = [{min: 1.3, max: 1.839993}, {min: 4.440006, max: 4.97999}]

    limit = if (isNaN(center_point.angle))
      points_required + Math.ceil(points_required / 1.3)
    else
      block_intervals.push(calc_parent_blocked_quart(center_point.angle))
      points_required + points_required * (6.28 / 5)

    points = []
    for i in [0...limit]
      angle = angleUnit(limit) * i - 3.14 / 4
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


    if (points.length > points_required)
      step = points.length / (points.length - points_required)
      for ind in [0...points.length] by step
        points.splice(ind, 1)

    if (points.length < points_required)
      console.error('Points is not enough :(')
    return points


  update_rects = (canvas, rects) ->
    for ind in [0...rects.length]
      base_rect = rects[ind]
      for ind2 in [ind + 1...rects.length]
        rect_proc_intersection(base_rect, rects[ind2])

    xmin = 999999
    ymin = 999999

    xmax = -999999
    ymax = -999999

    if (rects.length > 0)
      for rect in rects
        xmin = Math.min(xmin, rect.x1)
        ymin = Math.min(ymin, rect.y1)
        xmax = Math.max(xmax, rect.x2)
        ymax = Math.max(ymax, rect.y2)

      offsetx = if xmin < 0 then -xmin else 0
      offsety = if ymin < 0 then -ymin else 0

      for rect in rects
        for obj in rect.objs
          rect_move_objects(rect, offsetx, offsety, true)

        rect_draw(canvas, rect)


#      center_rect = rects.shift()
#      center_rect_width = center_rect.w
#      center_rect_height = center_rect.h
#      ycorrection = Math.min(ycorrection, center_rect.y1)
#
#      offsetx = center_rect_width / 2
#      offsety = center_rect_height / 2
#
#      for rect in rects
#        max_rect_width = Math.max(max_rect_width, rect.w)
#        max_rect_height = Math.max(max_rect_height, rect.h)
#        xcorrection = Math.min(xcorrection, rect.x1)
#        ycorrection = Math.min(ycorrection, rect.y1)
#
#      link_width = Math.max(
#        offsetx + max_rect_width / 2
#        offsety + max_rect_height / 2
#      )
#
#      max_rect_width = offsetx + link_width + max_rect_width
#      max_rect_height = offsety + link_width + max_rect_height
#
#      # update center rect objs
#      ycorrection = Math.abs(ycorrection)
#
#      for obj in center_rect.objs
#        obj.x += offsetx
#        obj.y += ycorrection + offsety
#        obj.ch = true
#
#      limit = rects.length
#      for i in [0...limit]
#        rect = rects[i]
#        offsetxx = Math.cos(angleUnit(limit) * i) * link_width + offsetx
#        offsetyy = Math.sin(angleUnit(limit) * i) * link_width + offsety + ycorrection
#
#        for obj in rect.objs
#          if (obj.ch) then continue;
#          obj.x += offsetxx
#          obj.y += offsetyy

    {w: Math.min(6000, xmax - xmin), h: Math.min(6000, ymax - ymin)}

  # params example
  #  objs = {
  #    uniq_obj.name: {obj: uniq_obj, w: 100, h: 100, links: [uniq_obj_names]}
  #  }
  pack = (canvas, objs) ->
    sortir = {}
    rects = []

    for key, attrs of objs
      sortir[attrs.links.length] or (sortir[attrs.links.length] = [])
      sortir[attrs.links.length].push(attrs) # need to sort by height

    i = 0
    for key in Object.keys(sortir).reverse()
      for obj in sortir[key]
        point = {x: 0, y: 0, angle: NaN}
        obj.series = '' + i++

        rect = bubling(
          objs,
          obj,
          point,
          rect_generate(obj, point)
          '' + i
        )
        if (rect.objs.length > 0)
          rect_init_max(rect)
          rects.push(rect)


    max_rect = update_rects(canvas, rects)
    return { w: max_rect.w, h: max_rect.h, objs: objs }


  bubling = (hashes, attrs, point, rect, series) ->
    unless attrs.x
      attrs.x = point.x
      attrs.y = point.y
    else
      return rect


    radius = Math.max(attrs.w * 2, attrs.h) #def_link_segment_length # attrs.w + def_link_segment_length
    points = calc_circle_points(radius, attrs.links.length, point)

    for i in [0...attrs.links.length]
      obj = hashes[attrs.links[i]]
      unless obj.series
        obj.series = series
        obj.point = points.shift()
#        rect_add_obj(rect, obj, obj.point)

    subrects = []
    for i in [0...attrs.links.length]
      obj = hashes[attrs.links[i]]
      if obj.series == series
        subrect = bubling(
          hashes
          obj
          obj.point
          rect_generate(obj, obj.point)
          series + i
        )

        if (subrect.objs.length > 0)
          subrects.push(subrect)


    console.log('Main', rect.name)
    for sub in subrects
      console.log('Rel', sub.name)
      rect_proc_subrect_intersection(rect, sub)
      rect_add_subrect(rect, sub)

    console.log('--------------------')
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