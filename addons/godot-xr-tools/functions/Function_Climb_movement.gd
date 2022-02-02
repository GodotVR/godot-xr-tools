tool
class_name Function_ClimbMovement
extends MovementProvider

##
## Movement Provider for Climbing
##
## @desc:
##     This script works with the Function_Climb_movement asset to provide
##     climbing movement for the player. This script works with the PlayerBody
##     attached to the players ARVROrigin.
##
##     StaticBody objects can be marked as climbable by adding the
##     Object_climbable script to them
##
##     When climbing, the global velocity of the PlayerBody is averaged for
##     velocity_averages samples, and upon release the velocity is applied
##     to the PlayerBody so the player can fling themselves up walls if
##     desired.
##

## Signal invoked when the player starts climing
signal player_climb_start

## Signal invoked when the player ends climbing
signal player_climb_end

## Movement provider order
export var order := 15

## Push forward when flinging
export var forward_push := 1.0

## Velocity multiplier when flinging up walls
export var fling_multiplier := 1.0

## Averages for velocity measurement
export var velocity_averages := 5

## Pickup function for the left hand
export (NodePath) var left_pickup = null

## Pickup function for the right hand
export (NodePath) var right_pickup = null

# Is the player climbing
var is_climbing := false

# Node references
var _left_pickup_node : Function_Pickup = null
var _right_pickup_node : Function_Pickup = null

# Velocity averaging fields
var _distances = Array()
var _deltas = Array()

# Horizontal vector (multiply by this to get only the horizontal components
const horizontal := Vector3(1.0, 0.0, 1.0)

# Called when the node enters the scene tree for the first time.
func _ready():
	_left_pickup_node = get_node(left_pickup)
	_right_pickup_node = get_node(right_pickup)

func physics_movement(delta: float, player_body: PlayerBody):
	# Get the left-hand climbable
	var left_climbable = _left_pickup_node.picked_up_object
	if !is_instance_valid(left_climbable) or !left_climbable is Object_climbable:
		left_climbable = null

	# Get the right-hand climbable
	var right_climbable : Node = _right_pickup_node.picked_up_object
	if !is_instance_valid(right_climbable) or !right_climbable is Object_climbable:
		right_climbable = null

	# Detect if we are climbing now
	var old_is_climbing := is_climbing
	is_climbing = left_climbable or right_climbable

	# Skip if no current or previous climbing
	if !is_climbing and !old_is_climbing:
		return

	# Detect change of climbing state
	if !old_is_climbing:
		_distances.clear()
		_deltas.clear()
		emit_signal("player_climb_start")
	elif !is_climbing:
		var velocity := _average_velocity()
		var dir_forward = -(player_body.camera_node.global_transform.basis.z * horizontal).normalized()
		player_body.velocity = (velocity * fling_multiplier) + (dir_forward * forward_push)
		emit_signal("player_climb_end")
		return

	# Calculate how much the player has moved
	var offset := Vector3.ZERO
	if left_climbable:
		offset += _left_pickup_node.global_transform.origin - left_climbable.get_grab_location(_left_pickup_node)
	if right_climbable:
		offset += _right_pickup_node.global_transform.origin - right_climbable.get_grab_location(_right_pickup_node)

	# Average the offset if we have two hands moving
	if left_climbable and right_climbable:
		offset *= 0.5

	# Move the player by the offset
	var old_position := player_body.kinematic_node.global_transform.origin
	player_body.kinematic_node.move_and_collide(-offset)
	player_body.velocity = Vector3.ZERO

	# Update the players average-velocity data
	var distance := player_body.kinematic_node.global_transform.origin - old_position
	_update_velocity(delta, distance)

	# Report exclusive motion performed (to bypass gravity)
	return true

# Update player velocity averaging data
func _update_velocity(delta: float, distance: Vector3):
	# Add delta and distance to averaging arrays
	_distances.push_back(distance)
	_deltas.push_back(delta)
	if _distances.size() > velocity_averages:
		_distances.pop_front()
		_deltas.pop_front()

# Calculate average player velocity
func _average_velocity() -> Vector3:
	# Calculate the total time
	var total_time := 0.0
	for dt in _deltas:
		total_time += dt

	# Calculate the total distance
	var total_distance := Vector3(0.0, 0.0, 0.0)
	for dd in _distances:
		total_distance += dd

	# Return the average
	return total_distance / total_time

# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Verify the left controller
	var test_left_pickup_node = get_node_or_null(left_pickup) if left_pickup else null
	if !test_left_pickup_node or !test_left_pickup_node is Function_Pickup:
		return "Unable to find left Function_Pickup"

	# Verify the right controller
	var test_right_pickup_node = get_node_or_null(right_pickup) if right_pickup else null
	if !test_right_pickup_node or !test_right_pickup_node is Function_Pickup:
		return "Unable to find right Function_Pickup"

	# Verify velocity averages
	if velocity_averages < 2:
		return "Minimum of 2 velocity averages needed"

	# Call base class
	return ._get_configuration_warning()
