@tool
class_name XRToolsGrabPointSnap
extends XRToolsGrabPoint


## XR Tools Grab Point Snap Script
##
## This script allows specifying a grab point for snap zones. It supports
## group-filters if different points are required for different snap zones.


## Require grab-by to be in the specified group
@export var require_group : String = ""

## Deny grab-by if in the specified group
@export var exclude_group : String = ""


# Called when the node enters the scene tree for the first time.
func _ready():
	# Add a Position3D child to help editor visibility
	if Engine.is_editor_hint():
		add_child(Marker3D.new())


## Evaluate fitness of the proposed grab, with 0.0 for not allowed.
func can_grab(grabber : Node3D, current : XRToolsGrabPoint) -> float:
	# Skip if not enabled or current grab
	if not enabled or current:
		return 0.0

	# Ensure the pickup is valid
	if not is_instance_valid(grabber):
		return 0.0

	# Ensure the grabber is a snap-zone
	if not grabber is XRToolsSnapZone:
		return 0.0

	# Refuse if the grabber is not in the required group
	if not require_group.is_empty() and not grabber.is_in_group(require_group):
		return 0.0

	# Refuse if the grabber is in the excluded group
	if not exclude_group.is_empty() and grabber.is_in_group(exclude_group):
		return 0.0

	# Return the distance-weighted fitness
	return _weight(grabber)
