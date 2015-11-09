package org.cove.ape {
	
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * A Spring-like constraint that connects two rigid bodies
	 */
	public class SpringConstraint2 extends AbstractConstraint {
		
		private var _p1:AbstractParticle;
		private var _p2:AbstractParticle;	
	
		private var _restLength:Number;
		
		public function SpringConstraint2(
				p1:AbstractParticle, 
				p2:AbstractParticle, 
				stiffness:Number = 0.5) {
			
			super(stiffness);
			
			this.p1 = p1;
			this.p2 = p2;
			checkParticlesLocation();
			
			_restLength = currLength;
		}
		
		
		/**
		 * The rotational value created by the positions of the two particles attached to this
		 * SpringConstraint. You can use this property to in your own painting methods, along with the 
		 * <code>center</code> property. 
		 * 
		 * @returns A Number representing the rotation of this SpringConstraint in radians
		 */			
		public function get radian():Number {
			var d:Vector = delta;
			return Math.atan2(d.y, d.x);
		}
		
		
		/**
		 * The rotational value created by the positions of the two particles attached to this
		 * SpringConstraint. You can use this property to in your own painting methods, along with the 
		 * <code>center</code> property. 
		 * 
		 * @returns A Number representing the rotation of this SpringConstraint in degrees
		 */					
		public function get angle():Number {
			return radian * MathUtil.ONE_EIGHTY_OVER_PI;
		}
		
				
		/**
		 * The center position created by the relative positions of the two particles attached to this
		 * SpringConstraint. You can use this property to in your own painting methods, along with the 
		 * rotation property.
		 * 
		 * @returns A Vector representing the center of this SpringConstraint
		 */			
		public function get center():Vector {
			return (p1.curr.plus(p2.curr)).divEquals(2);
		}
		
		
		/**
		 * Returns the length of the SpringConstraint, the distance between its two 
		 * attached particles.
		 */ 
		public function get currLength():Number {
			return p1.curr.distance(p2.curr);
		}
		
		
		/**
		 * The <code>restLength</code> property sets the length of SpringConstraint. This value will be
		 * the distance between the two particles unless their position is altered by external forces. 
		 * The SpringConstraint will always try to keep the particles this distance apart. Values must 
		 * be > 0.
		 */			
		public function get restLength():Number {
			return _restLength;
		}
		
		
		/**
		 * @private
		 */	
		public function set restLength(r:Number):void {
			if (r <= 0) throw new ArgumentError("restLength must be greater than 0");
			_restLength = r;
		}
		
		/**
		 * Returns true if the passed particle is one of the two particles attached to this SpringConstraint.
		 */		
		public function isConnectedTo(p:AbstractParticle):Boolean {
			return (p == p1 || p == p2);
		}
		
		/**
		 * Returns true if both connected particle's <code>fixed</code> property is true.
		 */
		public function get fixedPosition():Boolean {
			return (p1.fixedPosition && p2.fixedPosition);
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
			
			if (displayObject != null) {
				var c:Vector = center;
				sprite.x = c.x; 
				sprite.y = c.y;
				sprite.rotation = angle;
			} else {
				sprite.graphics.clear();
				sprite.graphics.lineStyle(lineThickness, lineColor, lineAlpha);
				sprite.graphics.moveTo(p1.px, p1.py);
				sprite.graphics.lineTo(p2.px, p2.py);	
			}
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
			
			if (p1.fixedPosition && p2.fixedPosition) return;
			
			//displacement
			
			var del:Vector = delta;
			var norm:Vector = delta.normalize();
			var deltaLength:Number = del.magnitude();
			var xError:Vector = norm.mult(stiffness*(restLength - deltaLength));
			
			var totalInvMass:Number = p1.invMass + p2.invMass;
			
			p1.curr = p1.curr.plus(xError.mult(p1.invMass/totalInvMass));
			p2.curr = p2.curr.minus(xError.mult(p2.invMass/totalInvMass));
			
			//velocties
			
			var delVel:Vector = p1.velocity.minus(p2.velocity);
			//trace(delVel.magnitude());
			//var vError:Vector = (delVel.dot(norm)).
			var vError:Vector = norm.mult(delVel.dot(norm) * stiffness);
			//trace(vError);
			
			p1.velocity = p1.velocity.minus(vError.mult(p1.invMass/totalInvMass));
			p2.velocity = p2.velocity.plus(vError.mult(p2.invMass/totalInvMass));
		}
		
		
		/**
		 * if the two particles are at the same location offset slightly
		 */
		private function checkParticlesLocation():void {
			if (p1.curr.x == p2.curr.x && p1.curr.y == p2.curr.y) {
				p2.curr.x += 0.0001;
			}
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
	}
}