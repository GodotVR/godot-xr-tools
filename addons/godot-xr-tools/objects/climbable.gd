@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsClimbable
extends Node3D


## XR Tools Climbable Object
##
## This script adds climbing support to any [StaticBody3D].
##
## For climbing to work, the player must have an [XRToolsMovementClimb] node
## configured appropriately.


## If true, the grip control must be held to keep holding the climbable
var press_to_hold : bool = true

## Dictionary of grab locations by pickup
var grab_locations := {}


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsClimbable"


# Called by XRToolsFunctionPickup
func is_picked_up() -> bool:
	return false

func can_pick_up(_by: Node3D) -> bool:
	return true

# Called by XRToolsFunctionPickup when user presses the action button while holding this object
func action():
	pass

# Called by XRToolsFunctionPickup when this becomes the closest object to a controller
func increase_is_closest():
	pass

# Called by XRToolsFunctionPickup when this stops being the closest object to a controller
func decrease_is_closest():
	pass

# Called by XRToolsFunctionPickup when this is picked up by a controller
func pick_up(by: Node3D, _with_controller: XRController3D) -> void:
	save_grab_location(by)

# Called by XRToolsFunctionPickup when this is let go by a controller
func let_go(_p_linear_velocity: Vector3, _p_angular_velocity: Vector3) -> void:
	pass

# Save the grab location
func save_grab_location(p: Node3D):
	grab_locations[p.get_instance_id()] = to_local(p.global_transform.origin)

# Get the grab location in world-space
func get_grab_location(p: Node3D) -> Vector3:
	return to_global(grab_locations[p.get_instance_id()])
