class_name XRFirearmBolt
extends MeshInstance3D


@export var _owner : XRToolsPickable

@export var _handle : XRToolsInteractableHandle

@export var _slide : XRFirearmSlide

@export var value : Vector3

# Current controller holding this object
var _current_controller : XRController3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRFirearmBolt"


func _ready() -> void:
	# Listen for when this object is picked up or dropped
	_handle.grabbed.connect(_on_grabbed)
	_handle.released.connect(_on_released)

# Called when this object is grabbed
func _on_grabbed(_pickable, _by) -> void:
	_update_controller_signals()


# Called when this object is released
func _on_released(_pickable, _by) -> void:
	_update_controller_signals()


# Update the controller signals
func _update_controller_signals() -> void:
	# Find the primary controller holding the firearm
	var controller := _handle.get_picked_up_by_controller()
	var grab_point := _handle.get_active_grab_point() as XRToolsGrabPointHand
	#if not grab_point or grab_point.handle != "Grip":
	#	controller = null

	# If the bound controller is no-longer correct then unbind
	if _current_controller and _current_controller != controller:
		if !_slide.slider_position:
			reset_rotation()
		_current_controller = null

	# If we need to bind to a new controller then bind
	if controller and not _current_controller:
		_current_controller = controller
		if !_slide.default_position:
			reset_rotation()
			rotation_degrees += value

func _on_controller_trigger_pressed(trigger_button : String):
	# Skip if not pose-toggle button
	if trigger_button != "trigger_click":
		return

	rotation_degrees += value


func _on_controller_trigger_released(trigger_button : String):
	# Skip if not pose-toggle button
	if trigger_button != "trigger_click":
		return

	reset_rotation()
func reset_rotation():
	rotation_degrees = Vector3(0,0,0)

