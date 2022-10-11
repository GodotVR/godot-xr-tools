tool
class_name XRToolsMovementJump
extends XRToolsMovementProvider


##
## Movement Provider for Jumping
##
## @desc:
##     This script provides jumping mechanics for the player. This script works
##     with the XRToolsPlayerBody attached to the players ARVROrigin.
##
##     The player enables jumping by attaching an XRToolsMovementJump as a
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

## Movement provider order
export var order : int = 20

## Button to trigger jump
export (Buttons) var jump_button_id : int = Buttons.VR_TRIGGER

# Node references
onready var _controller: ARVRController = get_parent()

# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the jump controller isn't active
	if !_controller.get_is_active():
		return

	# Request jump if the button is pressed
	if _controller.is_button_pressed(jump_button_id):
		player_body.request_jump()


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is ARVRController:
		return "Unable to find ARVR Controller node"

	# Call base class
	return ._get_configuration_warning()
