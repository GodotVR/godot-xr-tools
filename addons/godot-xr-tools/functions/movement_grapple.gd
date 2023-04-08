tool
class_name XRToolsMovementGrapple
extends XRToolsMovementProvider


## XR Tools Movement Provider for Grapple Movement
##
## This script provide simple grapple based movement - "bat hook" style
## where the player flings a rope to the target and swings on it.
## This script works with the [XRToolsPlayerBody] attached to the players
## [ARVROrigin].


## Signal emitted when grapple starts
signal grapple_started()

## Signal emitted when grapple finishes
signal grapple_finished()


## Grapple state
enum GrappleState {
	IDLE,			## Grapple is idle
	FIRED,			## Grapple is fired
	WINCHING,		## Grapple is winching
}


# Default grapple collision mask of 1-5 (world)
const DEFAULT_COLLISION_MASK := 0b0000_0000_0000_0000_0000_0000_0001_1111

# Default grapple enable mask of 5:grapple-target
const DEFAULT_ENABLE_MASK := 0b0000_0000_0000_0000_0000_0000_0001_0000


## Movement provider order
export var order : int = 20

## Grapple length - use to adjust maximum distance for possible grapple hooking.
export var grapple_length : float = 15.0

## Grapple collision mask
export (int, LAYERS_3D_PHYSICS) var grapple_collision_mask : int = DEFAULT_COLLISION_MASK \
	setget _set_grapple_collision_mask

## Grapple enable mask
export (int, LAYERS_3D_PHYSICS) var grapple_enable_mask : int = DEFAULT_ENABLE_MASK

## Impulse speed applied to the player on first grapple
export var impulse_speed : float = 10.0

## Winch speed applied to the player while the grapple is held
export var winch_speed : float = 2.0

## Probably need to add export variables for line size, maybe line material at
## some point so dev does not need to make children editable to do this.
## For now, right click on grapple node and make children editable to edit these
## facets.
export var rope_width : float = 0.02

## Air friction while grappling
export var friction : float = 0.1

## Grapple button (triggers grappling movement).  Be sure this button does not
## conflict with other functions.
export (XRTools.Buttons) var grapple_button_id : int = XRTools.Buttons.VR_TRIGGER

# Hook related variables
var hook_object : Spatial = null
var hook_local := Vector3(0,0,0)
var hook_point := Vector3(0,0,0)

# Grapple button state
var _grapple_button := false

# Get line creation nodes
onready var _line_helper : Spatial = $LineHelper
onready var _line : CSGCylinder = $LineHelper/Line

# Get Controller node - consider way to universalize this if user wanted to
# attach this to a gun instead of player's hand.  Could consider variable to
# select controller instead.
onready var _controller := ARVRHelpers.get_arvr_controller(self)

# Get Raycast node
onready var _grapple_raycast : RayCast = $Grapple_RayCast

# Get Grapple Target Node
onready var _grapple_target : Spatial = $Grapple_Target


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementGrapple" or .is_class(name)


# Function run when node is added to scene
func _ready():
	# Skip if running in the editor
	if Engine.editor_hint:
		return

	# Ensure grapple length is valid
	var min_hook_length := 1.5 * ARVRServer.world_scale
	if grapple_length < min_hook_length:
		grapple_length = min_hook_length

	# Set ray-cast
	_grapple_raycast.cast_to = Vector3(0, 0, -grapple_length) * ARVRServer.world_scale
	_grapple_raycast.collision_mask = grapple_collision_mask

	# Deal with line
	_line.radius = rope_width
	_line.hide()


# Update grapple display objects
func _process(_delta: float):
	# Skip if running in the editor
	if Engine.editor_hint:
		return

	# Update grapple line
	if is_active:
		var line_length := (hook_point - _controller.global_transform.origin).length()
		_line_helper.look_at(hook_point, Vector3.UP)
		_line.height = line_length
		_line.translation.z = line_length / -2
		_line.visible = true
	else:
		_line.visible = false

	# Update grapple target
	if enabled and !is_active and _is_raycast_valid():
		_grapple_target.global_transform.origin  = _grapple_raycast.get_collision_point()
		_grapple_target.global_transform = _grapple_target.global_transform.orthonormalized()
		_grapple_target.visible = true
	else:
		_grapple_target.visible = false


# Perform grapple movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Disable if requested
	if disabled or !enabled or !_controller.get_is_active():
		_set_grappling(false)
		return

	# Update grapple button
	var old_grapple_button := _grapple_button
	_grapple_button = _controller.is_button_pressed(grapple_button_id)

	# Enable/disable grappling
	var do_impulse := false
	if is_active and !_grapple_button:
		_set_grappling(false)
	elif _grapple_button and !old_grapple_button and _is_raycast_valid():
		hook_object = _grapple_raycast.get_collider()
		hook_point = _grapple_raycast.get_collision_point()
		hook_local = hook_object.global_transform.xform_inv(hook_point)
		do_impulse = true
		_set_grappling(true)

	# Skip if not grappling
	if !is_active:
		return

	# Get hook direction
	hook_point = hook_object.global_transform.xform(hook_local)
	var hook_vector := hook_point - _controller.global_transform.origin
	var hook_length := hook_vector.length()
	var hook_direction := hook_vector / hook_length

	# Apply gravity
	player_body.velocity += player_body.gravity * delta

	# Select the grapple speed
	var speed := impulse_speed if do_impulse else winch_speed
	if hook_length < 1.0:
		speed = 0.0

	# Ensure velocity is at least winch_speed towards hook
	var vdot = player_body.velocity.dot(hook_direction)
	if vdot < speed:
		player_body.velocity += hook_direction * (speed - vdot)

	# Scale down velocity
	player_body.velocity *= 1.0 - friction * delta

	# Perform exclusive movement as we have dealt with gravity
	player_body.velocity = player_body.move_body(player_body.velocity)
	return true


# Called when the grapple collision mask has been modified
func _set_grapple_collision_mask(new_value: int) -> void:
	grapple_collision_mask = new_value
	if is_inside_tree() and _grapple_raycast:
		_grapple_raycast.collision_mask = new_value


# Set the grappling state and fire any signals
func _set_grappling(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update the is_active flag
	is_active = active;

	# Report transition
	if is_active:
		emit_signal("grapple_started")
	else:
		emit_signal("grapple_finished")


# Test if the raycast is striking a valid target
func _is_raycast_valid() -> bool:
	# Fail if raycast not colliding
	if not _grapple_raycast.is_colliding():
		return false

	# Get the target of the raycast
	var target : CollisionObject = _grapple_raycast.get_collider()

	# Check tartget layer
	return true if target.collision_layer & grapple_enable_mask else false


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warning():
	# Check the controller node
	if !ARVRHelpers.get_arvr_controller(self):
		return "This node must be within a branch of an ARVRController node"

	# Call base class
	return ._get_configuration_warning()
