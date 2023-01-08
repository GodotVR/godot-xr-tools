tool
class_name XRToolsGrabPointSnap
extends XRToolsGrabPoint


## XR Tools Grab Point Snap Script
##
## This script allows specifying a grab point for snap zones. It supports
## group-filters if different points are required for different snap zones.


## Require grab-by to be in the specified group
export var require_group : String = ""

## Deny grab-by if in the specified group
export var exclude_group : String = ""


# Called when the node enters the scene tree for the first time.
func _ready():
	# Add a Position3D child to help editor visibility
	if Engine.editor_hint:
		add_child(Position3D.new())


## Test if a grabber can grab by this grab-point
func can_grab(_grabber : Node) -> bool:
	# Skip if not enabled
	if not enabled:
		return false

	# Ensure the pickup is valid
	if not is_instance_valid(_grabber):
		return false

	# Ensure the grabber is a snap-zone
	if not _grabber is XRToolsSnapZone:
		return false

	# Refuse if the grabber is not in the required group
	if not require_group.empty() and not _grabber.is_in_group(require_group):
		return false

	# Refuse if the grabber is in the excluded group
	if not exclude_group.empty() and _grabber.is_in_group(exclude_group):
		return false

	# Allow the grab
	return true
