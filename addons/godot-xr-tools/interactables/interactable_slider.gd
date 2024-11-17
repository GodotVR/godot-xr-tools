@tool
class_name XRToolsInteractableSlider
extends XRToolsInteractableHandleDriven


## XR Tools Interactable Slider script
##
## A transform node controlled by the user through [XRToolsInteractableHandle] instances.
##
## An example scene may be setup in the following way:
## XRSlider
##     SliderModel (A Firearm Bolt, or Door Handle)
##         GrabPointHandLeft
##     InteractableHandle
##         CollisionShape3D
##         GrabPointRedirectLeft (set to 'GrabPointHandLeft')
##
## The interactable slider is not a [RigidBody3D], and as such will not react
## to any collisions.


signal slider_moved(offset: float)


## Start position for slide, can be positiv and negativ in values
@export var slider_limit_min : float = 0.0:
	set(v):
		slider_limit_min = minf(v, slider_limit_max)
		slider_position = slider_position

## End position for slide, can be positiv and negativ in values
@export var slider_limit_max : float = 1.0:
	set(v):
		slider_limit_max = maxf(v, slider_limit_min)
		slider_position = slider_position

## Signal for slider moved
## Slider step size (zero for no steps)
@export var slider_steps : float = 0.0:
	set(v):
		slider_steps = maxf(v, 0)

## Slider position - move to test the position setup
@export var slider_position : float = 0.0:
	set(v):
		# Apply slider step-quantization
		if !is_zero_approx(slider_steps):
			v = roundf(v / slider_steps) * slider_steps

		# Clamp position
		v = clampf(v, slider_limit_min, slider_limit_max)

		# No change
		if is_equal_approx(slider_position, v):
			return

		# Set, Emit
		_is_driven_change = true
		position = _private_transform.origin - (v * get_slider_direction())
		slider_position = v
		slider_moved.emit(v)

## Default position
@export var default_position : float = 0.0

## If true, the slider moves to the default position when released
@export var default_on_release : bool = false


# Add support for is_xr_class on XRTools classes
func is_xr_class(_name : String) -> bool:
	return _name == "XRToolsInteractableSlider" or super(_name)


func _ready() -> void:
	super()

	# Connect signals
	if released.connect(_on_released):
		push_error("Cannot connect slider released signal")


func _process(_delta: float) -> void:
	if grabbed_handles.is_empty():
		return

	# Get the total handle offsets
	var offset_sum := 0.0
	for item in grabbed_handles:
		var handle := item as XRToolsInteractableHandle
		var hlocal := to_local(handle.global_position)
		offset_sum = hlocal.dot(get_slider_direction())

	slider_position -= offset_sum / grabbed_handles.size()


## Returns a Unit Vector3 pointing backwards relative to the current transform
func get_slider_direction() -> Vector3:
		return (Vector3.BACK * _private_transform.basis.inverse()).normalized()


func _on_released(_interactable: Variant) -> void:
	if default_on_release:
		slider_position = default_position
