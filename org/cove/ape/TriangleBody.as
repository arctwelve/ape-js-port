package org.cove.ape {
	
	/**
	 * A triangular shaped body. Use this instead of a 3 sided PolygonBody as it is more efficient
	 */ 
	public class TriangleBody extends PolygonBody {
		
		public function TriangleBody(x:Number, 
				y:Number,
				width:Number, 
				height:Number,
				rotation:Number = 0,
				fixed:Boolean = false,
				mass:Number = 1, 
				elasticity:Number = 0.15,
				friction:Number = 0.1) {
				
				super(x, y, width, height, 3, rotation, fixed, mass, elasticity, friction);
		}
		
		internal override function createVertices(width:Number, height:Number):void{
			_vertices = new Array();
			_originalVertices = new Array();
			
			_originalVertices.push(new Vector(width/2, height/3));
			_originalVertices.push(new Vector(-width/2, height/3));
			_originalVertices.push(new Vector(0, -height*2/3));
		}
	}
}