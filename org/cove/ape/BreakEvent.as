package org.cove.ape {
	
	import flash.events.Event;
	
	public class BreakEvent extends Event {
		
		/**
		 * Defines the value of the type property of a collide event object
		 */
		public static const ANGULAR:String = "angular";
		public static const LENGTH:String = "length";
		
		private var _magnitude:Number;
		
		public function BreakEvent(
				type:String,
				magnitude:Number,
				bubbles:Boolean = false, 
				cancelable:Boolean = false) {
			
			super(type, bubbles, cancelable);
			_magnitude = Math.abs(magnitude);
		}
		
		public function get magnitude():Number{
			return _magnitude;
		}
	}
}
