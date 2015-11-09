package org.cove.ape {
	
	/**
	 * An n-sided polygon shaped rigid body with angular momentum 
	 */ 
	public class PolygonBody extends PolygonParticle {
		
		internal var _inertia:Number;
		internal var _invInertia:Number;
		
		internal var _angVelocity:Number;
		internal var _netTorque:Number;
		
		
		public function PolygonBody(x:Number, 
				y:Number,
				width:Number, 
				height:Number,
				numVertices:int,
				rotation:Number = 0,
				fixedPosition:Boolean = false,
				mass:Number = 1, 
				elasticity:Number = 0.15,
				friction:Number = 0.1) {
				
				super(x, y, width, height, numVertices, rotation, fixedPosition, mass, elasticity, friction);
				_netTorque = 0;
				_angVelocity = 0;
				
				inertia = calculateInertia();
		}
		
		public override function get angVelocity():Number{
			return _angVelocity;
		}
		
		public override function set angVelocity(n:Number):void{
			_angVelocity = n;
		}
		
		internal override function set density(d:Number):void{
			super.density = d;
			inertia = calculateInertia();
		}
		
		public function set inertia(n:Number){
			if (n <= 0) throw new ArgumentError("inertia may not be set <= 0"); 
			_inertia = n;
			_invInertia = 1/n;
		}
		
		public function get inertia():Number{
			return _inertia;
		}
		
		public override function get invInertia():Number{
			return _invInertia; 
		}
		
		internal function calculateInertia():Number{
			var iner:Number;
			if (numVertices == 1){
				iner = 1
				return iner;
			}
			
			var denom:Number = 0;
			var numer:Number = 0;
			
			var j:int = numVertices - 1;
			for (var i:int = 0; i < numVertices; i++){
				var P0:Vector = vertices[j];
				var P1:Vector = vertices[i];
				
				var a:Number = Math.abs(P0.cross(P1));
				var b:Number = (P1.dot(P1) + P1.dot(P0) + P0.dot(P0));
				
				denom += (a * b);
				numer += a;
			}
			iner = (mass/6) * (denom/numer);
			return iner;
		}
		
		public override function get velocity():Vector {
			return _velocity;
			//return curr.minus(prev);
		}
		
		public override function set velocity(v:Vector):void {
			_velocity = v;
			//prev = curr.minus(v);	
		}
		
		public override function update(dt2:Number):void {
			if (!fixedPosition) {		
				// integrate position
				temp.copy(curr);
				
				//var nv:Vector = velocity.plus(forces.multEquals(dt2));
				//curr.plusEquals(nv.multEquals(APEngine.damping));
				curr.plusEquals(velocity.mult(APEngine.damping));
				prev.copy(temp);
				
				// global forces
				addForce(APEngine.force);
				addMasslessForce(APEngine.masslessForce);
				
				velocity.plusEquals(forces.multEquals(dt2));

				// clear the forces
				forces.setTo(0,0);
			}
			//if(atRest)	return;
			radian -= angVelocity;
			angVelocity -= netTorque * invInertia * dt2;			
			netTorque = 0;
		}
		
		public override function resolveVelocities(dv:Vector, dw:Number, normal:Vector):void{
			if(!fixedPosition){
				velocity.plusEquals(dv);
				angVelocity += dw * .5;
			}else if(invInertia > 0){
				angVelocity += dw * .5;
			}
		}
		
		public function get netTorque():Number {
			return _netTorque;
		}
		
		public function set netTorque(n:Number):void{
			_netTorque = n;
		}
	}
}