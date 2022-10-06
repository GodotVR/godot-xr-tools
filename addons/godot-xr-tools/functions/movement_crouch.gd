@tool
class_name XRToolsMovementCrouch
extends XRToolsMovementProvider

##
## Movement Provider for Crouching
##
## @desc:
##     This script works with the PlayerBody attached to the players XROrigin3D.
##

##     When the player presses the selected button, the height is overridden
##     to the crouch height
##


## Movement provider order
@export var order : int = 10

## Crouch height
@export var crouch_height : float = 1.0

## Crouch button
@export var crouch_button_action : String = "primary_click"


## Crouching flag
var _crouching : bool = false


# Controller node
@onready var _controller : XRController3D = get_parent()


func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super._ready()


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	# Check for crouching change
	var crouching := _controller.is_button_pressed(crouch_button_action)
	if crouching == _crouching:
		return

	# Update crouching state
	_crouching = crouching
	if crouching:
		player_body.override_player_height(self, crouch_height)
	else:
		player_body.override_player_height(self)


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is XRController3D:
		return "Unable to find XR Controller node"

	# Call base class
	return super._get_configuration_warning()
