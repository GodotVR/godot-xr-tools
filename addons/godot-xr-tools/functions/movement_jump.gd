@tool
class_name XRToolsMovementJump
extends XRToolsMovementProvider


##
## Movement Provider for Jumping
##
## @desc:
##     This script works with the Function_Jump_movement asset to provide 
##     jumping mechanics for the player. This script works with the PlayerBody
##     attached to the players XROrigin3D.
##
##     The player enables jumping by attaching a Function_Jump_movement as a 
##     child of the appropriate XRController3D, then configuring the jump button 
##     and jump velocity.
##


## Movement provider order
@export var order : int = 20

## Button to trigger jump
@export var jump_button_action = "trigger_click"


# Node references
@onready var _controller: XRController3D = get_parent()


func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super._ready()


# Perform jump movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody):
	# Skip if the jump controller isn't active
	if !_controller.get_is_active():
		return

	# Skip if the jump button isn't pressed
	if _controller.is_button_pressed(jump_button_action):
		player_body.request_jump()


# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is XRController3D:
		return "Unable to find XR Controller node"

	# Call base class
	return super._get_configuration_warning()
