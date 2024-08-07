@tool
class_name XRToolsDesktopMovementJump
extends XRToolsMovementProvider


## XR Tools Movement Provider for Jumping
##
## This script provides jumping mechanics for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## The player enables jumping by attaching an [XRToolsMovementJump] as a
## child of the appropriate [XRController3D], then configuring the jump button
## and jump velocity.


## Movement provider order
@export var order : int = 20

## Button to trigger jump
@export var jump_button_action : String = "ui_accept"


# Node references
@onready var xr_start_node = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsDesktopMovementJump" or super(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the jump controller isn't active
	if !player_body.enabled or xr_start_node.is_xr_active():
		return

	# Request jump if the button is pressed
	if Input.is_action_pressed(jump_button_action):
		player_body.request_jump()

