package org.cove.ape {
	
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * An Angular Constraint between 3 particles
	 */
	public class AngularConstraint extends SpringConstraint{
		
		private var _p3:AbstractParticle;
		
		private var _minAng:Number;
		private var _maxAng:Number;
		private var _minBreakAng:Number;
		private var _maxBreakAng:Number;
		
		public function AngularConstraint(
				p1:AbstractParticle, 
				p2:AbstractParticle,
				p3:AbstractParticle,
				minAng:Number,
				maxAng:Number,
				minBreakAng:Number = -10,
				maxBreakAng:Number = 10,
				stiffness:Number = .5,
				dependent:Boolean = false,
				collidable:Boolean = false,
				rectHeight:Number = 1,
				rectScale:Number = 1,
				scaleToLength:Boolean = false)
				{
			
			super(p1, p2, stiffness, false, dependent, collidable, rectHeight, rectScale, scaleToLength);
			
			this.p3 = p3;
			
			if(minAng == 10){
				this.minAng = acRadian;
				this.maxAng = acRadian;
			}else{
				this.minAng = minAng;
				this.maxAng = maxAng;
			}
			this.minBreakAng = minBreakAng;
			this.maxBreakAng = maxBreakAng;
		}
		
		public function get p3():AbstractParticle{
			return _p3;
		}
		
		public function set p3(p:AbstractParticle){
			_p3 = p;
		}
		
		/**
		 * The current difference between the angle of p1, p2, and p3 and a straight line (pi)
		 * 
		 */	
		public function get acRadian():Number{
			var ang12:Number = Math.atan2(p2.curr.y - p1.curr.y, p2.curr.x - p1.curr.x);
			var ang23:Number = Math.atan2(p3.curr.y - p2.curr.y, p3.curr.x - p2.curr.x);
			
			var angDiff:Number = ang12 - ang23;
			return angDiff;
		}
		
		/**
		 * Returns true if the passed particle is one of the two particles attached to this AngularConstraint.
		 */		
		public override function isConnectedTo(p:AbstractParticle):Boolean {
			return (p == p1 || p == p2 || p == p3);
		}		
		
		/**
		 * Returns true if any connected particle's <code>fixed</code> property is true.
		 */
		public override function get fixedPosition():Boolean {
			return (p1.fixedPosition && p2.fixedPosition && p3.fixedPosition);
		}
		
		public function get minAng():Number{
			return _minAng;
		}
		
		public function set minAng(n:Number):void{
			_minAng = n;
		}
		
		public function get maxAng():Number{
			return _maxAng;
		}
		
		public function set maxAng(n:Number):void{
			_maxAng = n;
		}
		
		public function get minBreakAng():Number{
			return _minBreakAng;
		}
		
		public function set minBreakAng(n:Number):void{
			_minBreakAng = n;
		}
		
		public function get maxBreakAng():Number{
			return _maxBreakAng;
		}
		
		public function set maxBreakAng(n:Number):void{
			_maxBreakAng = n;
		}
		
		/**
		 * @private
		 */
		public override function resolve():void {
			if (broken) return;
			
			var PI2:Number = MathUtil.TWO_PI;
			
			var ang12:Number = Math.atan2(p2.curr.y - p1.curr.y, p2.curr.x - p1.curr.x);
			var ang23:Number = Math.atan2(p3.curr.y - p2.curr.y, p3.curr.x - p2.curr.x);
			
			var angDiff:Number = ang12 - ang23;
			while (angDiff > Math.PI) angDiff -= PI2;
			while (angDiff < -Math.PI) angDiff += PI2;
			
			var p2invMass:Number = (dependent == true) ? 0 : p2.invMass;
			
			var sumInvMass:Number = p1.invMass + p2invMass;
			var mult1:Number = p1.invMass/sumInvMass;
			var mult2:Number = p2invMass/sumInvMass;
			var angChange:Number = 0;
			
			var lowMid:Number = (maxAng - minAng) / 2;
			var highMid:Number = (maxAng + minAng) / 2;
     		var breakAng:Number = (maxBreakAng - minBreakAng)/2;
			
     		var newDiff:Number = highMid - angDiff;
			while (newDiff > Math.PI) newDiff -= PI2;
			while (newDiff < -Math.PI) newDiff += PI2;
			
			if (newDiff > lowMid){
				if(newDiff > breakAng){
					var diff = newDiff - breakAng;
					broken = true;
					if(hasEventListener(BreakEvent.ANGULAR)){
						dispatchEvent(new BreakEvent(BreakEvent.ANGULAR, diff));
					}
					return;
				}
				angChange = newDiff - lowMid;
			}else if (newDiff < -lowMid){
				if(newDiff < - breakAng){
					var diff2 = newDiff + breakAng;
					broken = true;
					if(hasEventListener(BreakEvent.ANGULAR)){
						dispatchEvent(new BreakEvent(BreakEvent.ANGULAR, diff2));
					}
					return;
				}
				angChange = newDiff + lowMid;
			}
			
			var finalAng:Number = angChange * this.stiffness + ang12;
			var displaceX:Number = p1.curr.x + (p2.curr.x - p1.curr.x) * mult1;
			var displaceY:Number = p1.curr.y + (p2.curr.y - p1.curr.y) * mult1;
    		p1.curr.x = displaceX + Math.cos(finalAng + Math.PI) * restLength * mult1;
    		p1.curr.y = displaceY + Math.sin(finalAng + Math.PI) * restLength * mult1;
			p2.curr.x = displaceX + Math.cos(finalAng) * restLength * mult2;
			p2.curr.y = displaceY + Math.sin(finalAng) * restLength * mult2;	
		}
		
	}
}
