package org.cove.ape {
	
	import flash.display.Graphics;
	
	/**
	 * A rectangular shaped particle. Use this instead of a 4 sided PolygonParticle as it is more efficient
	 */ 
	public class RectangleParticle extends PolygonParticle {
	
		private var _extents:Array;
		//private var _axes:Array;		
		
		/**
		 * @param x The initial x position.
		 * @param y The initial y position.
		 * @param width The width of this particle.
		 * @param height The height of this particle.
		 * @param rotation The rotation of this particle in radians.
		 * @param fixed Determines if the particle is fixed or not. Fixed particles
		 * are not affected by forces or collisions and are good to use as surfaces.
		 * Non-fixed particles move freely in response to collision and forces.
		 * @param mass The mass of the particle
		 * @param elasticity The elasticity of the particle. Higher values mean more elasticity.
		 * @param friction The surface friction of the particle. 
		 * <p>
		 * Note that RectangleParticles can be fixed but still have their rotation property 
		 * changed.
		 * </p>
		 */
		public function RectangleParticle(x:Number, 
				y:Number,
				width:Number, 
				height:Number,
				rotation:Number = 0,
				fixed:Boolean = false,
				mass:Number = 1, 
				elasticity:Number = 0.15,
				friction:Number = 0.1) {
				
				super(x, y, width, height, 4, rotation, fixed, mass, elasticity, friction);
		}
		
		internal override function createVertices(width:Number, height:Number):void{
			_vertices = new Array();
			_originalVertices = new Array();
			
			_originalVertices.push(new Vector(width/2, height/2));
			_originalVertices.push(new Vector(-width/2, height/2));
			_originalVertices.push(new Vector(-width/2, -height/2));
			_originalVertices.push(new Vector(width/2, -height/2));
			
			_extents = new Array(width/2, height/2);
			_axes = new Array(new Vector(0,0), new Vector(0,0));
		}		
		
		/**
		 * @private
		 */		
		public override function set radian(t:Number):void {
			super.radian = t;
			//setAxes();
		}
		
		public function set width(w:Number):void {
			_extents[0] = w/2;
		}

		
		public function get width():Number {
			return _extents[0] * 2
		}


		public function set height(h:Number):void {
			_extents[1] = h / 2;
		}


		public function get height():Number {
			return _extents[1] * 2
		}
		
		/**
		 * @private
		 */	
		internal function get axes():Array {
			return _axes;
		}
		
		/**
		 * @private
		 */	
		internal function get extents():Array {
			return _extents;
		}
		
		/**
		 * @private
		 */	
		internal override function getProjection(axis:Vector):Interval {
			
			var radius:Number =
			    extents[0] * Math.abs(axis.dot(axes[0]))+
			    extents[1] * Math.abs(axis.dot(axes[1]));
			
			var c:Number = samp.dot(axis);
			
			interval.min = c - radius;
			interval.max = c + radius;
			return interval;
		}		


		/**
		 * 
		 */					
		internal override function setAxes():void {
			//_axes = new Array();
			var s:Number = Math.sin(_radian);
			var c:Number = Math.cos(_radian);
			
			_axes[0].x = c;
			_axes[0].y = s;
			_axes[1].x = -s;
			_axes[1].y = c;
		}
		
		internal override function getAxes():Array{
			return _axes;
		}
		
		/*
		internal override function getClosestVertex(v:Vector):Vector{
			var d:Vector = v.minus(curr);
			var q:Vector = new Vector(curr.x, curr.y);
	
			for (var i:int = 0; i < 2; i++) {
				var dist:Number = d.dot(_axes[i]);
	
				if (dist >= 0) dist = _extents[i];
				else if (dist < 0) dist = _extents[i];
	
				q.plusEquals(_axes[i].mult(dist));
			}
			return q;
		}
		*/
	}
}