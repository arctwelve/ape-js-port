package org.cove.ape {
	
	import flash.display.Graphics;
	import flash.geom.Matrix;
	
	/**
	 * An n-sided polygon shaped particle. 
	 */ 
	public class PolygonParticle extends AbstractParticle {
		
		internal var _radian:Number;
		
		internal var _density:Number;
		
		internal var _originalVertices:Array;
		internal var _vertices:Array;
		internal var _numVertices:int;
		
		internal var _axes:Array;
		
		public function PolygonParticle(x:Number, 
				y:Number,
				width:Number, 
				height:Number,
				numVertices:int,
				rotation:Number = 0,
				fixedPosition:Boolean = false,
				mass:Number = 1, 
				elasticity:Number = 0.15,
				friction:Number = 0.1) {
				
				super(x, y, fixedPosition, mass, elasticity, friction);
				
				_numVertices = numVertices;
				createVertices(width, height);
				radian = rotation;
				
				//this.density = density;
		}
		
		internal function createVertices(width:Number, height:Number):void{
			_vertices = new Array();
			_originalVertices = new Array();
			
			var a:Number = Math.PI/numVertices;
			var da:Number = MathUtil.TWO_PI/numVertices;
			
			for(var i:int = 0; i < numVertices; i++){
				a+= da;
				_originalVertices.push(new Vector(Math.cos(a) * width, Math.sin(a) * height));
			}			
		}
		
		
		public override function get radian():Number {
			return _radian;
		}
		
		/**
		 * @private
		 */		
		public function set radian(t:Number):void {
			t = t % (MathUtil.TWO_PI);
			_radian = t;
			orientVertices(t);
			setAxes();
		}
		
		public function get angle():Number {
			return radian * MathUtil.ONE_EIGHTY_OVER_PI;
		}

		/**
		 * @private
		 */		
		public function set angle(a:Number):void {
			radian = a * MathUtil.PI_OVER_ONE_EIGHTY;
		}
		
		/**
		 * Sets up the visual representation of this PolygonParticle. This method is called 
		 * automatically when an instance of this PolygonParticle's parent Group is added to 
		 * the APEngine, when  this PolygonParticle's Composite is added to a Group, or the 
		 * PolygonParticle is added to a Composite or Group.
		 */				
		public override function init():void {
			cleanup();
			if (displayObject != null) {
				initDisplay();
			} else {
			
				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);
				sprite.graphics.beginFill(fillColor, fillAlpha);
				sprite.graphics.moveTo(_originalVertices[0].x, _originalVertices[0].y);
				for(var i:int = 1; i < _originalVertices.length; i++){
					sprite.graphics.lineTo(_originalVertices[i].x, _originalVertices[i].y);
				}
				sprite.graphics.lineTo(_originalVertices[0].x, _originalVertices[0].y);
				sprite.graphics.endFill();
			}
			paint();
		}
		
		public override function paint():void {
			sprite.x = curr.x;
			sprite.y = curr.y;
			sprite.rotation = angle;
		}
		
		public function clearSprite():void{
			sprite.parent.removeChild(sprite);
		}
		
		internal function get vertices():Array{
			return _vertices;
		}
		
		internal function get numVertices():int{
			return _numVertices;
		}
		
		internal function set density(d:Number):void{
			_density = d;
			mass = calculateMass();
		}
		
		internal function get density():Number{
			return _density;
		}
		
		internal function calculateMass():Number{
			if(numVertices < 2){
				return 5 * density;
			}
			
			var m:Number = 0;
			var j:int = numVertices - 1;
			for (var i:int = 0; i < numVertices; i++){
				var P0:Vector = vertices[j];
				var P1:Vector = vertices[i];
				m += Math.abs(P0.cross(P1));
				j = i;
			}
			if(numVertices <= 2){
				m = 10;
			}
			m *= density * .5;
			return m;
		}
		
		internal function orientVertices(r:Number){
			for(var i:int = 0; i < _originalVertices.length; i++){
				_vertices[i] = _originalVertices[i].rotate(r);
			}
		}
		
		/**
		 * @private
		 */	
		internal function getProjection(axis:Vector):Interval {
			
			var c:Number = curr.dot(axis);
			
			var rad:Number = _vertices[0].dot(axis);
			var negRad:Number = rad;
			var posRad:Number = rad;
			
			for (var i:int = 1; i < _vertices.length; i++){
				rad = _vertices[i].dot(axis);
				if(rad < negRad){
					negRad = rad;
				}else if(rad > posRad){
					posRad = rad;
				}
			}
			
			interval.min = c + negRad;
			interval.max = c + posRad;
			
			return interval;
		}
		
		internal function getAxes():Array{
			return _axes;
		}
		
		internal function setAxes():void{
			_axes = new Array();
			var j:int = _numVertices - 1;
			for(var i:int = 0; i < _numVertices; i++){
				var e0:Vector = _vertices[j];
				var e1:Vector = _vertices[i];
				var e:Vector = e1.minus(e0);
				var currAxis:Vector = (new Vector(-e.y, e.x)).normalize();
				_axes.push(currAxis);
				j=i;
			}
		}
		
		internal function getClosestVertex(v:Vector):Vector{
			var d:Vector = v.minus(curr);
			var maxDist:Number = 0;
			var index:int = -1;
			
			for(var i:int = 0; i<_vertices.length; i++){
				var dist:Number = d.dot(_vertices[i]);
				if(dist > maxDist){
					maxDist = dist;
					index = i;
				}
			}
			return _vertices[index].plus(curr);
		}
		
		public override function leftMostXValue():Number{
			if(!isNaN(lmx) && fixedPosition) return lmx;
			
			var vx:Number = _vertices[0].x;
			lmx = vx;
			for(var i:int = 1; i < _vertices.length; i++){
				vx = _vertices[i].x;
				if( vx < lmx){
					lmx = vx;
				}
			}
			lmx += curr.x;
			return lmx;
		}
		
		public override function rightMostXValue():Number{
			if(!isNaN(rmx) && fixedPosition) return rmx;
			
			var vx:Number = _vertices[0].x;
			rmx = vx;
			for(var i:int = 1; i < _vertices.length; i++){
				vx = _vertices[i].x;
				if( vx > rmx){
					rmx = vx;
				}
			}
			rmx += curr.x;
			return rmx;
		}
	}
}