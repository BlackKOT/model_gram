//= require jquery
//= require jquery_ujs
//= require canva
// require_tree .

//window.svg = window.svg_canvas();
window.canvas = window.canva();


$('document').ready(function() {
    canvas.init();

    canvas.addTable({
        name: 'Lol',
        fields: [
            { name: 'field1' },
            { name: 'field2' },
            { name: 'field3' }
        ]
    });

    //rect = svg.figures.createRect(20, 20, 100, 100, 20, 20);
    //svg.addFigure(rect);
    //
    //circle = svg.figures.createCircle(150, 150, 40);
    //svg.figures.setBrush(circle, 'rgb(45,45,45)');
    //svg.addFigure(circle);
});