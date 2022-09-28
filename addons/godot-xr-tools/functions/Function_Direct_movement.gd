@tool
class_name Function_DirectMovement
extends MovementProvider


##
## Movement Provider for Direct Movement
##
## @desc:
##     This script works with the Function_Direct_movement asset to provide
##     direct movement for the player. This script works with the PlayerBody
##     attached to the players XROrigin3D.
##
##     The following types of direct movement are supported:
##      - Snap turning
##      - Smooth turning
##      - Slewing
##      - Forwards and backwards motion
##
##     The player may have multiple direct movement nodes attached to different
##     controllers to provide different types of direct movement.
##


enum MOVEMENT_TYPE { MOVE_AND_ROTATE, MOVE_AND_STRAFE }


## Movement provider order
@export var order : int = 10

## Use smooth rotation (may cause motion sickness)
@export var smooth_rotation : bool = false

## Smooth turn speed in radians per second
@export var smooth_turn_speed : float = 2.0

## Seconds per step (at maximum turn rate)
@export var step_turn_delay : float = 0.2

## Step turn angle in degrees
@export var step_turn_angle : float = 20.0

## Movement speed
@export var max_speed : float = 10.0

## Type of movement to perform
@export var move_type : MOVEMENT_TYPE = MOVEMENT_TYPE.MOVE_AND_ROTATE

## Our directional input
@export var input_action = "primary"


# Turn step accumulator
var _turn_step := 0.0


# Controller node
@onready var _controller : XRController3D = get_parent()


func _ready():
	# Workaround for issue #52223, our onready var is preventing ready from being called on the super class
	super()


# Perform jump movement
func physics_movement(delta: float, player_body: PlayerBody):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Handle rotation
	if move_type == MOVEMENT_TYPE.MOVE_AND_ROTATE:
		_perform_player_rotation(delta, player_body)

	# Apply forwards/backwards ground control
	player_body.ground_control_velocity.y += _controller.get_axis(input_action).y * max_speed

	# Apply left/right ground control
	if move_type == MOVEMENT_TYPE.MOVE_AND_STRAFE:
		player_body.ground_control_velocity.x += _controller.get_axis(input_action).x * max_speed

	# Clamp ground control
	player_body.ground_control_velocity.x = clamp(player_body.ground_control_velocity.x, -max_speed, max_speed)
	player_body.ground_control_velocity.y = clamp(player_body.ground_control_velocity.y, -max_speed, max_speed)

# Perform rotation based on the players rotation controller input
func _perform_player_rotation(delta: float, player_body: PlayerBody):
	var left_right := _controller.get_axis(input_action).x
	
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
	_rotate_player(player_body, deg_to_rad(step_turn_angle) * sign(left_right))


# Rotate the origin node around the camera
func _rotate_player(player_body: PlayerBody, angle: float):
	var t1 := Transform3D()
	var t2 := Transform3D()
	var rot := Transform3D()

	t1.origin = -player_body.camera_node.transform.origin
	t2.origin = player_body.camera_node.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle)
	player_body.origin_node.transform = (player_body.origin_node.transform * t2 * rot * t1).orthonormalized()


# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is XRController3D:
		return "Unable to find XR Controller node"

	# Call base class
	return super._get_configuration_warning()
