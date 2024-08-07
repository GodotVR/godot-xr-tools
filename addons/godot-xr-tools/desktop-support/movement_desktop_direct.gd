@tool
class_name XRToolsDesktopMovementDirect
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
@export var max_speed : float = 3.0

## If true, the player can strafe
@export var strafe : bool = false

## Input action for movement direction
@export var input_forward : String = "ui_up"
@export var input_backward : String = "ui_down"
@export var input_left : String = "ui_left"
@export var input_right : String = "ui_right"


# XRStart node
@onready var xr_start_node = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,
	"*Staging",
	"XRToolsStaging"),"StartXR","Node")


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsDesktopMovementDirect" or super(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !player_body.enabled or xr_start_node.is_xr_active():
		return

	#Calculate input vector
	var input_dir = Input.get_vector(input_left, input_right, input_backward, input_forward)

	# Apply forwards/backwards ground control
	player_body.ground_control_velocity.y += input_dir.y * max_speed

	# Apply left/right ground control
	if strafe:
		player_body.ground_control_velocity.x += input_dir.x * max_speed

	# Clamp ground control
	var length := player_body.ground_control_velocity.length()
	if length > max_speed:
		player_body.ground_control_velocity *= max_speed / length

## Find the right [XRToolsDesktopMovementDirect] node.
##
## This function searches from the specified node for the right controller
## [XRToolsDesktopMovementDirect] assuming the node is a sibling of the [XROrigin3D].
static func find(node : Node) -> XRToolsDesktopMovementDirect:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_origin(node),
		"*",
		"XRToolsDesktopMovementDirect") as XRToolsDesktopMovementDirect
