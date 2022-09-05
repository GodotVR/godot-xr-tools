class_name XRTInteractableJoystick
extends XRTInteractableHandleDriven


##
## Interactable Joystick script
##
## @desc:
##     The interactable joystick is a joystick transform node controlled by the
##     player through interactable handles.
##
##     The joystick rotates itelf around its local X/Y axes, and so should be
##     placed as a child of a spatial node to translate and rotate as 
##     appropriate.
##
##     The interactable joystick is not a rigid body, and as such will not react
##     to any collisions.
##  


## Constant for flattening a vector horizontally (X/Z only)
const VECTOR_XZ := Vector3(1.0, 0.0, 1.0)

## Constant for flattening a vector vertically (Y/Z only)
const VECTOR_YZ := Vector3(0.0, 1.0, 1.0)


## Signal for hinge moved
signal joystick_moved(x_angle, y_angle)

## Joystick X minimum limit
export var joystick_x_limit_min := -45.0 setget _set_joystick_x_limit_min

## Joystick X maximum limit
export var joystick_x_limit_max := 45.0 setget _set_joystick_x_limit_max

## Joystick Y minimum limit
export var joystick_y_limit_min := -45.0 setget _set_joystick_y_limit_min

## Joystick Y maximum limit
export var joystick_y_limit_max := 45.0 setget _set_joystick_y_limit_max

## Joystick X step size (zero for no steps)
export var joystick_x_steps := 0.0 setget _set_joystick_x_steps

## Joystick Y step size (zero for no steps)
export var joystick_y_steps := 0.0 setget _set_joystick_y_steps

## Joystick X position
export var joystick_x_position := 0.0 setget _set_joystick_x_position

## Joystick Y position
export var joystick_y_position := 0.0 setget _set_joystick_y_position

## Default X position
export var default_x_position := 0.0

## Default Y position
export var default_y_position := 0.0

## Move to default position on release
export var default_on_release := false


# Joystick values in radians
onready var _joystick_x_limit_min_rad := deg2rad(joystick_x_limit_min)
onready var _joystick_x_limit_max_rad := deg2rad(joystick_x_limit_max)
onready var _joystick_y_limit_min_rad := deg2rad(joystick_y_limit_min)
onready var _joystick_y_limit_max_rad := deg2rad(joystick_y_limit_max)
onready var _joystick_x_steps_rad := deg2rad(joystick_x_steps)
onready var _joystick_y_steps_rad := deg2rad(joystick_y_steps)
onready var _joystick_x_position_rad := deg2rad(joystick_x_position)
onready var _joystick_y_position_rad := deg2rad(joystick_y_position)
onready var _default_x_position_rad := deg2rad(default_x_position)
onready var _default_y_position_rad := deg2rad(default_y_position)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the initial position to match the initial joystick position value
	transform = Transform(
		Basis(Vector3(_joystick_y_position_rad, _joystick_x_position_rad, 0)), 
		Vector3.ZERO)

	# Connect signals
	if connect("released", self, "_on_joystick_released"):
		push_error("Cannot connect joystick released signal")


# Called every frame when one or more handles are held by the player
func _process(var _delta: float) -> void:
	# Get the total handle angular offsets
	var offset_x_sum := 0.0
	var offset_y_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRTInteractableHandle
		var to_handle: Vector3 = global_transform.xform_inv(handle.global_transform.origin) 
		var to_handle_origin: Vector3 = global_transform.xform_inv(handle.handle_origin.global_transform.origin)

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
func move_joystick(var position_x: float, var position_y: float) -> void:
	# Apply joystick step-quantization
	if _joystick_x_steps_rad:
		position_x = round(position_x / _joystick_x_steps_rad) * _joystick_x_steps_rad
	if _joystick_y_steps_rad:
		position_y = round(position_y / _joystick_y_steps_rad) * _joystick_y_steps_rad

	# Apply joystick limits
	position_x = clamp(position_x, _joystick_x_limit_min_rad, _joystick_x_limit_max_rad)
	position_y = clamp(position_y, _joystick_y_limit_min_rad, _joystick_y_limit_max_rad)

	# Skip if the position has not changed
	if position_x == _joystick_x_position_rad and position_y == _joystick_y_position_rad:
		return

	# Update the current positon
	_joystick_x_position_rad = position_x
	_joystick_y_position_rad = position_y
	joystick_x_position = rad2deg(position_x)
	joystick_y_position = rad2deg(position_y)

	# Update the transform
	transform.basis = Basis(Vector3(_joystick_y_position_rad, _joystick_x_position_rad, 0))

	# Emit the joystick signal
	emit_signal("joystick_moved", joystick_x_position, joystick_y_position)


# Handle release of joystick
func _on_joystick_released(var _interactable):
	if default_on_release:
		move_joystick(_default_x_position_rad, _default_y_position_rad)


# Called when joystick_x_limit_min is set externally
func _set_joystick_x_limit_min(var value: float) -> void:
	joystick_x_limit_min = value
	_joystick_x_limit_min_rad = deg2rad(value)


# Called when joystick_y_limit_min is set externally
func _set_joystick_y_limit_min(var value: float) -> void:
	joystick_y_limit_min = value
	_joystick_y_limit_min_rad = deg2rad(value)


# Called when joystick_x_limit_max is set externally
func _set_joystick_x_limit_max(var value: float) -> void:
	joystick_x_limit_max = value
	_joystick_x_limit_max_rad = deg2rad(value)


# Called when joystick_y_limit_max is set externally
func _set_joystick_y_limit_max(var value: float) -> void:
	joystick_y_limit_max = value
	_joystick_y_limit_max_rad = deg2rad(value)


# Called when joystick_x_steps is set externally
func _set_joystick_x_steps(var value: float) -> void:
	joystick_x_steps = value
	_joystick_x_steps_rad = deg2rad(value)


# Called when joystick_y_steps is set externally
func _set_joystick_y_steps(var value: float) -> void:
	joystick_y_steps = value
	_joystick_y_steps_rad = deg2rad(value)


# Called when joystick_x_position is set externally
func _set_joystick_x_position(var value: float) -> void:
	joystick_x_position = value
	_joystick_x_position_rad = deg2rad(value)
	if is_inside_tree():
		move_joystick(_joystick_x_position_rad, _joystick_y_position_rad)


# Called when joystick_y_position is set externally
func _set_joystick_y_position(var value: float) -> void:
	joystick_y_position = value
	_joystick_y_position_rad = deg2rad(value)
	if is_inside_tree():
		move_joystick(_joystick_x_position_rad, _joystick_y_position_rad)


# Called when default_x_position is set externally
func _set_default_x_position(var value: float) -> void:
	default_x_position = value
	_default_x_position_rad = deg2rad(value)


# Called when default_y_position is set externally
func _set_default_y_position(var value: float) -> void:
	default_y_position = value
	_default_y_position_rad = deg2rad(value)
