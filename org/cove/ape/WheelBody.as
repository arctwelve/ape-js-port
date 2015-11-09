package org.cove.ape {
	
	public class WheelBody extends CircleBody {
		
		internal var _traction:Number;
		
		public function WheelBody(
				x:Number, 
				y:Number, 
				radius:Number, 
				fixedPosition:Boolean = false, 
				mass:Number = 1, 
				elasticity:Number = 0.15,
				friction:Number = .5,
				traction:Number = 1) {
			
			super(x,y,radius,fixedPosition, mass, elasticity, friction);
			
			_traction = traction;
		}
		
		public override function resolveVelocities(dv:Vector, dw:Number, normal:Vector):void{
			
			var tanVec:Vector = new Vector(-normal.y, normal.x);
			tanVec.multEquals(dw * radius * _traction);
			dv.plusEquals(tanVec);
			dw *= (1-_traction);
			
			if(!fixedPosition){
				velocity.plusEquals(dv);
				angVelocity += dw;
			}else if(invInertia > 0){
				angVelocity += dw;
			}
		}
		
		public function get traction():Number{
			return _traction;
		}
		
		public function set traction(t:Number):void{
			_traction = t;
		}
	}
}