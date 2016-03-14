/*
	Script: xdRectPacker.js
	bin-pack rectangles in rectangle An algorithm implementation in JavaScript for rectangle packing.
	Author:
		Valeriy Chupurnov <leroy@xdan.ru>, <http://xdan.ru>
	License:
		LGPL - Lesser General Public License
	Class: xdRectPacker
	A class that finds an 'efficient' position for a rectangle inside another rectangle
	without overlapping the space already taken.
	
	Posted <http://xdan.ru/2d-bin-packing-with-javascript.html>
	
	A simple search of the empty positions, so it works very slowly.
	Warning: not recommended for more than 50 objects
*/
var xdRectPacker = function ( sideSize,horizontal ){
	this.side = (!horizontal)?'width':'height';
	this[this.side] = parseInt(sideSize);
	this._y = (this.side=='width')?'y':'x';
	this._x = (this.side=='width')?'x':'y';
	this._w = (this.side=='width')?'w':'h';
};
var xdRect = function(x,y,w,h){
  return {
    x:x,
    y:y,
    w:w,
    h:h,
    x1:function(){ return this.x+this.w;},
    y1:function(){ return this.y+this.h;},
    intersect:function( rc ){
      return (
			(
				(
					( rc.x>=this.x && rc.x<=this.x1() )||( rc.x1()>=this.x && rc.x1()<=this.x1()  )
				) && (
					( rc.y>=this.y && rc.y<=this.y1() )||( rc.y1()>=this.y && rc.y1()<=this.y1() )
				)
			)||(
				(
					( this.x>=rc.x && this.x<=rc.x1() )||( this.x1()>=rc.x && this.x1()<=rc.x1()  )
				) && (
					( this.y>=rc.y && this.y<=rc.y1() )||( this.y1()>=rc.y && this.y1()<=rc.y1() )
				)
			)
		)||(
			(
				(
					( rc.x>=this.x && rc.x<=this.x1() )||( rc.x1()>=this.x && rc.x1()<=this.x1()  )
				) && (
					( this.y>=rc.y && this.y<=rc.y1() )||( this.y1()>=rc.y && this.y1()<=rc.y1() )
				)
			)||(
				(
					( this.x>=rc.x && this.x<=rc.x1() )||( this.x1()>=rc.x && this.x1()<=rc.x1()  )
				) && (
					( rc.y>=this.y && rc.y<=this.y1() )||( rc.y1()>=this.y && rc.y1()<=this.y1() )
				)
			)
		);
    },
  };
};
xdRectPacker.prototype = {
	width:0,
	height:0,
	side:'width',
	_x:'x',
	_y:'y',
	pack:[],
	findPlace:function( rc ){
		if( this.pack.length ){
			var i = 0;
			while( i<this.pack.length ){
				if( rc.intersect( this.pack[i] ) ){
					if( 1+rc[this._w]+this.pack[i][this._x+'1']()<this[this.side] ){
						rc[this._x] = this.pack[i][this._x+'1']()+1;
						i  = -1;
					}else{
						rc[this._y]+=1;
						rc[this._x]=0;
						i  = -1;
					}
				}
				i++;
			}
		}else{ rc.x = 0; rc.y = 0;};
		return rc;
	},
	fit:function (rcs){
		this.pack = [];
		for(var i=0;i<rcs.length;i++){
			this.pack.push( this.findPlace(rcs[i]) );
		}
	}
};