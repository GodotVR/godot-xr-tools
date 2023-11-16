@tool
class_name XRToolsGrabPointRedirect
extends XRToolsGrabPoint


## Grab point to redirect grabbing to
@export var target : XRToolsGrabPoint


## Evaluate fitness of the proposed grab, with 0.0 for not allowed.
func can_grab(grabber : Node3D, current : XRToolsGrabPoint) -> float:
	# Fail if no target
	if not is_instance_valid(target):
		return 0.0

	# Consult the target
	return target.can_grab(grabber, current)
