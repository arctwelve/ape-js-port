package org.cove.ape {
	
	import flash.events.Event;
	
	public class SmashEvent extends Event {
		
		/**
		 * Defines the value of the type property of a collide event object
		 */
		public static const COLLISION:String = "collision";
		
		private var _exitVelocity:Number;
		
		public function SmashEvent(
				type:String,
				exitVelocity:Number,
				bubbles:Boolean = false, 
				cancelable:Boolean = false) {
			
			super(type, bubbles, cancelable);
			_exitVelocity = exitVelocity;
		}
		
		public function get exitVelocity():Number{
			return _exitVelocity;
		}
	}
}
