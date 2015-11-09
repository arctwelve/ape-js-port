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
	- fix the friction bug for two non-fixed particles in collision. The tangental
	  component should not be scaled/applied in all instances, depending on the velocity
	  of the other colliding item
*/ 
package org.cove.ape {
	
	// thanks to Jim Bonacci for changes using the inverse mass instead of mass
	
	internal final class CollisionResolver {
        
        internal static function resolveParticleParticle(
                pa:AbstractParticle, 
                pb:AbstractParticle, 
                normal:Vector, 
                depth:Number):void {
     		
     		// a collision has occured. set the current positions to sample locations
     		pa.curr.copy(pa.samp);
     		pb.curr.copy(pb.samp);
     		
            var mtd:Vector = normal.mult(depth);           
            var te:Number = pa.elasticity + pb.elasticity;
            var sumInvMass:Number = pa.invMass + pb.invMass;
            
            // the total friction in a collision is combined but clamped to [0,1]
            var tf:Number = 1;//clamp(1 - (pa.friction + pb.friction), 0, 1);
            
            // get the collision components, vn and vt
            var ca:Collision = pa.getComponents(normal);
            var cb:Collision = pb.getComponents(normal);

             // calculate the coefficient of restitution based on the mass, as the normal component
            var vnA:Vector = (cb.vn.mult((te + 1) * pa.invMass).plus(
            		ca.vn.mult(pb.invMass - te * pa.invMass))).divEquals(sumInvMass);
            var vnB:Vector = (ca.vn.mult((te + 1) * pb.invMass).plus(
            		cb.vn.mult(pa.invMass - te * pb.invMass))).divEquals(sumInvMass);
            
            // apply friction to the tangental component
            ca.vt.multEquals(tf);
            cb.vt.multEquals(tf);
            
            // scale the mtd by the ratio of the masses. heavier particles move less 
            var mtdA:Vector = mtd.mult( pa.invMass / sumInvMass);     
            var mtdB:Vector = mtd.mult(-pb.invMass / sumInvMass);
            
            // add the tangental component to the normal component for the new velocity 
            vnA.plusEquals(ca.vt);
            vnB.plusEquals(cb.vt);
           
            
			pa.resolveCollision(mtdA, vnA, normal, depth, -1, pb);
            pb.resolveCollision(mtdB, vnB, normal, depth,  1, pa);
        }
        
    
        internal static function clamp(input:Number, min:Number, max:Number):Number {
        	if (input > max) return max;	
            if (input < min) return min;
            return input;
        }
		
		internal static function solve(ca:Array, cb:Array, numContactPoints:int, normal:Vector, depthTime:Number, pa:AbstractParticle, pb:AbstractParticle):void{
			
			for(var i:int = 0; i < numContactPoints; i++){
				resolveOverlap(normal, depthTime, ca[i], cb[i], pa, pb);
			}
			
			var va:Vector = new Vector();
			va.copy(pa.velocity);
			var ava:Number = pa.angVelocity;
			var vb:Vector = new Vector();
			vb.copy(pb.velocity);
			var avb:Number = pb.angVelocity;
			for(var j:int = 0; j < numContactPoints; j++){
				resolveCollision(normal.mult(-1), depthTime, cb[j], ca[j], pb, pa, pb.velocity, pb.angVelocity, pa.velocity, pa.angVelocity);
			}			
		}
		
		internal static function solvePolyCircle(contactA:Vector, contactB:Vector, normal:Vector, depth:Number, pa:AbstractParticle, pb:AbstractParticle):void{
			resolveOverlap(normal, depth, contactA, contactB, pa, pb);
			var va:Vector = new Vector();
			va.copy(pa.velocity);
			var ava:Number = pa.angVelocity;
			var vb:Vector = new Vector();
			vb.copy(pb.velocity);
			var avb:Number = pb.angVelocity;
			resolveCollision(normal.mult(-1), depth, contactB, contactA, pb, pa, pb.velocity, pb.angVelocity, pa.velocity, pa.angVelocity);
		}
		
		internal static function resolveCollision(normal:Vector, depthTime:Number, c0:Vector, c1:Vector, pa:AbstractParticle, pb:AbstractParticle, va:Vector, ava:Number, vb:Vector, avb:Number):void{
			
			//pre-computations
			
			var r0:Vector = c0.minus(pa.curr);
			var r1:Vector = c1.minus(pb.curr);
			var T0:Vector = new Vector(-r0.y, r0.x);
			var T1:Vector = new Vector(-r1.y, r1.x);
			var vp0:Vector = va.minus(T0.mult(ava));
			var vp1:Vector = vb.minus(T1.mult(avb));
			
			//impact velocity
			
			var vcoll:Vector = vp0.minus(vp1);
			var vn:Number = vcoll.dot(normal);
			var Vn:Vector = normal.mult(vn);
			var Vt:Vector = vcoll.minus(Vn);
			
			//separation
			if(vn > 0){
				return;
			}
			var vt:Number = Vt.magnitude();
			//Vt.normalize();
			
			// compute impulse (friction and restitution).
			// ------------------------------------------
			//
			//									-(1+Cor)(Vel.norm)
			//			j =  ------------------------------------------------------------
			//			     [1/Ma + 1/Mb] + [Ia' * (ra x norm)²] + [Ib' * (rb x norm)²]
			
			var J:Vector;
			var Jt:Vector;
			var Jn:Vector;
			
			var t0:Number = (r0.cross(normal)) * (r0.cross(normal)) * pa.invInertia;
			var t1:Number = (r1.cross(normal)) * (r1.cross(normal)) * pb.invInertia;
			var invMass0:Number = pa.invMass;
			var invMass1:Number = pb.invMass;
			var invMassTotal = invMass0 + invMass1;
			
			var denom:Number = invMassTotal + t0 + t1;
			
			var jn:Number = vn/denom;
			var restitution:Number = clamp((pa.elasticity + pb.elasticity), 0, 1);
			Jn = normal.mult(-(1 + restitution) * jn);
			
			//if(useFriction){
			var totalFriction:Number = clamp((pa.friction + pb.friction), 0, 1);
				Jt = Vt.normalize().mult(totalFriction * jn);
			
			J = Jn.plus(Jt);
			
			// changes in momentum
			
			var dV0:Vector = J.mult(invMass0);
			var dV1:Vector = J.mult(-invMass1);
			
			var avdamping = 1;
			var dw0:Number = -(r0.cross(J)) * pa.invInertia * avdamping;
			var dw1:Number = (r1.cross(J)) * pb.invInertia * avdamping;
			
			// apply changes in momentum
			//trace(pa);
			//trace(dV0.magnitude());
			pa.resolveVelocities(dV0, dw0, normal);
			pb.resolveVelocities(dV1, dw1, normal);
		}
		
		internal static function resolveOverlap(normal:Vector, depthTime:Number, c0:Vector, c1:Vector, pa:AbstractParticle, pb:AbstractParticle):void{
			var invMass0:Number = pa.invMass;
			var invMass1:Number = pb.invMass;
			var invMassTotal:Number = invMass0 + invMass1;
			
			var diff:Vector = c1.minus(c0);
			var relaxation:Number = .5;
			
			//trace("diff "+diff);
			//trace(depthTime);
			
			//diff.multEquals(relaxation);
			
			var displace0:Vector = new Vector();
			var displace1:Vector = new Vector();
			
			if(invMass0 > 0){
				displace0 = diff.mult(invMass0/invMassTotal);
				pa.curr.plusEquals(displace0);
				//pa.prev.plusEquals(displace0);
				if(pa.invInertia == 0){
					//pa.prev.plusEquals(displace0);
					pa.prev.plusEquals(displace0);
				}
			}
			if(invMass1 > 0){
				displace1 = diff.mult(-invMass1/invMassTotal);
				//trace(pb.velocity.magnitude());
				pb.curr.plusEquals(displace1);
				//trace(" "+pb.velocity.magnitude());
				//pb.prev.plusEquals(displace1);
				if(pb.invInertia == 0){
					//trace(" uhh");
					pb.prev.plusEquals(displace1);
				}
				//trace(" "+pb.velocity.magnitude());
			}			
		}
    }
}

