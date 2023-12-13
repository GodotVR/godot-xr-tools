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


## Hinge step size (zero for no steps)
@export var hinge_steps : float = 0.0: set = _set_hinge_steps

## Hinge position
@export var hinge_position : float = 0.0: set = _set_hinge_position

## Default position
@export var default_position : float = 0.0: set = _set_default_position

## If true, the hinge moves to the default position when releases
@export var default_on_release : bool = false


## Hinge origin
var _origin : XRToolsInteractableHingeOrigin


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableHinge" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Get the parent origin
	_origin = get_parent()

	# Set the initial position to match the initial hinge position value
	transform = Transform3D(
		Basis.from_euler(Vector3(-deg_to_rad(hinge_position), 0, 0)),
		Vector3.ZERO
	)

	# Connect signals
	if released.connect(_on_hinge_released):
		push_error("Cannot connect hinge released signal")


# Check for configuration warnings
func _get_configuration_warnings() -> PackedStringArray:
	var ret := PackedStringArray()

	# Check for origin
	var origin := get_parent() as XRToolsInteractableHingeOrigin
	if not origin:
		ret.append("Must be a child of an XRToolsInteractableHingeOrigin")

	return ret


# Called every frame when one or more handles are held by the player
func _process(_delta: float) -> void:
	# Get the total handle angular offsets
	var offset_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		var to_handle: Vector3 = handle.global_transform.origin * global_transform
		var to_handle_origin: Vector3 = handle.handle_origin.global_transform.origin * global_transform
		to_handle = to_handle.slide(Vector3.LEFT)
		to_handle_origin = to_handle_origin.slide(Vector3.LEFT)
		offset_sum += rad_to_deg(to_handle_origin.signed_angle_to(to_handle, Vector3.LEFT))

	# Average the angular offsets
	var offset := offset_sum / grabbed_handles.size()

	# Move the hinge by the requested offset
	move_hinge(hinge_position + offset)


# Move the hinge to the specified position
func move_hinge(p_position: float) -> void:
	# Do the hinge move
	p_position = _do_move_hinge(p_position)
	if p_position == hinge_position:
		return

	# Update the current positon
	hinge_position = p_position

	# Emit the moved signal
	emit_signal("hinge_moved", p_position)


# Handle release of hinge
func _on_hinge_released(_interactable: XRToolsInteractableHinge):
	if default_on_release:
		move_hinge(default_position)


# Called when hinge_steps is set externally
func _set_hinge_steps(p_hinge_steps: float) -> void:
	hinge_steps = maxf(0.0, p_hinge_steps)


# Called when hinge_position is set externally
func _set_hinge_position(p_hinge_position: float) -> void:
	hinge_position = _do_move_hinge(p_hinge_position)


# Called when default_position is set externally
func _set_default_position(p_default_position: float) -> void:
	default_position = _clamp_position(p_default_position)


# Do the hinge move
func _do_move_hinge(p_position: float) -> float:
	# Clamp the position
	p_position = _clamp_position(p_position)

	# Move if necessary
	if p_position != hinge_position:
		transform.basis = Basis.from_euler(
			Vector3(-deg_to_rad(p_position), 0.0, 0.0))

	# Return the updated position
	return p_position


# Clamp the position based on the hinge rules
func _clamp_position(p_position : float) -> float:
	# Apply hinge step-quantization
	if hinge_steps:
		p_position = snappedf(p_position, hinge_steps)

	# Apply hinge limits
	if _origin:
		p_position = clamp(p_position, _origin.limit_minimum, _origin.limit_maximum)

	# Return the updated position
	return p_position
