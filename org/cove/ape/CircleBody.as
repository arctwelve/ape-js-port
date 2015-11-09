package org.cove.ape {
	
	public class CircleBody extends CircleParticle {
		
		internal var _radian:Number;
		
		internal var _inertia:Number;
		internal var _invInertia:Number;
		
		internal var _angVelocity:Number;
		internal var _netTorque:Number;
		
		public function CircleBody(
				x:Number, 
				y:Number, 
				radius:Number, 
				fixedPosition:Boolean = false, 
				mass:Number = 1, 
				elasticity:Number = 0.15,
				friction:Number = 0.1) {
			
			super(x,y,radius,fixedPosition, mass, elasticity, friction);
			_radian = 0;
			_netTorque = 0;
			_angVelocity = 0;
			inertia = calculateInertia();
		}
		
		public override function get radian():Number {
			return _radian;
		}
		
		public function set radian(t:Number):void {
			_radian = t;
		}
		
		public function get angle():Number {
			return radian * MathUtil.ONE_EIGHTY_OVER_PI;
		}
		
		public function set angle(a:Number):void {
			radian = a * MathUtil.PI_OVER_ONE_EIGHTY;
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
			var iner:Number = .5 * mass * Math.pow(_radius, 2);
			return iner;
		}
		
		public override function init():void {
			cleanup();
			if (displayObject != null) {
				initDisplay();
			} else {
				
				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);
				
				// wheel circle
				sprite.graphics.beginFill(fillColor, fillAlpha);
				sprite.graphics.drawCircle(0, 0, radius);
				sprite.graphics.endFill();
				
				// spokes
				sprite.graphics.moveTo(-radius, 0);
				sprite.graphics.lineTo( radius, 0);
				sprite.graphics.moveTo(0, -radius);
				sprite.graphics.lineTo(0, radius);
			}
			paint();
		}
		
		public override function paint():void {
			sprite.x = curr.x;
			sprite.y = curr.y;
			sprite.rotation = angle;
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
		