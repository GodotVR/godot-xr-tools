@tool
class_name XRToolsMovementDirect
extends XRToolsMovementProvider


## XR Tools Movement Provider for Direct Movement
##
## This script provides direct movement for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## The player may have multiple [XRToolsMovementDirect] nodes attached to
## different controllers to provide different types of direct movement.


## Movement provider order
@export var order : int = 10

## Movement speed
@export var max_speed : float = 10.0

## If true, the player can strafe 
@export var strafe : bool = false

## Input action for movement direction
@export var input_action : String = "primary"


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

	# Apply forwards/backwards ground control
	player_body.ground_control_velocity.y += _controller.get_axis(input_action).y * max_speed

	# Apply left/right ground control
	if strafe:
		player_body.ground_control_velocity.x += _controller.get_axis(input_action).x * max_speed

	# Clamp ground control
	var length := player_body.ground_control_velocity.length()
	if length > max_speed:
		player_body.ground_control_velocity *= max_speed / length


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	var test_controller = get_parent()
	if !test_controller or !test_controller is XRController3D:
		return "Unable to find XR Controller node"

	# Call base class
	return super._get_configuration_warning()
