@tool
class_name XRToolsInteractableSlider
extends XRToolsInteractableHandleDriven


## XR Tools Interactable Slider script
##
## The interactable slider is a slider transform node controlled by the
## player through [XRToolsInteractableHandle] instances.
##
## The slider translates itelf along its local X axis, and so should be
## placed as a child of a node to translate and rotate as appropriate.
##
## The interactable slider is not a [RigidBody3D], and as such will not react
## to any collisions.


## Signal for slider moved
signal slider_moved(position)


## Slider step size (zero for no steps)
@export var slider_steps : float = 0.0 : set = _set_slider_steps

## Slider position
@export var slider_position : float = 0.0 : set = _set_slider_position

## Default position
@export var default_position : float = 0.0 : set = _set_default_position

## If true, the slider moves to the default position when released
@export var default_on_release : bool = false


## Slider origin
var _origin : XRToolsInteractableSliderOrigin


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableSlider" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Get the parent origin
	_origin = get_parent()

	# Set the initial position to match the initial slider position value
	transform = Transform3D(
		Basis.IDENTITY,
		Vector3(slider_position, 0.0, 0.0)
	)

	# Connect signals
	if released.connect(_on_slider_released):
		push_error("Cannot connect slider released signal")


# Called every frame when one or more handles are held by the player
func _process(_delta : float) -> void:
	# Get the total handle offsets
	var offset_sum := Vector3.ZERO
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		offset_sum += handle.global_transform.origin - handle.handle_origin.global_transform.origin

	# Rotate the offset sum vector from global into local coordinate space
	offset_sum = offset_sum * global_transform.basis

	# Get the average displacement in the X axis
	var offset := offset_sum.x / grabbed_handles.size()

	# Move the slider by the requested offset
	move_slider(slider_position + offset)


# Move the slider to the specified position
func move_slider(p_position : float) -> void:
	# Do the slider move
	p_position = _do_move_slider(p_position)
	if p_position == slider_position:
		return

	# Update the current position
	slider_position = p_position

	# Emit the moved signal
	emit_signal("slider_moved", p_position)


# Handle release of slider
func _on_slider_released(_interactable : XRToolsInteractableSlider):
	if default_on_release:
		move_slider(default_position)


# Called when the slider steps are set
func _set_slider_steps(p_slider_steps : float) -> void:
	slider_steps = maxf(0.0, p_slider_steps)


# Called when the slider position is set
func _set_slider_position(p_slider_position : float) -> void:
	slider_position = _do_move_slider(p_slider_position)


# Called when the default position is set
func _set_default_position(p_default_position : float) -> void:
	default_position = _clamp_position(p_default_position)


# Do the slider move
func _do_move_slider(p_position : float) -> float:
	# Clamp the position
	p_position = _clamp_position(p_position)

	# Move if necessary
	if p_position != slider_position:
		transform.origin.x = p_position

	# Return the updated position
	return p_position


# Clamp the position based on the hinge rules
func _clamp_position(p_position : float) -> float:
	# Apply hinge step-quantization
	if slider_steps:
		p_position = snappedf(p_position, slider_steps)

	# Apply hinge limits
	if _origin:
		p_position = clamp(p_position, _origin.limit_minimum, _origin.limit_maximum)

	# Return the updated position
	return p_position
