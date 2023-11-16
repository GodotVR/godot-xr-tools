class_name Grabber


## Grabber Class
##
## This class contains relevant information for a grabber including any
## assocated pickup, controller, and hand nodes.


## Grabber node
var by : Node3D

## Pickup associated with the grabber
var pickup : XRToolsFunctionPickup

## Controller associated with the grabber
var controller : XRController3D

## Hand associated with the grabber
var hand : XRToolsHand

## Collision hand associated with the grabber
var collision_hand : XRToolsCollisionHand


## Initialize the grabber
func _init(p_by : Node3D) -> void:
	by = p_by
	pickup = p_by as XRToolsFunctionPickup
	controller = pickup.get_controller() if pickup else null
	hand = XRToolsHand.find_instance(controller)
	collision_hand = XRToolsCollisionHand.find_instance(controller)
