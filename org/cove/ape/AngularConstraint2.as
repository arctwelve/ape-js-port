package org.cove.ape {
	
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * An angle constraint between rigid bodies
	 */
	public class AngularConstraint2 extends AbstractConstraint {
		
		private var _p1:AbstractParticle;
		private var _p2:AbstractParticle;	
		
		private var _minAng:Number;
		private var _maxAng:Number;
		
		private var _lowMid:Number;
		private var _highMid:Number;
		
		/**
		 * @param p1 The first particle this constraint is connected to.
		 * @param p2 The second particle this constraint is connected to.
		 * @param minAng The minimum angle of difference between both particles orientations
		 * @param maxAng The maximum angle of difference between both particles orientations
		 */
		public function AngularConstraint2(
				p1:AbstractParticle, 
				p2:AbstractParticle,
				minAng:Number,
				maxAng:Number,
				stiffness:Number = 1
				) {
			
			super(stiffness);
			
			this.p1 = p1;
			this.p2 = p2;
			_minAng = minAng;
			this.maxAng = maxAng;
		}
		
		private function get currAngle():Number{
			var ang1:Number = p1.radian;
			var ang2:Number = p2.radian;
			
			var ang:Number = ang1 - ang2;
			while (ang > Math.PI) ang -= MathUtil.TWO_PI;
			while (ang < -Math.PI) ang += MathUtil.TWO_PI;
			
			return ang;
		}
		
		/**
		 * @private
		 */			
		public override function resolve():void {
			var ca:Number = currAngle;
			var delta:Number;
			
			var diff:Number = _highMid - ca;
			while (diff > Math.PI) diff -= MathUtil.TWO_PI;
			while (diff < -Math.PI) diff += MathUtil.TWO_PI;
			
			if (diff > _lowMid){
				delta = diff - _lowMid;
			}else if (diff < - _lowMid){
				delta = diff + _lowMid;
			}else{
				return;
			}
			
			var invInertiaTotal:Number = p1.invInertia + p2.invInertia;
			var deltaAng1:Number = delta * p1.invInertia/invInertiaTotal;
			var deltaAng2:Number = delta * -p2.invInertia/invInertiaTotal;
			
			p1.angVelocity -= deltaAng1 * stiffness;
			p2.angVelocity -= deltaAng2 * stiffness;			
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
		
		public function get minAng():Number{
			return _minAng;
		}
		
		public function set minAng(n:Number):void{
			_minAng = n;
			calcMidAngles();
		}
		
		public function get maxAng():Number{
			return _maxAng;
		}
		
		public function set maxAng(n:Number):void{
			_maxAng = n;
			calcMidAngles();
		}
		
		private function calcMidAngles():void{
			_lowMid = (maxAng - minAng) / 2;
			_highMid = (maxAng + minAng) / 2;
		}
	}
}