@tool
class_name XRToolsMovementClimb
extends XRToolsMovementProvider


## XR Tools Movement Provider for Climbing
##
## This script provides climbing movement for the player. To add climbing
## support, the player must also have [XRToolsFunctionPickup] nodes attached
## to the left and right controllers, and an [XRToolsPlayerBody] under the
## [XROrigin3D].
##
## Climbable objects can inherit from the climbable scene, or be [StaticBody]
## objects with the [XRToolsClimbable] script attached to them.
##
## When climbing, the global velocity of the [XRToolsPlayerBody] is averaged,
## and upon release the velocity is applied to the [XRToolsPlayerBody] with an
## optional fling multiplier, so the player can fling themselves up walls if
## desired.


## Signal invoked when the player starts climing
signal player_climb_start

## Signal invoked when the player ends climbing
signal player_climb_end


## Distance at which grabs snap
const SNAP_DISTANCE : float = 1.0


## Movement provider order
@export var order : int = 15

## Push forward when flinging
@export var forward_push : float = 1.0

## Velocity multiplier when flinging up walls
@export var fling_multiplier : float = 1.0

## Averages for velocity measurement
@export var velocity_averages : int = 5


# Left climbing handle
var _left_handle : Node3D

# Right climbing handle
var _right_handle : Node3D

# Dominant handle (moving the player)
var _dominant : Node3D


# Velocity averager
@onready var _averager := XRToolsVelocityAveragerLinear.new(velocity_averages)

# Left pickup node
@onready var _left_pickup_node := XRToolsFunctionPickup.find_left(self)

# Right pickup node
@onready var _right_pickup_node := XRToolsFunctionPickup.find_right(self)

# Left controller
@onready var _left_controller := XRHelpers.get_left_controller(self)

# Right controller
@onready var _right_controller := XRHelpers.get_right_controller(self)

# Left collision hand
@onready var _left_hand := XRToolsHand.find_left(self)

# Right collision hand
@onready var _right_hand := XRToolsHand.find_right(self)

# Left collision hand
@onready var _left_collision_hand := XRToolsCollisionHand.find_left(self)

# Right collision hand
@onready var _right_collision_hand := XRToolsCollisionHand.find_right(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementClimb" or super(name)


## Called when the node enters the scene tree for the first time.
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
	# Disable climbing if requested
	if disabled or !enabled:
		_set_climbing(false, player_body)
		return

	# Check for climbing handles being deleted while held
	if not is_instance_valid(_left_handle):
		_left_handle = null
	if not is_instance_valid(_right_handle):
		_right_handle = null
	if not is_instance_valid(_dominant):
		_dominant = null

	# Snap grabs if too far
	if _left_handle:
		var left_pickup_pos := _left_controller.global_position
		var left_grab_pos = _left_handle.global_position
		if left_pickup_pos.distance_to(left_grab_pos) > SNAP_DISTANCE:
			_left_pickup_node.drop_object()
	if _right_handle:
		var right_pickup_pos := _right_controller.global_position
		var right_grab_pos := _right_handle.global_position
		if right_pickup_pos.distance_to(right_grab_pos) > SNAP_DISTANCE:
			_right_pickup_node.drop_object()

	# Update climbing
	_set_climbing(_dominant != null, player_body)

	# Skip if not actively climbing
	if !is_active:
		return

	# Calculate how much the player has moved
	var offset := Vector3.ZERO
	if _dominant == _left_handle:
		var left_pickup_pos := _left_controller.global_position
		var left_grab_pos := _left_handle.global_position
		offset = left_pickup_pos - left_grab_pos
	elif _dominant == _right_handle:
		var right_pickup_pos := _right_controller.global_position
		var right_grab_pos := _right_handle.global_position
		offset = right_pickup_pos - right_grab_pos

	# Move the player by the offset
	var old_position := player_body.global_position
	player_body.move_and_collide(-offset)
	player_body.velocity = Vector3.ZERO

	# Update the players average-velocity data
	var distance := player_body.global_position - old_position
	_averager.add_distance(delta, distance)

	# Report exclusive motion performed (to bypass gravity)
	return true


## Start or stop climbing
func _set_climbing(active: bool, player_body: XRToolsPlayerBody) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update state
	is_active = active

	# Handle state change
	if is_active:
		_averager.clear()
		player_body.override_player_height(self, 0.0)
		emit_signal("player_climb_start")
	else:
		# Calculate the forward direction (based on camera-forward)
		var dir_forward = -player_body.camera_node.global_transform.basis.z \
				.slide(player_body.up_player) \
				.normalized()

		# Set player velocity based on averaged velocity, fling multiplier,
		# and a forward push
		var velocity := _averager.velocity()
		player_body.velocity = (velocity * fling_multiplier) + (dir_forward * forward_push)

		player_body.override_player_height(self)
		emit_signal("player_climb_end")


## Handler for left controller picked up
func _on_left_picked_up(what : Node3D) -> void:
	# Get the climbable
	var climbable = what as XRToolsClimbable
	if not climbable:
		return

	# Get the handle
	_left_handle = climbable.get_grab_handle(_left_pickup_node)
	if not _left_handle:
		return

	# Switch dominance to the left handle
	_dominant = _left_handle

	# If collision hands present then target the handle
	if _left_collision_hand:
		_left_collision_hand.add_target_override(_left_handle, 0)
	elif _left_hand:
		_left_hand.add_target_override(_left_handle, 0)


## Handler for right controller picked up
func _on_right_picked_up(what : Node3D) -> void:
	# Get the climbable
	var climbable = what as XRToolsClimbable
	if not climbable:
		return

	# Get the handle
	_right_handle = climbable.get_grab_handle(_right_pickup_node)
	if not _right_handle:
		return

	# Switch dominance to the right handle
	_dominant = _right_handle

	# If collision hands present then target the handle
	if _right_collision_hand:
		_right_collision_hand.add_target_override(_right_handle, 0)
	elif _right_hand:
		_right_hand.add_target_override(_right_handle, 0)


## Handler for left controller dropped
func _on_left_dropped() -> void:
	# If collision hands present then clear handle target
	if _left_collision_hand:
		_left_collision_hand.remove_target_override(_left_handle)
	if _left_hand:
		_left_hand.remove_target_override(_left_handle)

	# Release handle and transfer dominance
	_left_handle = null
	_dominant = _right_handle


## Handler for righ controller dropped
func _on_right_dropped() -> void:
	# If collision hands present then clear handle target
	if _right_collision_hand:
		_right_collision_hand.remove_target_override(_right_handle)
	if _right_hand:
		_right_hand.remove_target_override(_right_handle)

	# Release handle and transfer dominance
	_right_handle = null
	_dominant = _left_handle


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Verify the left controller pickup
	if !XRToolsFunctionPickup.find_left(self):
		warnings.append("Unable to find left XRToolsFunctionPickup node")

	# Verify the right controller pickup
	if !XRToolsFunctionPickup.find_right(self):
		warnings.append("Unable to find right XRToolsFunctionPickup node")

	# Verify velocity averages
	if velocity_averages < 2:
		warnings.append("Minimum of 2 velocity averages needed")

	# Return warnings
	return warnings
