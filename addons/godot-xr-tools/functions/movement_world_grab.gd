@tool
class_name XRToolsMovementWorldGrab
extends XRToolsMovementProvider


## XR Tools Movement Provider for World-Grab
##
## This script provides world-grab movement for the player. To add world-grab
## support, the player must also have [XRToolsFunctionPickup] nodes attached
## to the left and right controllers, and an [XRToolsPlayerBody] under the
## [XROrigin3D].
##
## World-Grab areas inherit from the world_grab_area scene, or be [Area3D]
## nodes with the [XRToolsWorldGrabArea] script attached to them.


## Signal invoked when the player starts world-grab movement
signal player_world_grab_start

## Signal invoked when the player ends world-grab movement
signal player_world_grab_end


## Movement provider order
@export var order : int = 15

## Smallest world scale
@export var world_scale_min := 0.5

## Largest world scale
@export var world_scale_max := 2.0


# Left world-grab handle
var _left_handle : Node3D

# Right world-grab handle
var _right_handle : Node3D


# Left pickup node
@onready var _left_pickup_node := XRToolsFunctionPickup.find_left(self)

# Right pickup node
@onready var _right_pickup_node := XRToolsFunctionPickup.find_right(self)

# Left controller
@onready var _left_controller := XRHelpers.get_left_controller(self)

# Right controller
@onready var _right_controller := XRHelpers.get_right_controller(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementGrabWorld" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Connect pickup funcitons
	if _left_pickup_node.connect("has_picked_up", _on_left_picked_up):
		push_error("Unable to connect left picked up signal")
	if _right_pickup_node.connect("has_picked_up", _on_right_picked_up):
		push_error("Unable to connect right picked up signal")
	if _left_pickup_node.connect("has_dropped", _on_left_dropped):
		push_error("Unable to connect left dropped signal")
	if _right_pickup_node.connect("has_dropped", _on_right_dropped):
		push_error("Unable to connect right dropped signal")


## Perform player physics movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Disable world-grab movement if requested
	if disabled or !enabled:
		_set_world_grab_moving(false)
		return

	# Always set velocity to zero if enabled
	player_body.velocity = Vector3.ZERO

	# Check for world-grab handles being deleted while held
	if not is_instance_valid(_left_handle):
		_left_handle = null
	if not is_instance_valid(_right_handle):
		_right_handle = null

	# Disable world-grab movement if not holding the world
	if not _left_handle and not _right_handle:
		_set_world_grab_moving(false)
		return

	# World grabbed
	_set_world_grab_moving(true)

	# Handle world-grab movement
	var offset := Vector3.ZERO
	if _left_handle and not _right_handle:
		# Left-hand movement only
		var left_pickup_pos := _left_controller.global_position
		var left_grab_pos := _left_handle.global_position
		offset = left_pickup_pos - left_grab_pos
	elif _right_handle and not _left_handle:
		# Right-hand movement only
		var right_pickup_pos := _right_controller.global_position
		var right_grab_pos := _right_handle.global_position
		offset = right_pickup_pos - right_grab_pos
	else:
		# Get the world-grab handle positions
		var left_grab_pos := _left_handle.global_position
		var right_grab_pos := _right_handle.global_position
		var grab_l2r := (right_grab_pos - left_grab_pos).slide(player_body.up_player)
		var grab_mid := (left_grab_pos + right_grab_pos) * 0.5

		# Get the pickup positions
		var left_pickup_pos := _left_controller.global_position
		var right_pickup_pos := _right_controller.global_position
		var pickup_l2r := (right_pickup_pos - left_pickup_pos).slide(player_body.up_player)
		var pickup_mid := (left_pickup_pos + right_pickup_pos) * 0.5

		# Apply rotation
		var angle := grab_l2r.signed_angle_to(pickup_l2r, player_body.up_player)
		player_body.rotate_player(angle)

		# Apply scale
		var new_world_scale := XRServer.world_scale * grab_l2r.length() / pickup_l2r.length()
		new_world_scale = clamp(new_world_scale, world_scale_min, world_scale_max)
		XRServer.world_scale = new_world_scale

		# Apply offset
		offset = pickup_mid - grab_mid

	# Move the player by the offset
	var old_position := player_body.global_position
	player_body.move_body(-offset / delta)
	player_body.velocity = Vector3.ZERO
	#player_body.move_and_collide(-offset)

	# Report exclusive motion performed (to bypass gravity)
	return true


## Start or stop world-grab movement
func _set_world_grab_moving(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		emit_signal("player_world_grab_start")
	else:
		emit_signal("player_world_grab_end")


## Handler for left controller picked up
func _on_left_picked_up(what : Node3D) -> void:
	# Get the world-grab area
	var world_grab_area = what as XRToolsWorldGrabArea
	if not world_grab_area:
		return

	# Get the handle
	_left_handle = world_grab_area.get_grab_handle(_left_pickup_node)
	if not _left_handle:
		return


## Handler for right controller picked up
func _on_right_picked_up(what : Node3D) -> void:
	# Get the world-grab area
	var world_grab_area = what as XRToolsWorldGrabArea
	if not world_grab_area:
		return

	# Get the handle
	_right_handle = world_grab_area.get_grab_handle(_right_pickup_node)
	if not _right_handle:
		return


## Handler for left controller dropped
func _on_left_dropped() -> void:
	# Release handle and transfer dominance
	_left_handle = null


## Handler for righ controller dropped
func _on_right_dropped() -> void:
	# Release handle and transfer dominance
	_right_handle = null


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Verify the left controller pickup
	if !XRToolsFunctionPickup.find_left(self):
		warnings.append("Unable to find left XRToolsFunctionPickup node")

	# Verify the right controller pickup
	if !XRToolsFunctionPickup.find_right(self):
		warnings.append("Unable to find right XRToolsFunctionPickup node")

	# Return warnings
	return warnings
