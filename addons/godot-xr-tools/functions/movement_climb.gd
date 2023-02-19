tool
class_name XRToolsMovementClimb
extends XRToolsMovementProvider


## XR Tools Movement Provider for Climbing
##
## This script provides climbing movement for the player. To add climbing
## support, the player must also have [XRToolsFunctionPickup] nodes attached
## to the left and right controllers, and an [XRToolsPlayerBody] under the
## [ARVROrigin].
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
export var order : int = 15

## Push forward when flinging
export var forward_push : float = 1.0

## Velocity multiplier when flinging up walls
export var fling_multiplier : float = 1.0

## Averages for velocity measurement
export var velocity_averages : int = 5


## Left climbable
var _left_climbable : XRToolsClimbable

## Right climbable
var _right_climbable : XRToolsClimbable

## Dominant pickup (moving the player)
var _dominant : XRToolsFunctionPickup


# Velocity averager
onready var _averager := XRToolsVelocityAveragerLinear.new(velocity_averages)

# Left pickup node
onready var _left_pickup_node := XRToolsFunctionPickup.find_left(self)

# Right pickup node
onready var _right_pickup_node := XRToolsFunctionPickup.find_right(self)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementClimb" or .is_class(name)


## Called when the node enters the scene tree for the first time.
func _ready():
	# Connect pickup funcitons
	if _left_pickup_node.connect("has_picked_up", self, "_on_left_picked_up"):
		push_error("Unable to connect left picked up signal")
	if _right_pickup_node.connect("has_picked_up", self, "_on_right_picked_up"):
		push_error("Unable to connect right picked up signal")
	if _left_pickup_node.connect("has_dropped", self, "_on_left_dropped"):
		push_error("Unable to connect left dropped signal")
	if _right_pickup_node.connect("has_dropped", self, "_on_right_dropped"):
		push_error("Unable to connect right dropped signal")


## Perform player physics movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Disable climbing if requested
	if disabled or !enabled:
		_set_climbing(false, player_body)
		return

	# Snap grabs if too far
	if is_instance_valid(_left_climbable):
		var left_pickup_pos := _left_pickup_node.global_transform.origin
		var left_grab_pos := _left_climbable.get_grab_location(_left_pickup_node)
		if left_pickup_pos.distance_to(left_grab_pos) > SNAP_DISTANCE:
			_left_pickup_node.drop_object()
	if is_instance_valid(_right_climbable):
		var right_pickup_pos := _right_pickup_node.global_transform.origin
		var right_grab_pos := _right_climbable.get_grab_location(_right_pickup_node)
		if right_pickup_pos.distance_to(right_grab_pos) > SNAP_DISTANCE:
			_right_pickup_node.drop_object()

	# Update climbing
	_set_climbing(_dominant != null, player_body)

	# Skip if not actively climbing
	if !is_active:
		return

	# Calculate how much the player has moved
	var offset := Vector3.ZERO
	if _dominant == _left_pickup_node:
		var left_pickup_pos := _left_pickup_node.global_transform.origin
		var left_grab_pos := _left_climbable.get_grab_location(_left_pickup_node)
		offset = left_pickup_pos - left_grab_pos
	elif _dominant == _right_pickup_node:
		var right_pickup_pos := _right_pickup_node.global_transform.origin
		var right_grab_pos := _right_climbable.get_grab_location(_right_pickup_node)
		offset = right_pickup_pos - right_grab_pos

	# Move the player by the offset
	var old_position := player_body.global_transform.origin
	player_body.move_and_collide(-offset)
	player_body.velocity = Vector3.ZERO

	# Update the players average-velocity data
	var distance := player_body.global_transform.origin - old_position
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
		var dir_forward = -player_body.up_player_plane.project(
			player_body.camera_node.global_transform.basis.z).normalized()

		# Set player velocity based on averaged velocity, fling multiplier,
		# and a forward push
		var velocity := _averager.velocity()
		player_body.velocity = (velocity * fling_multiplier) + (dir_forward * forward_push)

		player_body.override_player_height(self)
		emit_signal("player_climb_end")


## Handler for left controller picked up
func _on_left_picked_up(what : Spatial) -> void:
	# Get the climbable
	_left_climbable = what as XRToolsClimbable

	# Transfer climb dominance
	if is_instance_valid(_left_climbable):
		_dominant = _left_pickup_node
	else:
		_left_climbable = null


## Handler for right controller picked up
func _on_right_picked_up(what : Spatial) -> void:
	# Get the climbable
	_right_climbable = what as XRToolsClimbable

	# Transfer climb dominance
	if is_instance_valid(_right_climbable):
		_dominant = _right_pickup_node
	else:
		_right_climbable = null


## Handler for left controller dropped
func _on_left_dropped() -> void:
	# Release climbable
	_left_climbable = null

	# Transfer climb dominance
	if is_instance_valid(_right_climbable):
		_dominant = _right_pickup_node
	else:
		_dominant = null


## Handler for righ controller dropped
func _on_right_dropped() -> void:
	# Release climbable
	_right_climbable = null

	# Transfer climb dominance
	if is_instance_valid(_left_climbable):
		_dominant = _left_pickup_node
	else:
		_dominant = null


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Verify the left controller pickup
	if !XRToolsFunctionPickup.find_left(self):
		return "Unable to find left XRToolsFunctionPickup node"

	# Verify the right controller pickup
	if !XRToolsFunctionPickup.find_right(self):
		return "Unable to find right XRToolsFunctionPickup node"

	# Verify velocity averages
	if velocity_averages < 2:
		return "Minimum of 2 velocity averages needed"

	# Call base class
	return ._get_configuration_warning()
