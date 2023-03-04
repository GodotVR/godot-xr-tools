@tool
@icon("res://addons/godot-xr-tools/editor/icons/hand.svg")
class_name XRToolsReturnToSnapZone
extends Node


## XR Tools Return to Snap Zone
##
## This node can be added to an XRToolsPickable to make it return to a specified
## snap-zone when the object is dropped.


## Snap zone path
@export var snap_zone_path : NodePath

## Return delay
@export var return_delay : float = 1.0


# Pickable object to control
var _pickable : XRToolsPickable

# Snap zone to return to
var _snap_zone : XRToolsSnapZone

# Return counter
var _return_counter : float = 0.0

# Is the pickable held
var _held := false


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsReturnToSnapZone"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the pickable (parent of this node)
	_pickable = get_parent() as XRToolsPickable
	if _pickable:
		_pickable.picked_up.connect(_on_picked_up)
		_pickable.dropped.connect(_on_dropped)

	# Get the optional snap-zone
	_snap_zone = get_node_or_null(snap_zone_path)
	if not _snap_zone:
		set_process(false)


# Handle the return counter
func _process(delta : float) -> void:
	# Update return time and skip if still waiting
	_return_counter += delta
	if _return_counter < return_delay:
		return

	# Stop counting
	set_process(false)

	# If the snap-zone is empty then snap to it
	if not _snap_zone.has_snapped_object():
		_snap_zone.pick_up_object(_pickable)


# Set the snap-zone
func set_snap_zone(snap_zone : XRToolsSnapZone) -> void:
	# Set the snap zone
	_snap_zone = snap_zone
	_return_counter = 0.0

	# Control counting
	if _snap_zone and not _held:
		set_process(true)
	else:
		set_process(false)


# Handle the object being picked up
func _on_picked_up(_pickable) -> void:
	# Set held and stop counting
	_held = true
	set_process(false)


# Handle the object being dropped
func _on_dropped(_pickable) -> void:
	# Clear held and reset counter
	_held = false
	_return_counter = 0.0

	# Start counter if snap-zone specified
	if _snap_zone:
		set_process(true)


# This method verifies the pose area has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify this node is a child of a pickable
	if not get_parent() is XRToolsPickable:
		warnings.append("Must be a child of a pickable")

	# Return warnings
	return warnings
