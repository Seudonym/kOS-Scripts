set g to body:mu / body:radius^2.

lock currentHeight to ship:bounds:bottomaltradar.
lock maxDecel to ship:maxThrust / ship:mass - g.
lock stoppingDistance to 0.5 * ship:verticalSpeed^2 / maxDecel.
lock stoppingTime to abs(ship:verticalSpeed / maxDecel).
lock throttleAmount to stoppingDistance / currentHeight.

wait until ship:verticalspeed < -1.
print "Bringup sequence running...".
sas off.
rcs on.
brakes on.
lock steering to srfretrograde.


wait until currentHeight <= stoppingDistance.
print "Starting burn...".
lock throttle to throttleAmount.

when stoppingTime<= 10 then {
    print "Extending landing gears...".
    gear on.
}


wait until ship:verticalSpeed >= -0.1.
print "Landed successfully...".
lock throttle to 0.0.
unlock throttle.
unlock steering.
rcs off.
brakes off.