package org.cove.ape {
	
	import flash.display.Graphics;
	
	/**
	 * A triangular shaped particle. Use this instead of a 3 sided PolygonParticle as it is more efficient
	 */ 
	public class TriangleParticle extends PolygonParticle {
	
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
		public function TriangleParticle(x:Number, 
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