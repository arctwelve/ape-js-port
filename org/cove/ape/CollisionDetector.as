/*
Copyright (c) 2006, 2007 Alec Cove

Permission is hereby granted, free of charge, to any person obtaining a copy of this 
software and associated documentation files (the "Software"), to deal in the Software 
without restriction, including without limitation the rights to use, copy, modify, 
merge, publish, distribute, sublicense, and/or sell copies of the Software, and to 
permit persons to whom the Software is furnished to do so, subject to the following 
conditions:

The above copyright notice and this permission notice shall be included in all copies 
or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, 
INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF 
CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE 
OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

/*
TODO:
- Get rid of all the object testing and use the double dispatch pattern
- There's some physical differences in collision response for multisampled
  particles, probably due to prev/curr differences.
*/ 
package org.cove.ape {
	import flash.filters.ColorMatrixFilter;
	import flash.geom.Matrix;
	import flash.geom.Rectangle;

	internal final class CollisionDetector {	
		
		
		/**
		 * Tests the collision between two objects. If there is a collision it is passed off
		 * to the CollisionResolver class.
		 */	
		internal static function test(objA:AbstractParticle, objB:AbstractParticle):void {
			objA.samp.copy(objA.curr);
			objB.samp.copy(objB.curr);
			testTypes(objA, objB);			
		}
		
		/**
		 *
		 */	
		private static function testTypes(objA:AbstractParticle, objB:AbstractParticle):Boolean {
			if(objA is PolygonParticle){
				if(objB is PolygonParticle){
					//return testOBBvsOBB(objA as RectangleParticle, objB as RectangleParticle);
					//return testPolygonvsPolygon(objA as PolygonParticle, objB as PolygonParticle);
					if(objA is PolygonBody || objB is PolygonBody){
						return testRigidvsRigid(objA as PolygonParticle, objB as PolygonParticle);
					}else{
						return testPolygonvsPolygon(objA as PolygonParticle, objB as PolygonParticle);
					}					
				}else if(objB is CircleParticle){
					if(objA is PolygonBody || objB is CircleBody){
						return testPolygonBodyvsCircleBody(objA as PolygonParticle, objB as CircleParticle);
					}else{
						return testPolygonParticlevsCircleParticle(objA as PolygonParticle, objB as CircleParticle);
					}
				}
			}else if(objA is CircleParticle){
				if(objB is PolygonParticle){
					if(objA is CircleBody || objB is PolygonBody){
						return testPolygonBodyvsCircleBody(objB as PolygonParticle, objA as CircleParticle);
					}else{
						return testPolygonParticlevsCircleParticle(objB as PolygonParticle, objA as CircleParticle);
					}
				}else if(objB is CircleParticle){
					return testCirclevsCircle(objA as CircleParticle, objB as CircleParticle);
				}
			}
			/*
			if(objA is RectangleParticle){
				if(objB is RectangleParticle){
					//return testRigidvsRigid(objA as RectangleParticle, objB as RectangleParticle);
					return testOBBvsOBB(objA as RectangleParticle, objB as RectangleParticle);
				}else if(objB is CircleParticle){
					return testOBBvsCircle(objA as RectangleParticle, objB as CircleParticle);
				}else if(objB is TriangleParticle){
					return testOBBvsTriangle(objA as RectangleParticle, objB as TriangleParticle);
				}
			} else if(objA is CircleParticle){
				if(objB is RectangleParticle){
					return testOBBvsCircle(objB as RectangleParticle, objA as CircleParticle);
				}else if(objB is CircleParticle){
					return testCirclevsCircle(objA as CircleParticle, objB as CircleParticle);
				}else if(objB is TriangleParticle){
					return testCirclevsTriangle(objA as CircleParticle, objB as TriangleParticle);
				}
			} else if(objA is TriangleParticle){
				if(objB is RectangleParticle){
					return testOBBvsTriangle(objB as RectangleParticle, objA as TriangleParticle);
				}else if(objB is CircleParticle){
					return testCirclevsTriangle(objB as CircleParticle, objA as TriangleParticle);
				}else if(objB is TriangleParticle){
					return testTrianglevsTriangle(objA as TriangleParticle, objB as TriangleParticle);
				}
			}
			*/
			return false;
		}
		
		private static function testRigidvsRigid(ra:PolygonParticle, rb:PolygonParticle):Boolean{
			
			var offset:Vector = (ra.curr.minus(rb.curr));
			
			var collisionNormal:Vector;
			var collisionDepth:Number = Number.POSITIVE_INFINITY;
			var currAxis:Vector = new Vector();
			
			//test separation axes of A
			var axes:Array = ra.getAxes();
			for(var i:int = 0; i < axes.length; i++){
				currAxis = axes[i];
				var depthA:Number = testIntervals(ra.getProjection(currAxis), rb.getProjection(currAxis));
				if (depthA == 0) return false;
				var absA:Number = Math.abs(depthA);
				if (absA < Math.abs(collisionDepth)) {
			    	collisionNormal = currAxis;
			    	collisionDepth = depthA;
			    }
			}
			
			//test separation axes of B
			axes = rb.getAxes();
			for(i = 0; i < axes.length; i++){
				currAxis = axes[i];
				var depthB:Number = testIntervals(ra.getProjection(currAxis), rb.getProjection(currAxis));
				if (depthB == 0) return false;
				var absB:Number = Math.abs(depthB);
				if (absB < Math.abs(collisionDepth)) {
			    	collisionNormal = currAxis;
			    	collisionDepth = depthB;
			    }
			}
			
			if (collisionNormal.dot(offset) < 0){
				collisionNormal.multEquals(-1);
			}
			
			var ca:Array = new Array();
			var cb:Array = new Array();
			var cNum:int = findContacts(ra, rb, collisionNormal, ca, cb);
			
			CollisionResolver.solve(ca, cb, cNum, collisionNormal, collisionDepth, ra, rb);
			return true;
		}
		
		private static function findContacts(ra:PolygonParticle, rb:PolygonParticle, normal:Vector, ca:Array, cb:Array):int{
			
			var s0:Array = findSupportPoints(normal, ra);
			var s1:Array = findSupportPoints(normal.mult(-1), rb);
			
			var cNum:int = convertSupportPointsToContacts(normal, s0, s1, ca, cb);
			
			return cNum;			
		}
		
		private static function findContactsPolygonCircle(pa:PolygonParticle, ca:CircleParticle, normal:Vector, depth:Number, contacts:Array):void{
			
			var polySupportPoints:Array = findSupportPoints(normal, pa);
			//trace(polySupportPoints);
			
			if(polySupportPoints.length == 1){
				//trace("one support point");
				contacts.push(polySupportPoints[0]);
			}else{
				//trace("two support points");
				contacts.push(projectPointOnSegment(ca.samp, polySupportPoints[0], polySupportPoints[1]));
				
			}
			
			contacts.push(contacts[0].minus(normal.mult(depth)));
		}
		
		private static function convertSupportPointsToContacts(normal:Vector, s0:Array, s1:Array, c0:Array, c1:Array):int{
			var cNum:int = 0;
			var s0num:int = s0.length;
			var s1num:int = s1.length;
			if(s0num == 0 || s1num == 0){
				return 0;
			}
			if(s0num == 1 && s1num == 1){
				c0[cNum] = s0[0];
				c1[cNum] = s1[0];
				cNum ++;
				return cNum;
			}
			var xPerp:Vector = new Vector(-normal.y, normal.x);
			
			var currS0:Vector = s0[0];
			var currS1:Vector = s1[0];
			var min0:Number = currS0.dot(xPerp);
			var max0:Number = min0;
			var min1:Number = currS1.dot(xPerp);
			var max1:Number = min1;
			
			if(s0num == 2){
				currS0 = s0[1];
				max0 = currS0.dot(xPerp);
				if(max0 < min0){
					var temp0:Number = min0;
					min0 = max0;
					max0 = temp0;
					var tempVec0:Vector = s0[0];
					s0[0] = s0[1];
					s0[1] = tempVec0;
				}
			}
			if(s1num == 2){
				currS1 = s1[1];
				max1 = currS1.dot(xPerp);
				if(max1 < min1){
					var temp1:Number = min1;
					min1 = max1;
					max1 = temp1;
					var tempVec1:Vector = s1[0];
					s1[0] = s1[1];
					s1[1] = tempVec1;
				}
			}
			
			if(min0 > max1 || min1 > max0){
				return 0;
			}
			
			var pSeg:Vector;
			if(min0 > min1){
				pSeg = projectPointOnSegment(s0[0], s1[0], s1[1]);
				if(pSeg){
					c0[cNum] = s0[0];
					c1[cNum] = pSeg;
					cNum++;
				}
			}else{
				pSeg = projectPointOnSegment(s1[0], s0[0], s0[1]);
				if(pSeg){
					c0[cNum] = pSeg;
					c1[cNum] = s1[0];
					cNum++;
				}
			}
			
			if(max0 != min0 && max1 != min1){
				if(max0 < max1){
					pSeg = projectPointOnSegment(s0[1], s1[0], s1[1]);
					if(pSeg){
						c0[cNum] = s0[1];
						c1[cNum] = pSeg;
						cNum++;
					}
				}else{
					pSeg = projectPointOnSegment(s1[1], s0[0], s0[1]);
					if(pSeg){
						c0[cNum] = pSeg;
						c1[cNum] = s1[1];
						cNum++;
					}
				}
			}
			return cNum;
		}
		
		private static function projectPointOnSegment(v:Vector, a:Vector, b:Vector):Vector{
			
			var AV:Vector = v.minus(a);
			var AB:Vector = b.minus(a);
			var t:Number = (AV.dot(AB))/(AB.dot(AB));
			
			if(t < 0){
				t = 0;
			}else if (t > 1){
				t = 1;
			}
			
			var point:Vector = a.plus(AB.mult(t));
			return point;
		}
		
		private static function findSupportPoints(normal:Vector, rp:PolygonParticle):Array{
			
			var supportPoints:Array = new Array();
			var vertices:Array = rp.vertices;
			
			var norm:Vector = normal;
			var d:Array = new Array();
			var dmin:Number;
			
			var currVert:Vector = vertices[0];
			dmin = d[0] = currVert.dot(norm);
			
			// this seems redundant... we've already calculated dot products relative to the normal before
			for(var i:int = 1; i < rp.numVertices; i++){
				currVert = vertices[i];
				d[i] = currVert.dot(norm);
				if(d[i] < dmin){
					dmin = d[i];
				}
			}
			
			// we limit the number of support points to only 2. 
			var threshold:Number = dmin + .5;//.003 originally
			
			for(i = 0; i < rp.numVertices; i++){
				if(d[i] < threshold && supportPoints.length < 2){
					var contact:Vector = rp.position.plus(vertices[i]);
					supportPoints.push(contact);
				}
			}
			return supportPoints;			
		}
		
		private static function testPolygonvsPolygon(ra:PolygonParticle, rb:PolygonParticle):Boolean{
			
			var collisionNormal:Vector;
			var collisionDepth:Number = Number.POSITIVE_INFINITY;
			var currAxis:Vector = new Vector();
			
			//test separation axes of A
			var axes:Array = ra.getAxes();
			for(var i:int = 0; i < axes.length; i++){
				currAxis = axes[i];
				var depthA:Number = testIntervals(ra.getProjection(currAxis), rb.getProjection(currAxis));
				if (depthA == 0) return false;
				var absA:Number = Math.abs(depthA);
				if (absA < Math.abs(collisionDepth)) {
			    	collisionNormal = currAxis;
			    	collisionDepth = depthA;
			    }
			}
			
			//test separation axes of B
			axes = rb.getAxes();
			for(i = 0; i < axes.length; i++){
				currAxis = axes[i];
				var depthB:Number = testIntervals(ra.getProjection(currAxis), rb.getProjection(currAxis));
				if (depthB == 0) return false;
				var absB:Number = Math.abs(depthB);
				if (absB < Math.abs(collisionDepth)) {
			    	collisionNormal = currAxis;
			    	collisionDepth = depthB;
			    }
			}
			
			CollisionResolver.resolveParticleParticle(ra, rb, collisionNormal, collisionDepth);
			return true;
		}
		
		private static function testPolygonBodyvsCircleBody(pa:PolygonParticle, ca:CircleParticle){
			var offset:Vector = (pa.curr.minus(ca.curr));
			
			var collisionNormal:Vector;
			var collisionDepth:Number = Number.POSITIVE_INFINITY;
			var depths:Array = new Array();
			var currAxis:Vector = new Vector();
			
			var vertReg:Boolean = true;
			var r:Number = ca.radius;
			
			//test separation axes of polygon
			var axes:Array = pa.getAxes();
			for(var i:int = 0; i < axes.length; i++){
				currAxis = axes[i];
				var depthA:Number = testIntervals(pa.getProjection(currAxis), ca.getProjection(currAxis));
				if (depthA == 0) return false;
				if (depthA > 0) depthA *= -1;
				var absA:Number = Math.abs(depthA);
				if (absA < Math.abs(collisionDepth)) {
			    	collisionNormal = currAxis;
			    	collisionDepth = depthA;
			    }
				depths[i] = depthA;
				if(absA > r){
					vertReg = false;
				}
			}
			
			//trace("testing");
			var contacts:Array = new Array();
			
			// determine if the circle's center is in a vertex region
			if(vertReg){
				var vertex:Vector = pa.getClosestVertex(ca.samp);//closestVertexOnPolygon(ca.samp, pa);
				
				// get the distance from the closest vertex on rect to circle center
				collisionNormal = vertex.minus(ca.samp);
				
				var mag:Number = collisionNormal.magnitude();
				collisionDepth = r - mag;
				
				if (collisionDepth > 0) {
					//trace("vertReg");
					// there is a collision in one of the vertex regions
					collisionNormal.divEquals(mag);
					contacts.push(vertex);
					contacts.push(ca.samp.plus(collisionNormal.mult(r)));
				} else {
					// pa is in vertex region, but is not colliding
					return false;
				}
			}
			
			//if (collisionNormal.dot(offset) < 0){
			//	trace("reversed");
			//	collisionNormal.multEquals(-1);
			//}
			
			if(contacts.length == 0){
				//trace("findContacts");
				if (collisionNormal.dot(offset) < 0){
					//trace("reversed");
					collisionNormal.multEquals(-1);
				}
				findContactsPolygonCircle(pa, ca, collisionNormal, collisionDepth, contacts);
			}
			
			//trace("contacts "+contacts);
			//trace("depth "+collisionDepth);
			//trace("normal "+collisionNormal);
			CollisionResolver.solvePolyCircle(contacts[0], contacts[1], collisionNormal, collisionDepth, pa, ca);
			return true;
		}
		
		private static function testPolygonParticlevsCircleParticle(pa:PolygonParticle, ca:CircleParticle){
			if(pa is RectangleParticle){
				//return testOBBvsCircle(pa as RectangleParticle, ca);
			}
			
			var collisionNormal:Vector;
			var collisionDepth:Number = Number.POSITIVE_INFINITY;
			var depths:Array = new Array();
			var currAxis:Vector = new Vector();
			
			var vertReg:Boolean = true;
			var r:Number = ca.radius;
			
			//test separation axes of polygon
			var axes:Array = pa.getAxes();
			//trace(axes);
			for(var i:int = 0; i < axes.length; i++){
				currAxis = axes[i];
				var depthA:Number = testIntervals(pa.getProjection(currAxis), ca.getProjection(currAxis));
				if (depthA == 0) return false;
				var absA:Number = Math.abs(depthA);
				if (absA < Math.abs(collisionDepth)) {
			    	collisionNormal = currAxis;
			    	collisionDepth = depthA;
			    }
				depths[i] = depthA;
				if(absA > r){
					vertReg = false;
				}
			}
			
			// determine if the circle's center is in a vertex region
			if(vertReg){
				var vertex:Vector = pa.getClosestVertex(ca.samp);//closestVertexOnPolygon(ca.samp, pa);
				
				// get the distance from the closest vertex on rect to circle center
				collisionNormal = vertex.minus(ca.samp);
				
				var mag:Number = collisionNormal.magnitude();
				collisionDepth = r - mag;
				
				if (collisionDepth > 0) {
					// there is a collision in one of the vertex regions
					collisionNormal.divEquals(mag);
				} else {
					// pa is in vertex region, but is not colliding
					return false;
				}
			}
			CollisionResolver.resolveParticleParticle(pa, ca, collisionNormal, collisionDepth);
			return true;
		}
		
		
		/**
		 * Tests the collision between two RectangleParticles (aka OBBs). If there is a collision it
		 * determines its axis and depth, and then passes it off to the CollisionResolver for handling.
		 */
		private static function testOBBvsOBB(ra:RectangleParticle, rb:RectangleParticle):Boolean {
			
			var collisionNormal:Vector;
			var collisionDepth:Number = Number.POSITIVE_INFINITY;
			
			for (var i:int = 0; i < 2; i++) {
		
			    var axisA:Vector = ra.axes[i];
			    var depthA:Number = testIntervals(ra.getProjection(axisA), rb.getProjection(axisA));
			    if (depthA == 0) return false;
				
			    var axisB:Vector = rb.axes[i];
			    var depthB:Number = testIntervals(ra.getProjection(axisB), rb.getProjection(axisB));
			    if (depthB == 0) return false;
			    
			    var absA:Number = Math.abs(depthA);
			    var absB:Number = Math.abs(depthB);
			    
			    if (absA < Math.abs(collisionDepth) || absB < Math.abs(collisionDepth)) {
			    	var altb:Boolean = absA < absB;
			    	collisionNormal = altb ? axisA : axisB;
			    	collisionDepth = altb ? depthA : depthB;
			    }
			}
			CollisionResolver.resolveParticleParticle(ra, rb, collisionNormal, collisionDepth);
			return true;
		}		
	
	
		/**
		 * Tests the collision between a RectangleParticle (aka an OBB) and a CircleParticle. 
		 * If there is a collision it determines its axis and depth, and then passes it off 
		 * to the CollisionResolver.
		 */
		private static function testOBBvsCircle(ra:RectangleParticle, ca:CircleParticle):Boolean {
			trace("testing");
			var collisionNormal:Vector;
			var collisionDepth:Number = Number.POSITIVE_INFINITY;
			var depths:Array = new Array(2);
			
			// first go through the axes of the rectangle
			trace(ra.axes);
			for (var i:int = 0; i < 2; i++) {
	
				var boxAxis:Vector = ra.axes[i];
				var depth:Number = testIntervals(ra.getProjection(boxAxis), ca.getProjection(boxAxis));
				if (depth == 0) return false;
	
				if (Math.abs(depth) < Math.abs(collisionDepth)) {
					collisionNormal = boxAxis;
					collisionDepth = depth;
				}
				depths[i] = depth;
			}	
			
			// determine if the circle's center is in a vertex region
			var r:Number = ca.radius;
			if (Math.abs(depths[0]) < r && Math.abs(depths[1]) < r) {
				trace("oh");				
				var vertex:Vector = closestVertexOnOBB(ca.samp, ra);
	
				// get the distance from the closest vertex on rect to circle center
				collisionNormal = vertex.minus(ca.samp);
				
				var mag:Number = collisionNormal.magnitude();
				collisionDepth = r - mag;
	
				if (collisionDepth > 0) {
					// there is a collision in one of the vertex regions
					collisionNormal.divEquals(mag);
				} else {
					// ra is in vertex region, but is not colliding
					return false;
				}
			}
			CollisionResolver.resolveParticleParticle(ra, ca, collisionNormal, collisionDepth);
			return true;
		}
		
		/**
		 * Tests the collision between  CircleParticles. If there is a collision it 
		 * determines its axis and depth, and then passes it off to the CollisionResolver
		 * for handling.
		 */	
		private static function testCirclevsCircle(ca:CircleParticle, cb:CircleParticle):Boolean {
			
			var depthX:Number = testIntervals(ca.getIntervalX(), cb.getIntervalX());
			if (depthX == 0) return false;
			
			var depthY:Number = testIntervals(ca.getIntervalY(), cb.getIntervalY());
			if (depthY == 0) return false;
			
			var collisionNormal:Vector = ca.samp.minus(cb.samp);
			var mag:Number = collisionNormal.magnitude();
			var collisionDepth:Number = (ca.radius + cb.radius) - mag;
			
			if (collisionDepth > 0) {
				collisionNormal.divEquals(mag);
				if(ca is CircleBody || cb is CircleBody){
					var contactA:Vector = ca.samp.minus(collisionNormal.mult(ca.radius));
					var contactB:Vector = cb.samp.plus(collisionNormal.mult(cb.radius));
					CollisionResolver.solvePolyCircle(contactA, contactB, collisionNormal, collisionDepth, ca, cb);
					return true;
				}
				CollisionResolver.resolveParticleParticle(ca, cb, collisionNormal, collisionDepth);
				return true;
			}
			return false;
		}
		
		/**
		 * Returns 0 if intervals do not overlap. Returns smallest depth if they do.
		 */
		private static function testIntervals(intervalA:Interval, intervalB:Interval):Number {
			
			if (intervalA.max < intervalB.min) return 0;
			if (intervalB.max < intervalA.min) return 0;
			
			var lenA:Number = intervalB.max - intervalA.min;
			var lenB:Number = intervalB.min - intervalA.max;
			
			return (Math.abs(lenA) < Math.abs(lenB)) ? lenA : lenB;
		}
		
		
		/**
		 * Returns the location of the closest vertex on r to point p
		 */
	 	private static function closestVertexOnOBB(p:Vector, r:RectangleParticle):Vector {
	
			var d:Vector = p.minus(r.samp);
			var q:Vector = new Vector(r.samp.x, r.samp.y);
	
			for (var i:int = 0; i < 2; i++) {
				var dist:Number = d.dot(r.axes[i]);
	
				if (dist >= 0) dist = r.extents[i];
				else if (dist < 0) dist = -r.extents[i];
	
				q.plusEquals(r.axes[i].mult(dist));
			}
			return q;
		}
		
		private static function closestVertexOnPolygon(v:Vector, p:PolygonParticle):Vector {
			var verts:Array = p.vertices;
			var d:Vector = v.minus(p.samp);
			var maxDist:Number = 0;
			var index:int = -1;
			
			for(var i:int = 0; i<verts.length; i++){
				var dist:Number = d.dot(verts[i]);
				if(dist > maxDist){
					maxDist = dist;
					index = i;
				}
			}
			//trace("closest vertex = "+verts[index].plus(p.samp));
			return verts[index].plus(p.samp);
		}
	}
}
