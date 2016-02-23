#= require ./svg_events

window.svg_fgr = ->
  events = svg_events()


  addNodeToFgr = (fgr, node) ->
    fgr.appendChild(node)


  setPen = (fgr, color = 'black', width = 1) ->
    fgr.setAttribute('stroke', color)
    fgr.setAttribute('stroke-width', width + 'px')


  # pattern: "5,5" "20,10,5,5,5,10"
  # cap: butt round square
  setPenPattern = (fgr, pattern = undefined, cap = 'round') ->
    if (pattern)
      fgr.setAttribute('stroke-dasharray', pattern)
    fgr.setAttribute('stroke-linecap', cap)


  setBrush = (fgr, fill = 'none', fill_rule = 'evenodd') ->
    fgr.setAttribute('fill', fill)
    fgr.setAttribute('fill-rule', fill_rule)


  # "fill:blue;stroke:pink;stroke-width:5;fill-opacity:0.1;stroke-opacity:0.9"
  setStyle = (fgr, newStyle) ->
    fgr.setAttribute('style', newStyle)


  # example: "rotate(30 20,40)"
  setTransform = (fgr, newTransform) ->
    fgr.setAttribute('transform', newTransform)


  # group using for append styles to elements which included to it
  createElementsGroup = ->
    document.createElementNS('http://www.w3.org/2000/svg', 'g')

  createText = (x, y, msg) ->
    text = document.createElementNS('http://www.w3.org/2000/svg', 'text')
    text.setAttribute('x', x + 'px')
    text.setAttribute('y', y + 'px')
    addNodeToFgr(text, document.createTextNode(msg))
    events.attachEventAttributes(text)
    text

  appendSublIneToText = (textFgr, x, y, msg) ->
    tspan = document.createElementNS('http://www.w3.org/2000/svg', 'tspan')
    tspan.setAttribute('x', x + 'px')
    tspan.setAttribute('y', y + 'px')
    addNodeToFgr(tspan, document.createTextNode(msg))
    textFgr.appendChild(tspan)


  wrapTextToLink = (textFgr, href) ->
    a = document.createElement('a');
    a.appendChild(textFgr);
    a.setAttribute('xlink:href', href)
    a


  createLine = (x1, y1, x2, y2) ->
    line = document.createElementNS('http://www.w3.org/2000/svg', 'line')
    line.setAttribute('x1', x1 + 'px')
    line.setAttribute('y1', y1 + 'px')
    line.setAttribute('x2', x2 + 'px')
    line.setAttribute('y2', y2 + 'px')
    events.attachEventAttributes(line)
    line

  createRect = (x, y, width, height, roundCornerX = 0, roundCornerY = 0) ->
    rect = document.createElementNS('http://www.w3.org/2000/svg', 'rect')
    rect.setAttribute('x', x + 'px')
    rect.setAttribute('y', y + 'px')
    rect.setAttribute('width', width + 'px')
    rect.setAttribute('height', height + 'px')
    rect.setAttribute('rx', roundCornerX + 'px')
    rect.setAttribute('ry', roundCornerY + 'px')
    events.attachEventAttributes(rect)
    rect


  createCircle = (centerX, centerY, radius) ->
    circle = document.createElementNS('http://www.w3.org/2000/svg', 'circle');
    circle.setAttribute('cx', centerX + 'px')
    circle.setAttribute('cy', centerY + 'px')
    circle.setAttribute('r', radius + 'px')
    events.attachEventAttributes(circle)
    circle


  createEllipse = (centerX, centerY, radiusX, radiusY) ->
    ellipse = document.createElementNS('http://www.w3.org/2000/svg', 'ellipse');
    ellipse.setAttribute('cx', centerX + 'px')
    ellipse.setAttribute('cy', centerY + 'px')
    ellipse.setAttribute('rx', radiusX + 'px')
    ellipse.setAttribute('ry', radiusY + 'px')
    events.attachEventAttributes(ellipse)
    ellipse

  # The points attribute defines the x and y coordinates for each corner of the polygon
  # "100,10 40,198 190,78 10,78 160,198"
  createPolyline = (points) ->
    polyline = document.createElementNS('http://www.w3.org/2000/svg', 'polyline')
    polyline.setAttribute('points', points)
    events.attachEventAttributes(polyline)
    polyline


  # The points attribute defines the x and y coordinates for each corner of the polygon
  # "100,10 40,198 190,78 10,78 160,198"
  createPolygon = (points) ->
    polygon = document.createElementNS('http://www.w3.org/2000/svg', 'polygon')
    polygon.setAttribute('points', points)
    events.attachEventAttributes(polygon)
    polygon


  #  The following commands are available for path data:
  #
  #  M = moveto
  #  L = lineto
  #  H = horizontal lineto
  #  V = vertical lineto
  #  C = curveto
  #  S = smooth curveto
  #  Q = quadratic Bézier curve
  #  T = smooth quadratic Bézier curveto
  #  A = elliptical Arc
  #  Z = closepath
  #
  #  Note: All of the commands above can also be expressed with lower letters. Capital letters means
  #  absolutely positioned, lower cases means relatively positioned.

  # exaample: "M150 0 L75 200 L225 200 Z"
  createPath = (commands) ->
    path = document.createElementNS('http://www.w3.org/2000/svg', 'path')
    path.setAttribute('d', commands)
    events.attachEventAttributes(path)
    path

  return {
    addNodeToFgr: addNodeToFgr

    setPen: setPen
    setPenPattern: setPenPattern
    setBrush: setBrush
    setStyle: setStyle
    setTransform: setTransform


    createGroup: createElementsGroup

    createText: createText
    appendSublIneToText: appendSublIneToText
    wrapTextToLink: wrapTextToLink

    createLine: createLine
    createRect: createRect
    createCircle: createCircle
    createEllipse: createEllipse
    createPolyline: createPolyline
    createPolygon: createPolygon
    createPath: createPath
  }