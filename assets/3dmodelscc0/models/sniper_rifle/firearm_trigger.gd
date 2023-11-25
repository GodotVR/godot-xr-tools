class_name XRFirearmTrigger
extends Node


@export var mesh_trigger : MeshInstance3D

@export var value : float

@export var handle_grabpoints : Array[XRToolsGrabPoint]

@onready var _parent : XRToolsPickable = get_parent()

# Current controller holding this object
var _current_controller : XRController3D

var triggered : bool = false


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRFirearmTrigger"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for when this object is picked up or dropped
	_parent.grabbed.connect(_on_grabbed)
	_parent.released.connect(_on_released)
	# disable handle grabpoints on ready
	for handle_grabpoint in handle_grabpoints:
		handle_grabpoint.enabled = false

func _physics_process(delta):
	if is_instance_valid(_parent):
		# toggle handle grabpoints if parent got grabbed/released
		if _parent.get_picked_up_by():
			for handle_grabpoint in handle_grabpoints:
				handle_grabpoint.enabled = true
		else:
			for handle_grabpoint in handle_grabpoints:
				handle_grabpoint.enabled = false

# Called when this object is grabbed
func _on_grabbed(_pickable, _by) -> void:
	_update_controller_signals()
	for handle_grabpoint in handle_grabpoints:
		handle_grabpoint.enabled = true

# Called when this object is released
func _on_released(_pickable, _by) -> void:
	# disables handle grabpoints to ensure no missgrab if pickable is not being held
	for handle_grabpoint in handle_grabpoints:
		handle_grabpoint.enabled = false
	_update_controller_signals()


# Update the controller signals
func _update_controller_signals() -> void:
	# Find the primary controller holding the firearm
	var controller := _parent.get_picked_up_by_controller()
	var grab_point := _parent.get_active_grab_point() as XRToolsGrabPointHand
	if not grab_point or grab_point.handle != "Grip":
		controller = null

	# If the bound controller is no-longer correct then unbind
	if _current_controller and _current_controller != controller:
		_current_controller.button_pressed.disconnect(_on_controller_trigger_pressed)
		_current_controller.button_released.disconnect(_on_controller_trigger_released)
		if triggered:
			mesh_trigger.rotate(Vector3(1, 0, 0), value)
			triggered = false
		_current_controller = null

	# If we need to bind to a new controller then bind
	if controller and not _current_controller:
		_current_controller = controller
		_current_controller.button_pressed.connect(_on_controller_trigger_pressed)
		_current_controller.button_released.connect(_on_controller_trigger_released)

# Called when a controller button is released
func _on_controller_trigger_released(trigger_button : String):
	# Skip if not pose-toggle button
	if trigger_button != "trigger_click":
		return

	mesh_trigger.rotate(Vector3(1, 0, 0), value)
	triggered = false


# Called when a controller button is pressed
func _on_controller_trigger_pressed(trigger_button : String):
	# Skip if not pose-toggle button
	if trigger_button != "trigger_click":
		return
	triggered = true
	mesh_trigger.rotate(Vector3(1, 0, 0), -value)
