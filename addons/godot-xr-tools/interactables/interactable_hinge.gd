@tool
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
## The interactable hinge is not a [RigidBody3D], and as such will not react
## to any collisions.


## Signal for hinge moved
signal hinge_moved(angle)


## Hinge minimum limit
@export var hinge_limit_min : float = -45.0: set = _set_hinge_limit_min

## Hinge maximum limit
@export var hinge_limit_max : float = 45.0: set = _set_hinge_limit_max

## Hinge step size (zero for no steps)
@export var hinge_steps : float = 0.0: set = _set_hinge_steps

## Hinge position
@export var hinge_position : float = 0.0: set = _set_hinge_position

## Default position
@export var default_position : float = 0.0: set = _set_default_position

## If true, the hinge moves to the default position when releases
@export var default_on_release : bool = false

## Set to rotate about this local axis
@export var hinge_axis := Vector3.RIGHT:
	set(v):
		hinge_axis = v.normalized()

# Hinge values in radians
@onready var _hinge_limit_min_rad : float = deg_to_rad(hinge_limit_min)
@onready var _hinge_limit_max_rad : float = deg_to_rad(hinge_limit_max)
@onready var _hinge_steps_rad : float = deg_to_rad(hinge_steps)
@onready var _hinge_position_rad : float = deg_to_rad(hinge_position)
@onready var _default_position_rad : float = deg_to_rad(default_position)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableHinge" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Connect signals
	if released.connect(_on_hinge_released):
		push_error("Cannot connect hinge released signal")


# Called every frame when one or more handles are held by the player
func _process(_delta: float) -> void:
	# Get the total handle angular offsets
	var offset_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		# global handle + handle_origin position
		var axis := get_final_axis()
		var to_handle        : Vector3 = handle.global_transform.origin * global_transform
		var to_handle_origin : Vector3 = handle.handle_origin.global_transform.origin * global_transform
		var a_old = to_handle_origin.signed_angle_to(to_handle, axis)

		# project 'to_handle' and 'to_handle_origin' on 'axis'
		# then measure the angle
		offset_sum += atan2(to_handle_origin.cross(to_handle).dot(axis), to_handle.dot(to_handle_origin))

	# Average the angular offsets
	var offset := offset_sum / grabbed_handles.size()

	# Move the hinge by the requested offset
	move_hinge(_hinge_position_rad + offset)


## Return a unit vector of the final rotation axis
func get_final_axis() -> Vector3:
	return (hinge_axis * _private_transform.basis.inverse()).normalized()


# Move the hinge to the specified position
func move_hinge(position: float) -> void:
	# Do the hinge move
	position = _do_move_hinge(position)
	if position == _hinge_position_rad:
		return

	# Update the current positon
	_hinge_position_rad = position
	hinge_position = rad_to_deg(position)

	# Emit the moved signal
	hinge_moved.emit(hinge_position)


# Handle release of hinge
func _on_hinge_released(_interactable: XRToolsInteractableHinge):
	if default_on_release:
		move_hinge(_default_position_rad)


# Called when hinge_limit_min is set externally
func _set_hinge_limit_min(value: float) -> void:
	hinge_limit_min = value
	_hinge_limit_min_rad = deg_to_rad(value)


# Called when hinge_limit_max is set externally
func _set_hinge_limit_max(value: float) -> void:
	hinge_limit_max = value
	_hinge_limit_max_rad = deg_to_rad(value)


# Called when hinge_steps is set externally
func _set_hinge_steps(value: float) -> void:
	hinge_steps = value
	_hinge_steps_rad = deg_to_rad(value)


# Called when hinge_position is set externally
func _set_hinge_position(value: float) -> void:
		
	_is_driven_change = true
	var rads := deg_to_rad(value)
	rads = _do_move_hinge(rads)
	hinge_position = rad_to_deg(rads)
	_hinge_position_rad = rads


# Called when default_position is set externally
func _set_default_position(value: float) -> void:
	default_position = value
	_default_position_rad = deg_to_rad(value)


# Do the hinge move
func _do_move_hinge(_angle_radians: float) -> float:
	# Apply hinge step-quantization
	if _hinge_steps_rad:
		_angle_radians = round(_angle_radians / _hinge_steps_rad) * _hinge_steps_rad

	# Apply hinge limits
	_angle_radians = clamp(_angle_radians, _hinge_limit_min_rad, _hinge_limit_max_rad)

	# Move if necessary
	if _angle_radians != _hinge_position_rad:
		_is_driven_change = true
		transform = _private_transform.rotated_local(get_final_axis(), _angle_radians)

	# Return the updated _angle_radians
	return _angle_radians
