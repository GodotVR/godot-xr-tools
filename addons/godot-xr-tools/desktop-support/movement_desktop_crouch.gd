@tool
class_name XRToolsDesktopMovementCrouch
extends XRToolsMovementProvider


## XR Tools Movement Provider for Crouching
##
## This script works with the [XRToolsPlayerBody] attached to the players
## [XROrigin3D].
##
## While the player presses the crounch button, the height is overridden to
## the specified crouch height.


## Enumeration of crouching modes
enum CrouchType {
	HOLD_TO_CROUCH,	## Hold button to crouch
	TOGGLE_CROUCH,	## Toggle crouching on button press
}


## Movement provider order
@export var order : int = 10

## Crouch height
@export var crouch_height : float = 1.0

## Crouch button
@export var crouch_button_action : String = "action_crouch"

## Type of crouching
@export var crouch_type : CrouchType = CrouchType.HOLD_TO_CROUCH


## Crouching flag
var _crouching : bool = false

## Crouch button down state
var _crouch_button_down : bool = false


# Controller node
@onready var xr_start_node = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementCrouch" or super(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !player_body.enabled or xr_start_node.is_xr_active():
		return

	# Detect crouch button down and pressed states
	var crouch_button_down := Input.is_action_pressed(crouch_button_action)
	var crouch_button_pressed := crouch_button_down and !_crouch_button_down
	_crouch_button_down = crouch_button_down

	# Calculate new crouching state
	var crouching := _crouching
	match crouch_type:
		CrouchType.HOLD_TO_CROUCH:
			# Crouch when button down
			crouching = crouch_button_down

		CrouchType.TOGGLE_CROUCH:
			# Toggle when button pressed
			if crouch_button_pressed:
				crouching = !crouching

	# Update crouching state
	if crouching != _crouching:
		_crouching = crouching
		if crouching:
			player_body.override_player_height(self, crouch_height)
		else:
			player_body.override_player_height(self)

