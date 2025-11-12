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


## Constant for flattening a vector horizontally (X/Z only)
const VECTOR_XZ := Vector3(1.0, 0.0, 1.0)

## Constant for flattening a vector vertically (Y/Z only)
const VECTOR_YZ := Vector3(0.0, 1.0, 1.0)


## Joystick X minimum limit
@export var joystick_x_limit_min : float = -45.0: set = _set_joystick_x_limit_min

## Joystick X maximum limit
@export var joystick_x_limit_max : float = 45.0: set = _set_joystick_x_limit_max

## Joystick Y minimum limit
@export var joystick_y_limit_min : float = -45.0: set = _set_joystick_y_limit_min

## Joystick Y maximum limit
@export var joystick_y_limit_max : float = 45.0: set = _set_joystick_y_limit_max

## Joystick X step size (zero for no steps)
@export var joystick_x_steps : float = 0.0: set = _set_joystick_x_steps

## Joystick Y step size (zero for no steps)
@export var joystick_y_steps : float = 0.0: set = _set_joystick_y_steps

## Joystick X position
@export var joystick_x_position : float = 0.0: set = _set_joystick_x_position

## Joystick Y position
@export var joystick_y_position : float = 0.0: set = _set_joystick_y_position

## Default X position
@export var default_x_position : float = 0.0: set = _set_default_x_position

## Default Y position
@export var default_y_position : float = 0.0: set = _set_default_y_position

## If true, the joystick moves to the default position when released
@export var default_on_release : bool = false


# Joystick values in radians
@onready var _joystick_x_limit_min_rad : float = deg_to_rad(joystick_x_limit_min)
@onready var _joystick_x_limit_max_rad : float = deg_to_rad(joystick_x_limit_max)
@onready var _joystick_y_limit_min_rad : float = deg_to_rad(joystick_y_limit_min)
@onready var _joystick_y_limit_max_rad : float = deg_to_rad(joystick_y_limit_max)
@onready var _joystick_x_steps_rad : float = deg_to_rad(joystick_x_steps)
@onready var _joystick_y_steps_rad : float = deg_to_rad(joystick_y_steps)
@onready var _joystick_x_position_rad : float = deg_to_rad(joystick_x_position)
@onready var _joystick_y_position_rad : float = deg_to_rad(joystick_y_position)
@onready var _default_x_position_rad : float = deg_to_rad(default_x_position)
@onready var _default_y_position_rad : float = deg_to_rad(default_y_position)


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsInteractableJoystick" or super(xr_name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Set the initial position to match the initial joystick position value
	transform = Transform3D(
		Basis.from_euler(Vector3(_joystick_y_position_rad, _joystick_x_position_rad, 0)),
		Vector3.ZERO)

	# Connect signals
	if released.connect(_on_joystick_released):
		push_error("Cannot connect joystick released signal")


# Called every frame when one or more handles are held by the player
func _process(_delta: float) -> void:
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

		var to_handle_x := to_handle * VECTOR_XZ
		var to_handle_origin_x := to_handle_origin * VECTOR_XZ
		offset_x_sum += to_handle_origin_x.signed_angle_to(to_handle_x, Vector3.UP)

		var to_handle_y := to_handle * VECTOR_YZ
		var to_handle_origin_y := to_handle_origin * VECTOR_YZ
		offset_y_sum += to_handle_origin_y.signed_angle_to(to_handle_y, Vector3.RIGHT)

	# Average the angular offsets
	var offset_x := offset_x_sum / grabbed_handles.size()
	var offset_y := offset_y_sum / grabbed_handles.size()

	# Move the joystick by the requested offset
	move_joystick(
		_joystick_x_position_rad + offset_x,
		_joystick_y_position_rad + offset_y)


# Move the joystick to the specified position
func move_joystick(position_x: float, position_y: float) -> void:
	# Do the move
	var pos := _do_move_joystick(Vector2(position_x, position_y))
	if pos.x == _joystick_x_position_rad and pos.y == _joystick_y_position_rad:
		return

	# Update the current positon
	_joystick_x_position_rad = pos.x
	_joystick_y_position_rad = pos.y
	joystick_x_position = rad_to_deg(pos.x)
	joystick_y_position = rad_to_deg(pos.y)

	# Emit the joystick signal
	emit_signal("joystick_moved", joystick_x_position, joystick_y_position)


# Handle release of joystick
func _on_joystick_released(_interactable: XRToolsInteractableJoystick):
	if default_on_release:
		move_joystick(_default_x_position_rad, _default_y_position_rad)


# Called when joystick_x_limit_min is set externally
func _set_joystick_x_limit_min(value: float) -> void:
	joystick_x_limit_min = value
	_joystick_x_limit_min_rad = deg_to_rad(value)


# Called when joystick_y_limit_min is set externally
func _set_joystick_y_limit_min(value: float) -> void:
	joystick_y_limit_min = value
	_joystick_y_limit_min_rad = deg_to_rad(value)


# Called when joystick_x_limit_max is set externally
func _set_joystick_x_limit_max(value: float) -> void:
	joystick_x_limit_max = value
	_joystick_x_limit_max_rad = deg_to_rad(value)


# Called when joystick_y_limit_max is set externally
func _set_joystick_y_limit_max(value: float) -> void:
	joystick_y_limit_max = value
	_joystick_y_limit_max_rad = deg_to_rad(value)


# Called when joystick_x_steps is set externally
func _set_joystick_x_steps(value: float) -> void:
	joystick_x_steps = value
	_joystick_x_steps_rad = deg_to_rad(value)


# Called when joystick_y_steps is set externally
func _set_joystick_y_steps(value: float) -> void:
	joystick_y_steps = value
	_joystick_y_steps_rad = deg_to_rad(value)


# Called when joystick_x_position is set externally
func _set_joystick_x_position(value: float) -> void:
	var pos := Vector2(deg_to_rad(value), _joystick_y_position_rad)
	pos = _do_move_joystick(pos)
	joystick_x_position = rad_to_deg(pos.x)
	_joystick_x_position_rad = pos.x


# Called when joystick_y_position is set externally
func _set_joystick_y_position(value: float) -> void:
	var pos := Vector2(_joystick_x_position_rad, deg_to_rad(value))
	pos = _do_move_joystick(pos)
	joystick_y_position = rad_to_deg(pos.y)
	_joystick_y_position_rad = pos.y


# Called when default_x_position is set externally
func _set_default_x_position(value: float) -> void:
	default_x_position = value
	_default_x_position_rad = deg_to_rad(value)


# Called when default_y_position is set externally
func _set_default_y_position(value: float) -> void:
	default_y_position = value
	_default_y_position_rad = deg_to_rad(value)


# Do the joystick move
func _do_move_joystick(pos: Vector2) -> Vector2:
	# Apply joystick step-quantization
	if _joystick_x_steps_rad:
		pos.x = round(pos.x / _joystick_x_steps_rad) * _joystick_x_steps_rad
	if _joystick_y_steps_rad:
		pos.y = round(pos.y / _joystick_y_steps_rad) * _joystick_y_steps_rad

	# Apply joystick limits
	pos.x = clamp(pos.x, _joystick_x_limit_min_rad, _joystick_x_limit_max_rad)
	pos.y = clamp(pos.y, _joystick_y_limit_min_rad, _joystick_y_limit_max_rad)

	# Move if necessary
	if pos.x != _joystick_x_position_rad or pos.y != _joystick_y_position_rad:
		transform.basis = Basis.from_euler(Vector3(pos.y, pos.x, 0.0))

	# Return the updated position
	return pos
