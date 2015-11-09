package org.cove.ape {
	
	/**
	 * An rectangle shaped rigid body. 
	 */ 
	public class RectangleBody extends PolygonBody {
		
		public function RectangleBody(x:Number, 
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
		}
	}
}