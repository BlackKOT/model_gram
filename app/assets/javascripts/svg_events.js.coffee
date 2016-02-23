window.svg_events = ->
  selectedElement = 0
  currentX = 0
  currentY = 0
  currentMatrix = 0

  attachEventAttributes = (obj) ->
    obj.setAttribute('transform', 'matrix(1 0 0 1 0 0)')
    obj.setAttribute('onmousedown', 'fgr_events.selectElement(evt)')
    obj.setAttribute('class', 'draggable')


  selectElement = (evt) ->
    selectedElement = evt.target
    currentX = evt.clientX
    currentY = evt.clientY
    currentMatrix = selectedElement.getAttributeNS(null, 'transform').slice(7,-1).split(' ')
    for i in [0...currentMatrix.length]
      currentMatrix[i] = parseFloat(currentMatrix[i])

    selectedElement.setAttributeNS(null, 'onmousemove', 'fgr_events.moveElement(evt)')
    selectedElement.setAttributeNS(null, 'onmouseout', 'fgr_events.deselectElement(evt)')
    selectedElement.setAttributeNS(null, 'onmouseup', 'fgr_events.deselectElement(evt)')


  moveElement = (evt) ->
    dx = evt.clientX - currentX
    dy = evt.clientY - currentY
    currentMatrix[4] += dx
    currentMatrix[5] += dy
    newMatrix = "matrix(#{currentMatrix.join(' ')})"

    selectedElement.setAttributeNS(null, 'transform', newMatrix)
    currentX = evt.clientX
    currentY = evt.clientY


  deselectElement = (evt) ->
    if(selectedElement != 0)
      selectedElement.removeAttributeNS(null, 'onmousemove')
      selectedElement.removeAttributeNS(null, 'onmouseout')
      selectedElement.removeAttributeNS(null, 'onmouseup')
      selectedElement = 0


  return {
    selectElement: selectElement
    moveElement: moveElement
    deselectElement: deselectElement
    attachEventAttributes: attachEventAttributes
  }