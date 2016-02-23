// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

window.svg = window.svg_canvas();

$('document').ready(function() {
    rect = svg.figures.createRect(20, 20, 100, 100, 20, 20);
    svg.addFigure(rect);

    circle = svg.figures.createCircle(150, 150, 40);
    svg.figures.setBrush(circle, 'rgb(45,45,45)');
    svg.addFigure(circle);
});