@tool
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


## Array of permanent grab points.
var _grab_points : Array[XRToolsGrabPoint] = []

## Dictionary of temporary grabs keyed by the pickup node
var _grab_temps : Dictionary = {}

## Dictionary of active grabs keyed by the pickup node
var _grabs : Dictionary = {}


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsClimbable"


# Called when the node becomes "ready"
func _ready() -> void:
	# Get all grab points
	for child in get_children():
		var grab_point := child as XRToolsGrabPoint
		if grab_point:
			_grab_points.push_back(grab_point)


# Called by XRToolsFunctionPickup
func is_picked_up() -> bool:
	return false


func can_pick_up(_by: Node3D) -> bool:
	return true


# Called by XRToolsFunctionPickup when user presses the action button while holding this object
func action():
	pass


# Ignore highlighting requests from XRToolsFunctionPickup
func request_highlight(_from, _on) -> void:
	pass


# Called by XRToolsFunctionPickup when this is picked up by a controller
func pick_up(by: Node3D) -> void:
	# Get the best permanent grab-point
	var point := _get_grab_point(by)
	if not point:
		# Get a temporary grab-point for the pickup
		point = _grab_temps.get(by)
		if not point:
			# Create a new temporary grab-point childed to the climbable
			point = Node3D.new()
			add_child(point)
			_grab_temps[by] = point

		# Set the temporary to the current positon
		point.global_transform = by.global_transform

	# Save the grab
	_grabs[by] = point


# Called by XRToolsFunctionPickup when this is let go by a controller
func let_go(by: Node3D, _p_linear_velocity: Vector3, _p_angular_velocity: Vector3) -> void:
	_grabs.erase(by)


# Get the grab handle
func get_grab_handle(by: Node3D) -> Node3D:
	return _grabs.get(by)


## Find the most suitable grab-point for the grabber
func _get_grab_point(by : Node3D) -> Node3D:
	# Find the best grab-point
	var fitness := 0.0
	var point : XRToolsGrabPoint = null
	for p in _grab_points:
		var f := p.can_grab(by, null)
		if f > fitness:
			fitness = f
			point = p

	# Resolve redirection
	while point is XRToolsGrabPointRedirect:
		point = point.target

	# Return the best grab point
	print_verbose("%s> picked grab-point %s" % [name, point])
	return point
