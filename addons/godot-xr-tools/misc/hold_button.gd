@tool
class_name XRToolsHoldButton
extends Node3D

## XR Tools Hold Button script
##
## Checks whether an Input Action or an action from the OpenXR Action Map has
## been pressed for a specified amount of time

## Emitted when the button has been held for long enough
signal pressed


## Whether the button has been enabled
@export var enabled := false: set = set_enabled

## OpenXR Action that presses the button
@export var activate_action := "trigger_click"

## Input Action that presses the button
@export var activate_action_desktop := "ui_accept"

## How long a button should be pressed down before it counts as being pressed
@export var hold_time := 2.0

## Color of our visualisation
@export var color := Color(1.0, 1.0, 1.0, 1.0): set = set_color

## Size of the button
@export var size := Vector2(1.0, 1.0): set = set_size


var time_held := 0.0
var material: ShaderMaterial
var xr_start_node: XRToolsStartXR


@onready var _visual: MeshInstance3D = $Visualise


# When the node enters the scene tree for the first time.
func _ready() -> void:
	material = _visual.get_surface_override_material(0)
	xr_start_node = XRToolsStartXR.get_start_xr_node()

	if not Engine.is_editor_hint():
		_set_time_held(0.0)

	_update_size()
	_update_color()
	_update_enabled()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	var button_pressed = false

	# we check all trackers
	var controllers := XRServer.get_trackers(XRServer.TRACKER_CONTROLLER)
	for controller in controllers:
		var tracker: XRPositionalTracker = controllers[controller]
		if tracker.get_input(activate_action):
			button_pressed = true

	if not xr_start_node.is_xr_active():
		if Input.is_action_pressed(activate_action_desktop):
			button_pressed = true

	if button_pressed:
		_set_time_held(time_held + delta)
		if time_held > hold_time:
			# done, disable this
			set_enabled(false)
			pressed.emit()
	else:
		_set_time_held(max(0.0, time_held - delta))


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsHoldButton"


func set_color(p_color: Color) -> void:
	color = p_color
	_update_color()


func set_enabled(p_enabled: bool) -> void:
	enabled = p_enabled
	_update_enabled()


func set_size(p_size: Vector2) -> void:
	size = p_size
	_update_size()


func _set_time_held(p_time_held: float) -> void:
	time_held = p_time_held
	if material:
		_visual.visible = time_held > 0.0
		material.set_shader_parameter("value", time_held/hold_time)


func _update_color() -> void:
	if material:
		material.set_shader_parameter("albedo", color)


func _update_enabled() -> void:
	if is_inside_tree() and not Engine.is_editor_hint():
		_set_time_held(0.0)
		set_process(enabled)


func _update_size() -> void:
	if material: # Note, material won't be set until after we setup our scene
		var mesh: QuadMesh = _visual.mesh
		if mesh.size != size:
			mesh.size = size

			# updating the size will unset our material, so reset it
			_visual.set_surface_override_material(0, material)
