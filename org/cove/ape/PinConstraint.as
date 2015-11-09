package org.cove.ape {
	
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * A Pin constraint that connects two particles
	 */
	public class PinConstraint extends AbstractConstraint {
		
		private var _p1:AbstractParticle;
		private var _p2:AbstractParticle;	
		
		private var _pin1:Vector;
		private var _pin2:Vector;
		
		private var _breakable:Boolean;
		
		/**
		 * @param p1 The first particle this constraint is connected to.
		 * @param p2 The second particle this constraint is connected to.
		 * @param pin1 A vector of displacement from the center of mass for the pin of particle 1 at radian 0
		 * @param pin2 A vector of displacement from the center of mass for the pin of particle 2 at radian 0
		 */
		public function PinConstraint(
				p1:AbstractParticle, 
				p2:AbstractParticle,
				pin1:Vector,
				pin2:Vector,
				stiffness:Number = 0.5,
				breakable:Boolean = false
				) {
			
			super(stiffness);
			
			this.p1 = p1;
			this.p2 = p2;
			this.pin1 = pin1;
			this.pin2 = pin2;
			
			this.breakable = breakable;
		}
		
		/**
		 * Returns the length of the SpringConstraint, the distance between its two 
		 * attached particles.
		 */ 
		public function get currLength():Number {
			return p1.curr.distance(p2.curr);
		}
		
		
		public function set breakable(b:Boolean):void {
			_breakable = b;
		}
		
		public function get breakable():Boolean {
			return _breakable;
		}
		
		/**
		 * Returns true if the passed particle is one of the two particles attached to this SpringConstraint.
		 */		
		public function isConnectedTo(p:AbstractParticle):Boolean {
			return (p == p1 || p == p2);
		}
		
		
		/**
		 * Sets up the visual representation of this SpringContraint. This method is called 
		 * automatically when an instance of this SpringContraint's parent Group is added to 
		 * the APEngine, when  this SpringContraint's Composite is added to a Group, or this 
		 * SpringContraint is added to a Composite or Group.
		 */			
		public override function init():void {	
			cleanup();
			if (displayObject != null) {
				initDisplay();
			}
			paint();
		}
		
				
		/**
		 * The default painting method for this constraint. This method is called automatically
		 * by the <code>APEngine.paint()</code> method. If you want to define your own custom painting
		 * method, then create a subclass of this class and override <code>paint()</code>.
		 */			
		public override function paint():void {
			
		}
		
		
		/**
		 * Assigns a DisplayObject to be used when painting this constraint.
		 */ 
		public function setDisplay(d:DisplayObject, offsetX:Number=0, 
				offsetY:Number=0, rotation:Number=0):void {
			
			displayObject = d;
			displayObjectRotation = rotation;
			displayObjectOffset = new Vector(offsetX, offsetY);
		}
		
		
		/**
		 * @private
		 */
		internal function initDisplay():void {
			displayObject.x = displayObjectOffset.x;
			displayObject.y = displayObjectOffset.y;
			displayObject.rotation = displayObjectRotation;
			sprite.addChild(displayObject);
		}
		
		/**
		 * @private
		 */		
		internal function get delta():Vector {
			return p1.curr.minus(p2.curr);
		}		


		/**
		 * @private
		 */			
		public override function resolve():void {
			var currPin1:Vector = p1.position.plus(pin1.rotate(p1.radian));
			var r1:Vector = currPin1.minus(p1.position);
			
			var currPin2:Vector = p2.position.plus(pin2.rotate(p2.radian));
			var r2:Vector  = currPin2.minus(p2.position);
			
			var pinVec:Vector = currPin2.minus(currPin1);
			var normal:Vector = pinVec.normalize();
			
			// compute impulse for displacement
			
			var t1:Number = (r1.cross(normal)) * (r1.cross(normal)) * p1.invInertia;
			var t2:Number = (r2.cross(normal)) * (r2.cross(normal)) * p2.invInertia;
			var invMass1:Number = p1.invMass;
			var invMass2:Number = p2.invMass;
			var invMassTotal = invMass1 + invMass2;
			
			var J:Number = -1/(invMassTotal + t1 + t2);
			
			p1.curr.plusEquals(pinVec.mult(-J*invMass1));
			p2.curr.plusEquals(pinVec.mult(J*invMass2));
			p1.prev.plusEquals(pinVec.mult(-J*invMass1));
			p2.prev.plusEquals(pinVec.mult(J*invMass2));
			
			// compute impulse again for velocities
			
			var perpin1:Vector = new Vector(-r1.y, r1.x);
			var perpin2:Vector = new Vector(-r2.y, r2.x);
			var pin1Vel:Vector = p1.velocity.minus(perpin1.mult(p1.angVelocity));
			var pin2Vel:Vector = p2.velocity.minus(perpin2.mult(p2.angVelocity));
			
			var pinVel:Vector = pin1Vel.minus(pin2Vel);
			normal = pinVel.normalize();
			
			t1 = (r1.cross(normal)) * (r1.cross(normal)) * p1.invInertia;
			t2 = (r2.cross(normal)) * (r2.cross(normal)) * p2.invInertia;
			
			J = -1/(invMassTotal + t1 + t2);
			
			p1.velocity.plusEquals(pinVel.mult(J*invMass1));
			p2.velocity.plusEquals(pinVel.mult(-J*invMass2));
			
			p1.angVelocity += r1.cross(pinVel.mult(J)) * -p1.invInertia;
			p2.angVelocity += r2.cross(pinVel.mult(J)) * p2.invInertia;
		}
		
		public function get p1():AbstractParticle{
			return _p1;
		}
		
		public function set p1(p:AbstractParticle):void{
			_p1 = p;
		}
		
		public function get p2():AbstractParticle{
			return _p2;
		}
		
		public function set p2(p:AbstractParticle):void{
			_p2 = p;
		}
		
		public function get pin1():Vector{
			return _pin1;
		}
		
		public function set pin1(v:Vector):void{
			_pin1 = v;
		}
		
		public function get pin2():Vector{
			return _pin2;
		}
		
		public function set pin2(v:Vector):void{
			_pin2 = v;
		}
	}
}
