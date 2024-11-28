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
@export var hinge_limit_min : float = -45.0

## Hinge maximum limit
@export var hinge_limit_max : float = 45.0

## Hinge step size (zero for no steps)
@export var hinge_steps : float = 0.0


## Hinge position
@export var hinge_position : float = 0.0:
	set(v):
		# Apply constraints
		var radians = _apply_hinge_constraints(deg_to_rad(v))

		# No change
		if is_equal_approx(radians, _hinge_position_rad):
			return

		# Set, Emit
		_is_driven_change = true
		transform = _private_transform.rotated_local(hinge_axis, radians)
		hinge_position = rad_to_deg(radians)
		hinge_moved.emit(hinge_position)


## Default position
@export var default_position : float = 0.0

## Allow hinge to wrap between min and max limits
@export var hinge_wrapping : bool = false

## If true, the hinge moves to the default position when releases
@export var default_on_release : bool = false

## Define a local axis to rotate about
@export var hinge_axis := Vector3.RIGHT:
	set(v):
		hinge_axis = v.normalized()

# Hinge values in radians
@onready var _hinge_limit_min_rad  : float:
	get: return deg_to_rad(hinge_limit_min)
@onready var _hinge_limit_max_rad  : float:
	get: return deg_to_rad(hinge_limit_max)
@onready var _hinge_steps_rad      : float:
	get: return deg_to_rad(hinge_steps)
@onready var _hinge_position_rad   : float:
	get: return deg_to_rad(hinge_position)
@onready var _default_position_rad : float:
	get: return deg_to_rad(default_position)


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
	for handle : XRToolsInteractableHandle in grabbed_handles:
		# Move to local space
		var to_handle := handle.global_transform.origin * global_transform
		var to_origin := handle.handle_origin.global_transform.origin * global_transform

		# Find angle
		# Project 'to_handle' and 'to_handle_origin' on 'hinge_axis'
		offset_sum += atan2(to_origin.cross(to_handle).dot(hinge_axis), to_handle.dot(to_origin))

	# Average the angular offsets
	var offset := offset_sum / grabbed_handles.size()

	# Move the hinge by the requested offset
	move_hinge(_hinge_position_rad + offset)


# Move the hinge to the specified position
func move_hinge(radians: float) -> void:
	# Do the hinge move
	hinge_position = rad_to_deg(radians)


# Returns 'radians' with step-quantization and min/max limits applied
func _apply_hinge_constraints(radians: float) -> float:
	# Apply hinge step-quantization
	if !is_zero_approx(_hinge_steps_rad):
		radians = roundf(radians / _hinge_steps_rad) * _hinge_steps_rad

	# Apply hinge limits
	if hinge_wrapping:
		return wrapf(radians, _hinge_limit_min_rad, _hinge_limit_max_rad)
	return clampf(radians, _hinge_limit_min_rad, _hinge_limit_max_rad)


# Handle release of hinge
func _on_hinge_released(_interactable: XRToolsInteractableHinge):
	if default_on_release:
		move_hinge(_default_position_rad)
