tool
class_name XRToolsInteractableHinge
extends XRToolsInteractableHandleDriven


## XR Tools Interactable Hinge script
##
## The interactable hinge is a hinge transform node controlled by the
## player through one or more [XRToolsInteractableHandle] instances.
##
## The hinge rotates itelf around its local X axis, and so should be
## placed as a child of a node to translate and rotate as appropriate.
##
## The interactable hinge is not a [RigidBody], and as such will not react
## to any collisions.


## Signal for hinge moved
signal hinge_moved(angle)


## Hinge minimum limit
export var hinge_limit_min : float = -45.0 setget _set_hinge_limit_min

## Hinge maximum limit
export var hinge_limit_max : float = 45.0 setget _set_hinge_limit_max

## Hinge step size (zero for no steps)
export var hinge_steps : float = 0.0 setget _set_hinge_steps

## Hinge position
export var hinge_position : float = 0.0 setget _set_hinge_position

## Default position
export var default_position : float = 0.0 setget _set_default_position

## If true, the hinge moves to the default position when releases
export var default_on_release : bool = false


# Hinge values in radians
onready var _hinge_limit_min_rad : float = deg2rad(hinge_limit_min)
onready var _hinge_limit_max_rad : float = deg2rad(hinge_limit_max)
onready var _hinge_steps_rad : float = deg2rad(hinge_steps)
onready var _hinge_position_rad : float = deg2rad(hinge_position)
onready var _default_position_rad : float = deg2rad(default_position)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsInteractableHinge" or .is_class(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set the initial position to match the initial hinge position value
	transform = Transform(
		Basis(Vector3(_hinge_position_rad, 0, 0)),
		Vector3.ZERO
	)

	# Connect signals
	if connect("released", self, "_on_hinge_released"):
		push_error("Cannot connect hinge released signal")


# Called every frame when one or more handles are held by the player
func _process(_delta: float) -> void:
	# Get the total handle angular offsets
	var offset_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		var to_handle: Vector3 = global_transform.xform_inv(handle.global_transform.origin)
		var to_handle_origin: Vector3 = global_transform.xform_inv(
				handle.handle_origin.global_transform.origin)
		to_handle.x = 0.0
		to_handle_origin.x = 0.0
		offset_sum += to_handle_origin.signed_angle_to(to_handle, Vector3.RIGHT)

	# Average the angular offsets
	var offset := offset_sum / grabbed_handles.size()

	# Move the hinge by the requested offset
	move_hinge(_hinge_position_rad + offset)


# Move the hinge to the specified position
func move_hinge(position: float) -> void:
	# Do the hinge move
	position = _do_move_hinge(position)
	if position == _hinge_position_rad:
		return

	# Update the current positon
	_hinge_position_rad = position
	hinge_position = rad2deg(position)

	# Emit the moved signal
	emit_signal("hinge_moved", hinge_position)


# Handle release of hinge
func _on_hinge_released(_interactable: XRToolsInteractableHinge):
	if default_on_release:
		move_hinge(_default_position_rad)


# Called when hinge_limit_min is set externally
func _set_hinge_limit_min(value: float) -> void:
	hinge_limit_min = value
	_hinge_limit_min_rad = deg2rad(value)


# Called when hinge_limit_max is set externally
func _set_hinge_limit_max(value: float) -> void:
	hinge_limit_max = value
	_hinge_limit_max_rad = deg2rad(value)


# Called when hinge_steps is set externally
func _set_hinge_steps(value: float) -> void:
	hinge_steps = value
	_hinge_steps_rad = deg2rad(value)


# Called when hinge_position is set externally
func _set_hinge_position(value: float) -> void:
	var position := deg2rad(value)
	position = _do_move_hinge(position)
	hinge_position = rad2deg(position)
	_hinge_position_rad = position


# Called when default_position is set externally
func _set_default_position(value: float) -> void:
	default_position = value
	_default_position_rad = deg2rad(value)


# Do the hinge move
func _do_move_hinge(position: float) -> float:
	# Apply hinge step-quantization
	if _hinge_steps_rad:
		position = round(position / _hinge_steps_rad) * _hinge_steps_rad

	# Apply hinge limits
	position = clamp(position, _hinge_limit_min_rad, _hinge_limit_max_rad)

	# Move if necessary
	if position != _hinge_position_rad:
		transform.basis = Basis(Vector3(position, 0.0, 0.0))

	# Return the updated position
	return position
