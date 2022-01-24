tool
class_name Function_Jump
extends MovementProvider

##
## Movement Provider for Jumping
##
## @desc:
##     This script works with the Function_Jump_movement asset to provide 
##     jumping mechanics for the player. This script works with the PlayerBody
##     attached to the players ARVROrigin.
##
##     The player enables jumping by attaching a Function_Jump_movement as a 
##     child of the appropriate ARVRController, then configuring the jump button 
##     and jump velocity.
##

# enum our buttons, should find a way to put this more central
enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

## Player jumped signal
signal player_jumped

## Movement provider order
export var order := 20

## Button to trigger jump
export (Buttons) var jump_button_id = Buttons.VR_TRIGGER

# Node references
onready var _controller: ARVRController = get_parent()

# Perform jump movement
func physics_movement(delta: float, player_body: PlayerBody):
	# Skip if the player isn't on the ground
	if !player_body.on_ground:
		return

	# Skip if the jump controller isn't active
	if !_controller.get_is_active():
		return

	# Skip if the jump button isn't pressed
	if !_controller.is_button_pressed(jump_button_id):
		return

	# Skip if the ground is too steep to jump
	var current_max_slope := GroundPhysicsSettings.get_jump_max_slope(player_body.ground_physics, player_body.default_physics)
	if player_body.ground_angle > current_max_slope:
		return

	# Perform the jump
	emit_signal("player_jumped")
	var current_jump_velocity := GroundPhysicsSettings.get_jump_velocity(player_body.ground_physics, player_body.default_physics)
	player_body.velocity.y = current_jump_velocity * ARVRServer.world_scale

# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is ARVRController:
		return "Unable to find ARVR Controller node"

	# Call base class
	return ._get_configuration_warning()
