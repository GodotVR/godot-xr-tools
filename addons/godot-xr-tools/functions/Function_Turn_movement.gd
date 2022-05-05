tool
class_name Function_TurnMovement
extends MovementProvider

##
## Movement Provider for Turning
##
## @desc:
##     This script provides turning support for the player. This script works
##     with the PlayerBody attached to the players ARVROrigin.
##
##     The following types of turning are supported:
##      - Snap turning
##      - Smooth turning
##


## Movement provider order
export var order := 5

## Use smooth rotation (may cause motion sickness)
export var smooth_rotation := false

## Smooth turn speed in radians per second
export var smooth_turn_speed := 2.0

## Seconds per step (at maximum turn rate)
export var step_turn_delay := 0.2

## Step turn angle in degrees
export var step_turn_angle := 20.0


# Turn step accumulator
var _turn_step := 0.0


# Controller node
onready var _controller : ARVRController = get_parent()


# Perform jump movement
func physics_movement(delta: float, player_body: PlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Read the left/right joystick axis
	var left_right := _controller.get_joystick_axis(0)
	if abs(left_right) <= 0.1:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation
	if smooth_rotation:
		_rotate_player(player_body, smooth_turn_speed * delta * left_right)
		return

	# Update the next turn-step delay
	_turn_step -= abs(left_right) * delta
	if _turn_step >= 0.0:
		return

	# Turn one step in the requested direction
	_turn_step = step_turn_delay
	_rotate_player(player_body, deg2rad(step_turn_angle) * sign(left_right))


# Rotate the origin node around the camera
func _rotate_player(player_body: PlayerBody, angle: float):
	var t1 := Transform()
	var t2 := Transform()
	var rot := Transform()

	t1.origin = -player_body.camera_node.transform.origin
	t2.origin = player_body.camera_node.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle)
	player_body.origin_node.transform = (player_body.origin_node.transform * t2 * rot * t1).orthonormalized()


# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is ARVRController:
		return "Unable to find ARVR Controller node"

	# Call base class
	return ._get_configuration_warning()
