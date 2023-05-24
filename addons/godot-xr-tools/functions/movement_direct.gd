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
@export var max_speed : float = 3.0

## If true, the player can strafe
@export var strafe : bool = false

## Input action for movement direction
@export var input_action : String = "primary"


# Controller node
@onready var _controller := XRHelpers.get_xr_controller(self)

## y_axis_dead_zone (from configuration)
@onready var _y_axis_dead_zone : float = XRTools.get_y_axis_dead_zone()

## x_axis_dead_zone (from configuration)
@onready var _x_axis_dead_zone : float = XRTools.get_x_axis_dead_zone()

@onready var label = $"../../XRCamera3D/Label3D"


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementDirect" or super(name)


# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if the controller isn't active
	if !_controller.get_is_active():
		return

	_y_axis_dead_zone = XRTools.get_y_axis_dead_zone()
	_x_axis_dead_zone = XRTools.get_x_axis_dead_zone()

	# Apply forwards/backwards ground control
	var forward_backward := _controller.get_vector2(input_action).y
	var left_right := _controller.get_vector2(input_action).x
	
	if abs(forward_backward) > _y_axis_dead_zone:
		var negative = false
		if forward_backward < 0:
			negative = true			
		forward_backward = remap(abs(forward_backward), _y_axis_dead_zone, 1, 0, 1)
		if negative == true:
			forward_backward *= -1
			
		#print("input y %s" % forward_backward)
		player_body.ground_control_velocity.y += forward_backward * max_speed
		label.text = ""
	#elif forward_backward != 0:
	#	#print("deadzone y %s | %s" % [XRTools.get_y_axis_dead_zone(), forward_backward])
	#	label.text = "y %s | %s" % [XRTools.get_y_axis_dead_zone(), forward_backward]

	# Apply left/right ground control
	if strafe:
		if abs(left_right) > _x_axis_dead_zone:
			var negative = false
			if left_right < 0:
				negative = true	
			left_right = remap(abs(left_right), _x_axis_dead_zone, 1, 0, 1)
			if negative == true:
				left_right *= -1
			player_body.ground_control_velocity.x += left_right * max_speed
			#print("input x %s" % left_right)
			#label.text = ""
	#elif left_right != 0:
	#	print("deadzone x %s | %s" % [XRTools.get_x_axis_dead_zone(), left_right])
	#	#label.text = "x %s | %s" % [XRTools.get_x_axis_dead_zone(), left_right]
		
	# Clamp ground control
	var length := player_body.ground_control_velocity.length()
	if length > max_speed:
		player_body.ground_control_velocity *= max_speed / length


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Check the controller node
	if !XRHelpers.get_xr_controller(self):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings


## Find the left [XRToolsMovementDirect] node.
##
## This function searches from the specified node for the left controller
## [XRToolsMovementDirect] assuming the node is a sibling of the [XROrigin3D].
static func find_left(node : Node) -> XRToolsMovementDirect:
	return XRTools.find_xr_child(
		XRHelpers.get_left_controller(node),
		"*",
		"XRToolsMovementDirect") as XRToolsMovementDirect


## Find the right [XRToolsMovementDirect] node.
##
## This function searches from the specified node for the right controller
## [XRToolsMovementDirect] assuming the node is a sibling of the [XROrigin3D].
static func find_right(node : Node) -> XRToolsMovementDirect:
	return XRTools.find_xr_child(
		XRHelpers.get_right_controller(node),
		"*",
		"XRToolsMovementDirect") as XRToolsMovementDirect
