@tool
class_name Function_Jump
extends MovementProvider

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

## Player jumped signal
signal player_jumped

## Movement provider order
@export var order : int = 20

## Button to trigger jump
@export var jump_button_action = "trigger_click"

# Node references
@onready var _controller: XRController3D = get_parent()

# Perform jump movement
func physics_movement(delta: float, player_body: PlayerBody):
	# Skip if the player isn't on the ground
	if !player_body.on_ground:
		return

	# Skip if the jump controller isn't active
	if !_controller.get_is_active():
		return

	# Skip if the jump button isn't pressed
	if !_controller.is_button_pressed(jump_button_action):
		return

	# Skip if the ground is too steep to jump
	var current_max_slope := GroundPhysicsSettings.get_jump_max_slope(player_body.ground_physics, player_body.default_physics)
	if player_body.ground_angle > current_max_slope:
		return

	# Perform the jump
	emit_signal("player_jumped")
	var current_jump_velocity := GroundPhysicsSettings.get_jump_velocity(player_body.ground_physics, player_body.default_physics)
	player_body.velocity.y = current_jump_velocity * XRServer.world_scale

# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is XRController3D:
		return "Unable to find XR Controller node"

	# Call base class
	return super._get_configuration_warning()

func _ready():
	# Workaround for issue #52223, our onready var is preventing ready from being called on the super class
	super()
