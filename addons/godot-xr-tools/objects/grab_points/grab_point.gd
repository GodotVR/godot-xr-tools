class_name XRToolsGrabPoint
extends Marker3D

## XR Tools Grab Point Base Script
##
## This script is the base for all grab points. Pickable objects extending from
## [XRToolsPickable] can have numerous grab points to control where the object
## is grabbed from.


## Emitted when the user presses the action button while holding this grab point
signal action_pressed(pickable: XRToolsPickable, grab_point: XRToolsGrabPoint)

## Emitted when the user releases the action button while holding this grab point
signal action_released(pickable: XRToolsPickable, grab_point: XRToolsGrabPoint)


## Whether the grab point is enabled for grabbing
@export var enabled := true


## When the user presses the action button while holding this grab point
func action(pickable: XRToolsPickable) -> void:
	# let interested parties know
	action_pressed.emit(pickable, self)


## When the user releases the action button while holding this grab point
func action_release(pickable: XRToolsPickable) -> void:
	# let interested parties know
	action_released.emit(pickable, self)


## Evaluates fitness of the proposed grab, with 0.0 for not allowed.
func can_grab(grabber: Node3D, _current: XRToolsGrabPoint) -> float:
	if not enabled:
		return 0.0

	# Return the distance-weighted fitness
	return _weight(grabber)


# Returns a distance-weighted fitness weight in the range (0.0 - max]
func _weight(grabber: Node3D, max: float = 1.0) -> float:
	var distance := global_position.distance_to(grabber.global_position)
	return max / (1.0 + distance)
