#= require fabric.min

window.canva = ->
  grid = 25
  canvas = undefined

  resize = ->
    console.log('resize')
    canvas.setWidth(window.innerWidth)
    canvas.setHeight(window.innerHeight)
    canvas.calcOffset()
    calc_grid()


  calc_grid = ->
    for i in [0...canvas.width / grid]
      canvas.add(new fabric.Line([ i * grid, 0, i * grid, canvas.height], { stroke: '#ccc', selectable: false }));
    for j in [0...canvas.height / grid]
      canvas.add(new fabric.Line([ 0, j * grid, canvas.width, j * grid], { stroke: '#ccc', selectable: false }))


  init = ->
    canvas = new fabric.Canvas('c', { selection: false })
    window.addEventListener('resize', resize, false)
    resize()
    calc_grid()



  addTable = ->



  return {
    init: init
    addTable: addTable
  }
