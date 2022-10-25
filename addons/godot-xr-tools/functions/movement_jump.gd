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


## Movement provider order
export var order : int = 20

## Button to trigger jump
export (XRTools.Buttons) var jump_button_id : int = XRTools.Buttons.VR_TRIGGER

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
