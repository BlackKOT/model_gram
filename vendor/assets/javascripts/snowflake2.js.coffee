window.snowflake = ->
  def_link_segment_length = 40
  angleUnit = (limit) -> 6.28 / limit

#  rect_draw = (canvas, rect) ->
##    canvas.add new fabric.Rect({
##      left: rect.x1
##      top: rect.y1
##      width: rect.w || rect_width(rect)
##      height: rect.h || rect_height(rect)
##      fill: 'rgba(0,0,0,0)'
##      stroke: 'red'
##      strokeWidth: 1
##    })
##
##    for sub in rect.subrects
##      rect_draw(canvas, sub)
#
#    return true
#
#
#  rect_intersection = (rect1, rect2) ->
#    x = Math.max(rect1.x1, rect2.x1)
#    num1 = Math.min(rect1.x1 + rect_width(rect1), rect2.x1 + rect_width(rect2))
#    y = Math.max(rect1.y1, rect2.y1)
#    num2 = Math.min(rect1.y1 + rect_height(rect1), rect2.y1 + rect_height(rect2))
#    if num1 >= x && num2 >= y
#      {
#        x1: x, y1: y, x2: num1, y2: num2,
#        w: if (rect2.x1 + rect_width(rect2) / 2 > rect1.x1 + rect_width(rect1) / 2) then rect1.x2 - rect2.x1 + def_link_segment_length else rect1.x1 - rect2.x2 - def_link_segment_length
#        h: if (rect2.y1 + rect_height(rect2) / 2 > rect1.y1 + rect_height(rect1) / 2) then rect1.y2 - rect2.y1 + def_link_segment_length else rect1.y1 - rect2.y2 - def_link_segment_length
#      }
#    else
#      undefined
#
#  rect_proc_subrect_intersection = (rect, subrect) ->
#    i = 0
#    while(i++ < 25)
#      has_intersections = false
#      has_intersections |= rect_proc_intersection(rect.base, subrect)
#
#      for sub in rect.subrects
#        has_intersections |= rect_proc_intersection(sub, subrect)
#
#      if !has_intersections
#        break
#    console.error(subrect.name, i)
#
#
#  rect_proc_intersection = (rect, subrect) ->
#    intersect_rect = rect_intersection(rect, subrect)
#    if (intersect_rect)
#      console.log('^', intersect_rect.w, intersect_rect.h)
#
#      if Math.abs(intersect_rect.w) < Math.abs(intersect_rect.h)
#        w = intersect_rect.w
#        h = 0
#      else
#        w = 0
#        h = intersect_rect.h
#
#      for moves in subrect.moved
#        if moves.x == intersect_rect.w && moves.y == intersect_rect.h
#          if w != 0
#            w = 0
#            h = intersect_rect.h
#          else
#            w = intersect_rect.w
#            h = 0
#
#          break
#
#      console.log('**** start move')
#      subrect.moved.push({x: intersect_rect.w, y: intersect_rect.h})
#      rect_move_objects(subrect, w, h)
#      console.log('**** end move')
#
#    return !!intersect_rect
#
#
#  rect_generate = (obj, point) ->
#    rect = {
#      x1: 99999, y1: 99999, x2: -99999, y2: -99999, objs: [], subrects: [], name: obj.obj.name
#      base: {x1: point.x, y1: point.y, x2: point.x + obj.w, y2: point.y + obj.h, moved: []}
#      moved: []
#    }
#    if obj && !!!obj.x
#      rect_add_obj(rect, obj, point)
#    rect
#
#  rect_width = (rect) ->
#    Math.abs(rect.x2 - rect.x1)
#
#  rect_height = (rect) ->
#    Math.abs(rect.y2 - rect.y1)
#
#  rect_init_max = (rect) ->
#    rect.w = rect_width(rect)
#    rect.h = rect_height(rect)
#
#  rect_recalc_bounds = (rect, xn1, yn1, xn2, yn2) ->
#    rect.x1 = Math.min(rect.x1, xn1)
#    rect.y1 = Math.min(rect.y1, yn1)
#
#    rect.x2 = Math.max(rect.x2, xn2)
#    rect.y2 = Math.max(rect.y2, yn2)
#
#
#  rect_add_obj = (rect, obj, point) ->
#    rect.objs.push(obj)
#    rect_recalc_bounds(
#      rect,
#      point.x, point.y
#      point.x + obj.w, point.y + obj.h
#    )
#
#
#  rect_move_objects = (rect, offsetx, offsety, mark) ->
#    rect.x1 = 99999
#    rect.y1 = 99999
#    rect.x2 = -99999
#    rect.y2 = -99999
#
#    for obj in rect.objs
#      unless obj.ch
#        console.log('*', obj.obj.name)
#        obj.x += offsetx
#        obj.y += offsety
#        obj.ch = !!mark
#
#      rect_recalc_bounds(rect, obj.x, obj.y, obj.x + obj.w, obj.y + obj.h)
#
#    for subrect in rect.subrects
#      console.log('**', subrect.name)
#      rect_move_objects(subrect, offsetx, offsety, mark)
#      rect_recalc_bounds(rect, subrect.x1, subrect.y1, subrect.x2, subrect.y2)
#
#
#  rect_add_subrect = (rect, subrect) ->
#    rect.subrects.push(subrect)
##    rect.objs = rect.objs.concat(subrect.objs)
#    rect_recalc_bounds(
#      rect,
#      subrect.x1, subrect.y1
#      subrect.x2, subrect.y2
#    )
#
#
#  calc_parent_blocked_quart = (parent_angle) ->
#    min = (Math.round(parent_angle / 1.57) + 2) % 4 * 1.57
#    return {min: min, max: min + 1.57}

  calc_bound_rect = (rects) ->
    offsetx = 0
    offsety = 0

    for _, attrs of rects
      if attrs.x < 0
        offsetx = Math.min(offsetx, attrs.x)

      if attrs.y < 0
        offsety = Math.min(offsety, attrs.y)

    rect = {x1: 999999, y1: 999999, x2: -999999, y2: -999999}

    for _, attrs of rects
      attrs.x -= offsetx
      attrs.y -= offsety

      rect.x1 = Math.min(rect.x1, attrs.x)
      rect.y1 = Math.min(rect.y1, attrs.y)

      rect.x2 = Math.max(rect.x2, attrs.x + attrs.w)
      rect.y2 = Math.max(rect.y2, attrs.y + attrs.h)

    rect.w = rect.x2 - rect.x1
    rect.h = rect.y2 - rect.y1
    rect


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

  distance_between_rects = (rect1, rect2) ->
    Math.sqrt((rect1.x - rect2.x) * (rect1.x - rect2.x) + (rect1.y - rect2.y) * (rect1.y - rect2.y))

  # calc full branch distance
  calc_weight = (rects, name, proc_list = {}) ->
    weight = 0
    curr_rect = rects[name]

    proc_list[name] = true
    for link in curr_rect.links
      weight += distance_between_rects(curr_rect, rects[link])
      weight += calc_weight(rects, link, proc_list) unless proc_list[link]

    weight


  # params example
  #  objs = {
  #    uniq_obj.name: {obj: uniq_obj, w: 100, h: 100, links: [uniq_obj_names]}
  #  }
  pack = (canvas, objs) ->
    x = 0
    sortir = {}

    for key, attrs of objs
      attrs.x = x
      attrs.y = 0
      x += def_link_segment_length + attrs.w

      hash_key = '' + attrs.links.length
      (sortir[hash_key] or (sortir[hash_key] = [])).push(key)

    for name, params of objs # calc default weight
      params.proc = { weight: calc_weight(objs, name), points: {} }

    sorted_lens = Object.keys(sortir).sort().reverse()
    for i in [0..10]
      changed = false

      for len in sorted_lens
        continue if len == '0'

        for name in sortir[len]
          params = objs[name]

          radius = def_link_segment_length + params.w
          points = calc_circle_points(radius, params.links.length, {x: params.x + params.w / 2, y: params.y + params.h / 2})

          new_weight = params.proc.weight
          new_point = {x: params.x, y: params.y}

          for point in points
            params.x = point.x
            params.y = point.y

            weight = calc_weight(objs, name)
            if weight < new_weight && !!!params.proc.points[new_point]
              new_weight = weight
              new_point = point

          if params.proc.weight > new_weight
            changed = true
            params.x = new_point.x
            params.y = new_point.y
            params.proc.weight = new_weight
            params.proc.points[new_point] = true

      console.log('---------------------', i)

      unless changed
        console.log('Completed: ', i)
        break


    max_rect = calc_bound_rect(objs)
    return { w: max_rect.w, h: max_rect.h, objs: objs }

  return {
    pack: pack
  }
