tool
class_name XRToolsFunctionTurn, "res://addons/godot-xr-tools/editor/icons/function.svg"
extends Node

##
## Movement Provider for Turning
##
## @desc:
##     This script provides turning support for the player.
##
##     The following types of turning are supported:
##      - Snap turning
##      - Smooth turning
##


## Use smooth rotation (may cause motion sickness)
export var smooth_rotation : bool = false

## Smooth turn speed in radians per second
export var smooth_turn_speed : float = 2.0

## Seconds per step (at maximum turn rate)
export var step_turn_delay : float = 0.2

## Step turn angle in degrees
export var step_turn_angle : float = 20.0


# Turn step accumulator
var _turn_step : float = 0.0


# Controller node
onready var _controller : ARVRController = get_parent()

# Origin node
onready var _origin : ARVROrigin = ARVRHelpers.get_arvr_origin(self)

# Camea node
onready var _camera : ARVRCamera = ARVRHelpers.get_arvr_camera(self)


# Perform jump movement
func _process(delta: float):
	# Skip processing in editor or if the controller isn't active
	if Engine.editor_hint or !_controller.get_is_active():
		return

	# Read the left/right joystick axis
	var left_right := _controller.get_joystick_axis(0)
	if abs(left_right) <= 0.1:
		# Not turning
		_turn_step = 0.0
		return

	# Handle smooth rotation
	if smooth_rotation:
		_rotate_player(smooth_turn_speed * delta * left_right)
		return

	# Update the next turn-step delay
	_turn_step -= abs(left_right) * delta
	if _turn_step >= 0.0:
		return

	# Turn one step in the requested direction
	_turn_step = step_turn_delay
	_rotate_player(deg2rad(step_turn_angle) * sign(left_right))


# Rotate the origin node around the camera
func _rotate_player(angle: float):
	var t1 := Transform()
	var t2 := Transform()
	var rot := Transform()

	t1.origin = -_camera.transform.origin
	t2.origin = _camera.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle)
	_origin.transform = (_origin.transform * t2 * rot * t1).orthonormalized()


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is ARVRController:
		return "Unable to find ARVR Controller node"

	# Check the origin node
	var test_origin = ARVRHelpers.get_arvr_origin(self)
	if !test_origin:
		return "Unable to find ARVR Origin node"

	# Check the camera node
	var test_camera = ARVRHelpers.get_arvr_camera(self)
	if !test_camera:
		return "Unable to find ARVR Camera node"

	# Call base class
	return ._get_configuration_warnings()
