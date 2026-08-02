@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsWorldGrabArea
extends Area3D

## XR Tools World-Grab Area
##
## This script adds world-grab areas to an environment.
##
## For world-grab to work, the player must have an [XRToolsMovementWorldGrab]
## node configured appropriately.


## Whether the grip control must be held to keep holding the world-grab area
var press_to_hold := true

## Dictionary of pickup nodes and their temporary grab-handles
var grab_locations: Dictionary[int, Node3D] = {}


## Ignores user pressing the action button while holding this object
func action() -> void:
	pass


## Allows always being grabbed
func can_pick_up(_by: Node3D) -> bool:
	return true


## Gets the grab handle
func get_grab_handle(p: Node3D) -> Node3D:
	return grab_locations.get(p.get_instance_id())


## Called by [XRToolsFunctionPickup] when this is let go by a controller
func let_go(
		_by: Node3D,
		_p_linear_velocity: Vector3,
		_p_angular_velocity: Vector3,
) -> void:
	pass


## Allows always being grabbed
func is_picked_up() -> bool:
	return false


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsWorldGrabArea"


## Called by [XRToolsFunctionPickup] when this is picked up by a controller
func pick_up(by: Node3D) -> void:
	# Get the ID to save the grab handle under
	var id := by.get_instance_id()

	# Get or construct the grab handle
	var handle = grab_locations.get(id)
	if not handle:
		handle = Node3D.new()
		add_child(handle)
		grab_locations[id] = handle

	# Set the handles global transform. As it's a child of this
	# climbable it will move as the climbable moves
	handle.global_transform = by.global_transform


## Ignores highlighting requests from [XRToolsFunctionPickup]
func request_highlight(_from: XRToolsFunctionPickup, _on: bool) -> void:
	pass
