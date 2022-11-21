tool
class_name XRToolsHoldButton
extends Spatial


signal pressed


# Enable our button
export var enabled : bool = false setget set_enabled

export (XRTools.Buttons) var activate_button : int = XRTools.Buttons.VR_TRIGGER

# Countdown
export var hold_time : float = 2.0

# Color our our visualisation
export var color : Color = Color(1.0, 1.0, 1.0, 1.0) setget set_color

# Size
export var size : Vector2 = Vector2(1.0, 1.0) setget set_size


var time_held = 0.0

var material : ShaderMaterial


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsHoldButton" or .is_class(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	material = $Visualise.get_surface_material(0)

	if !Engine.is_editor_hint():
		_set_time_held(0.0)

	_update_size()
	_update_color()
	_update_enabled()


func _process(delta):
	if Engine.is_editor_hint():
		return

	var button_pressed = false

	# we check all trackers
	for i in ARVRServer.get_tracker_count():
		var tracker : ARVRPositionalTracker = ARVRServer.get_tracker(i)
		if tracker.get_hand() != 0:
			var joy_id = tracker.get_joy_id()

			if Input.is_joy_button_pressed(joy_id, activate_button):
				button_pressed = true

	if button_pressed:
		_set_time_held(time_held + delta)
		if time_held > hold_time:
			# done, disable this
			set_enabled(false)
			emit_signal("pressed")
	else:
		_set_time_held(max(0.0, time_held - delta))


func set_enabled(p_enabled: bool):
	enabled = p_enabled
	_update_enabled()


func _update_enabled():
	if is_inside_tree() and !Engine.is_editor_hint():
		_set_time_held(0.0)
		set_process(enabled)


func _set_time_held(p_time_held):
	time_held = p_time_held
	if material:
		$Visualise.visible = time_held > 0.0
		material.set_shader_param("value", time_held/hold_time)


func set_size(p_size: Vector2):
	size = p_size
	_update_size()


func _update_size():
	if material: # Note, material won't be set until after we setup our scene
		var mesh : QuadMesh = $Visualise.mesh
		if mesh.size != size:
			mesh.size = size

			# updating the size will unset our material, so reset it
			$Visualise.set_surface_material(0, material)


func set_color(p_color: Color):
	color = p_color
	_update_color()


func _update_color():
	if material:
		material.set_shader_param("albedo", color)
