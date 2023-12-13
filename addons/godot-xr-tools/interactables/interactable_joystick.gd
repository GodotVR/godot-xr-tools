@tool
class_name XRToolsInteractableJoystick
extends XRToolsInteractableHandleDriven


## XR Tools Interactable Joystick script
##
## The interactable joystick is a joystick transform node controlled by the
## player through [XRToolsInteractableHandle] instances.
##
## The joystick rotates itelf around its local X/Y axes, and so should be
## placed as a child of a node to translate and rotate as appropriate.
##
## The interactable joystick is not a [RigidBody3D], and as such will not react
## to any collisions.


## Signal for hinge moved
signal joystick_moved(x_angle, y_angle)


## Joystick X step size (zero for no steps)
@export var joystick_x_steps : float = 0.0 : set = _set_joystick_x_steps

## Joystick Y step size (zero for no steps)
@export var joystick_y_steps : float = 0.0 : set = _set_joystick_y_steps

## Joystick X position
@export var joystick_x_position : float = 0.0 : set = _set_joystick_x_position

## Joystick Y position
@export var joystick_y_position : float = 0.0 : set = _set_joystick_y_position

## Default X position
@export var default_x_position : float = 0.0 : set = _set_default_x_position

## Default Y position
@export var default_y_position : float = 0.0 : set = _set_default_y_position

## If true, the joystick moves to the default position when released
@export var default_on_release : bool = false


## Joystick origin
var _origin : XRToolsInteractableJoystickOrigin


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableJoystick" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Get the parent origin
	_origin = get_parent()

	# Set the initial position to match the initial joystick position value
	transform = Transform3D(
		Basis.from_euler(
			Vector3(
				-deg_to_rad(joystick_y_position),
				deg_to_rad(joystick_x_position),
				0.0)),
		Vector3.ZERO)

	# Connect signals
	if released.connect(_on_joystick_released):
		push_error("Cannot connect joystick released signal")


# Called every frame when one or more handles are held by the player
func _process(_delta : float) -> void:
	# Do not process in the editor
	if Engine.is_editor_hint():
		return

	# Skip if no handles grabbed
	if grabbed_handles.is_empty():
		return

	# Get the total handle angular offsets
	var offset_x_sum := 0.0
	var offset_y_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		var to_handle: Vector3 = handle.global_transform.origin * global_transform
		var to_handle_origin: Vector3 = handle.handle_origin.global_transform.origin * global_transform

		var to_handle_x := to_handle.slide(Vector3.UP)
		var to_handle_origin_x := to_handle_origin.slide(Vector3.UP)
		offset_x_sum += rad_to_deg(
			to_handle_origin_x.signed_angle_to(to_handle_x, Vector3.UP))

		var to_handle_y := to_handle.slide(Vector3.LEFT)
		var to_handle_origin_y := to_handle_origin.slide(Vector3.LEFT)
		offset_y_sum += rad_to_deg(
			to_handle_origin_y.signed_angle_to(to_handle_y, Vector3.LEFT))

	# Average the angular offsets
	var offset_x := offset_x_sum / grabbed_handles.size()
	var offset_y := offset_y_sum / grabbed_handles.size()

	# Move the joystick by the requested offset
	move_joystick(
		joystick_x_position + offset_x,
		joystick_y_position + offset_y)


# Move the joystick to the specified position
func move_joystick(pos_x: float, pos_y: float) -> void:
	# Do the move
	var pos := _do_move_joystick(Vector2(pos_x, pos_y))
	if pos.x == joystick_x_position and pos.y == joystick_y_position:
		return

	# Update the current positon
	joystick_x_position = pos.x
	joystick_y_position = pos.y

	# Emit the joystick signal
	emit_signal("joystick_moved", pos.x, pos.y)


# Handle release of joystick
func _on_joystick_released(_interactable: XRToolsInteractableJoystick):
	if default_on_release:
		move_joystick(default_x_position, default_y_position)


# Called when joystick_x_steps is set
func _set_joystick_x_steps(p_joystick_x_steps : float) -> void:
	joystick_x_steps = maxf(0.0, p_joystick_x_steps)


# Called when joystick_y_steps is set
func _set_joystick_y_steps(p_joystick_y_steps : float) -> void:
	joystick_y_steps = maxf(0.0, p_joystick_y_steps)


# Called when joystick_x_position is set
func _set_joystick_x_position(p_joystick_x_position : float) -> void:
	var pos := Vector2(p_joystick_x_position, joystick_y_position)
	pos = _do_move_joystick(pos)
	joystick_x_position = pos.x


# Called when joystick_y_position is set
func _set_joystick_y_position(p_joystick_y_position : float) -> void:
	var pos := Vector2(joystick_x_position, p_joystick_y_position)
	pos = _do_move_joystick(pos)
	joystick_y_position = pos.y


# Called when default_x_position is set
func _set_default_x_position(p_default_x_position : float) -> void:
	default_x_position = _clamp_x_position(p_default_x_position)


# Called when default_y_position is set
func _set_default_y_position(p_default_y_position : float) -> void:
	default_y_position = _clamp_y_position(p_default_y_position)


# Do the joystick move
func _do_move_joystick(p_pos: Vector2) -> Vector2:
	# Clamp position
	p_pos.x = _clamp_x_position(p_pos.x)
	p_pos.y = _clamp_y_position(p_pos.y)

	# Move if necessary
	if p_pos.x != joystick_x_position or p_pos.y != joystick_y_position:
		transform.basis = Basis.from_euler(
			Vector3(
				-deg_to_rad(p_pos.y),
				deg_to_rad(p_pos.x),
				0.0))

	# Return the updated position
	return p_pos


# Clamp the X position based on the hinge rules
func _clamp_x_position(p_x_position : float) -> float:
	# Apply joystick step-quantization
	if joystick_x_steps:
		p_x_position = snappedf(p_x_position, joystick_x_steps)

	# Apply joystick limits
	if _origin:
		p_x_position = clamp(p_x_position, _origin.limit_x_minimum, _origin.limit_x_maximum)

	# Return the updated x position
	return p_x_position


# Clamp the Y position based on the hinge rules
func _clamp_y_position(p_y_position : float) -> float:
	# Apply joystick step-quantization
	if joystick_y_steps:
		p_y_position = snappedf(p_y_position, joystick_y_steps)

	# Apply joystick limits
	if _origin:
		p_y_position = clamp(p_y_position, _origin.limit_y_minimum, _origin.limit_y_maximum)

	# Return the updated y position
	return p_y_position
