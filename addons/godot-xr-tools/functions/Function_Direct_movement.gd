tool
class_name Function_DirectMovement
extends MovementProvider

##
## Movement Provider for Direct Movement
##
## @desc:
##     This script works with the Function_Direct_movement asset to provide
##     direct movement for the player. This script works with the PlayerBody
##     attached to the players ARVROrigin.
##
##     The following types of direct movement are supported:
##      - Slewing
##      - Forwards and backwards motion
##
##     The player may have multiple direct movement nodes attached to different
##     controllers to provide different types of direct movement.
##


## Movement provider order
export var order := 10

## Movement speed
export var max_speed := 10.0

## Enable player strafing
export var strafe := false


# Controller node
onready var _controller : ARVRController = get_parent()


# Perform jump movement
func physics_movement(delta: float, player_body: PlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Apply forwards/backwards ground control
	player_body.ground_control_velocity.y += _controller.get_joystick_axis(1) * max_speed

	# Apply left/right ground control
	if strafe:
		player_body.ground_control_velocity.x += _controller.get_joystick_axis(0) * max_speed

	# Clamp ground control
	player_body.ground_control_velocity.x = clamp(player_body.ground_control_velocity.x, -max_speed, max_speed)
	player_body.ground_control_velocity.y = clamp(player_body.ground_control_velocity.y, -max_speed, max_speed)


# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is ARVRController:
		return "Unable to find ARVR Controller node"

	# Call base class
	return ._get_configuration_warning()
