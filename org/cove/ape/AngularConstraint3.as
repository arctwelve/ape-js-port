package org.cove.ape {
	
	import flash.display.Sprite;
	import flash.display.DisplayObject;
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	
	/**
	 * An angle constraint between a rigid body and a spring constraint.  only the rigid body resolves
	 */
	public class AngularConstraint3 extends AbstractConstraint {
		
		private var _p1:AbstractParticle;
		private var _spring1:SpringConstraint;	
		
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
		public function AngularConstraint3(
				p1:AbstractParticle, 
				spring1:SpringConstraint,
				minAng:Number,
				maxAng:Number,
				stiffness:Number = 1
				) {
			
			super(stiffness);
			
			this.p1 = p1;
			this.spring1 = spring1;
			_minAng = minAng;
			this.maxAng = maxAng;
		}
		
		private function get currAngle():Number{
			//trace(" "+p1.radian);
			//trace("  "+spring1.radian);
			var ang1:Number = p1.radian;
			var ang2:Number = spring1.radian;
			
			var ang:Number = ang1 - ang2;
			while (ang > Math.PI) ang -= MathUtil.TWO_PI;
			while (ang < -Math.PI) ang += MathUtil.TWO_PI;
			
			return ang;
		}
		
		/**
		 * @private
		 */	
		/*
		public override function resolve():void {
			var ca:Number = currAngle;
			//trace(ca);
			var delta:Number;
			
			if(ca < minAng){
				delta = ca - minAng;
			}else if(ca > maxAng){
				delta = ca - maxAng;
			}else{
				return;
			}
			
			while (delta > Math.PI) delta -= MathUtil.TWO_PI;
			while (delta < -Math.PI) delta += MathUtil.TWO_PI;
			
			//trace(" "+delta);
			//var invInertiaTotal:Number = p1.invInertia + p2.invInertia;
			//var deltaAng1:Number = delta * p1.invInertia/invInertiaTotal;
			//var deltaAng2:Number = delta * -p2.invInertia/invInertiaTotal;
			
			p1.angVelocity += delta;
			//p2.angVelocity += deltaAng2;			
		}
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
			
			p1.angVelocity -= delta * stiffness;			
		}
		
		
		public function get p1():AbstractParticle{
			return _p1;
		}
		
		public function set p1(p:AbstractParticle):void{
			_p1 = p;
		}
		
		public function get spring1():SpringConstraint{
			return _spring1;
		}
		
		public function set spring1(s:SpringConstraint):void{
			_spring1 = s;
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