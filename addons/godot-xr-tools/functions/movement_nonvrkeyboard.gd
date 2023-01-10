tool
class_name XRToolsMovementNonVRKeyboard
extends XRToolsMovementProvider


##
## Movement Provider for Direct Movement via keyboard control from a PC 
## when VR is not operating.  Intended as an easy debugging tool without 
## entering VR, or as an alternative default pancake interface.
##
## @desc:
##     This script provides direct movement for the player. This script works
##     with the PlayerBody attached to the players ARVROrigin.
##
##     The following types of direct movement are supported:
##      - Slewing
##      - Forwards and backwards motion
##      - Turning
##      - Camera pitch orientation
##
##

## Movement provider order
export var order : int = 10

## Movement speed
export var keyboard_walk_speed : float = 2.0

export var keyboard_smooth_turn_speed : float = 2.0

export var mouse_sensitivity : float = 0.1

## Disable if VR active
export var disable_in_VR : bool = true

# Origin node
onready var origin_node : ARVROrigin = ARVRHelpers.get_arvr_origin(self)

## ARVRCamera node
onready var camera_node : ARVRCamera = ARVRHelpers.get_arvr_camera(self)

# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementNonVRKeyboard" or .is_class(name)

var disable_nonvrkeyboardmovement : bool = false
var uncapturedmousemode = Input.MOUSE_MODE_VISIBLE
func _ready():
	if disable_in_VR and get_viewport().arvr:
		print("*** Removing from group")
		remove_from_group("movement_providers")
		disable_nonvrkeyboardmovement = true
	else:
		uncapturedmousemode = Input.get_mouse_mode()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

var cumulativemousemotion_physicsframe = Vector2.ZERO
func _input(event):
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			cumulativemousemotion_physicsframe += event.relative
	if event is InputEventKey:
		if event.pressed and event.scancode == KEY_ESCAPE:
			Input.set_mouse_mode(uncapturedmousemode if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)
			
# Perform jump movement
func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	if disable_nonvrkeyboardmovement:
		return

	if cumulativemousemotion_physicsframe != Vector2.ZERO:
		camera_node.rotation_degrees.x = clamp(camera_node.rotation_degrees.x - cumulativemousemotion_physicsframe.y*(90.0/200.0)*mouse_sensitivity, -89, 89)
		camera_node.rotation_degrees.y = camera_node.rotation_degrees.y + cumulativemousemotion_physicsframe.x*(90.0/200.0)*mouse_sensitivity
		cumulativemousemotion_physicsframe = Vector2.ZERO

	var kvec : Vector2 = Input.get_vector("ui_left", "ui_right", "ui_down", "ui_up")

	if Input.is_pressed(KEY_SHIFT):
		if kvec.x != 0:
			player_body.rotate_player(player_body, keyboard_smooth_turn_speed * _delta * kvec.x)
		kvec = Vector2.ZERO

	if kvec != Vector2.ZERO:
		player_body.ground_control_velocity += kvec * keyboard_walk_speed

		# Clamp ground control
		var length := player_body.ground_control_velocity.length()
		if length > keyboard_walk_speed:
			player_body.ground_control_velocity *= keyboard_walk_speed / length
		player_body.ground_control_velocity += kvec * keyboard_walk_speed


# Rotate the origin node around the camera
func _rotate_player(player_body: XRToolsPlayerBody, angle: float):
	var t1 := Transform()
	var t2 := Transform()
	var rot := Transform()

	t1.origin = -player_body.camera_node.transform.origin
	t2.origin = player_body.camera_node.transform.origin
	rot = rot.rotated(Vector3(0.0, -1.0, 0.0), angle)
	player_body.origin_node.transform = (player_body.origin_node.transform * t2 * rot * t1).orthonormalized()


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	if !ARVRHelpers.get_arvr_origin(self):
		return "This node must be within a branch of an ARVROrigin node"

	# Call base class
	return ._get_configuration_warning()


