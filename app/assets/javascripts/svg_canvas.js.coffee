#= require ./svg_fgr

window.svg_canvas = ->
  canva = ->
    (document.getElementsByTagName('svg') || [])[0]
  figures = svg_fgr()


  addFigure = (fgr) ->
    canva().appendChild(fgr)


  return {
    addFigure: addFigure,
    figures: figures
  }
