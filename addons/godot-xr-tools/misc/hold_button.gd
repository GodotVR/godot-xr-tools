tool
extends Spatial

class_name XRToolsHoldButton

signal pressed

# Enable our button
export (bool) var enabled = false setget set_enabled

func set_enabled(p_enabled):
	enabled = p_enabled
	_update_enabled()

func _update_enabled():
	if is_inside_tree() and !Engine.is_editor_hint():
		_set_time_held(0.0)
		set_process(enabled)

# Button

enum Buttons {
	VR_BUTTON_BY = 1,
	VR_GRIP = 2,
	VR_BUTTON_3 = 3,
	VR_BUTTON_4 = 4,
	VR_BUTTON_5 = 5,
	VR_BUTTON_6 = 6,
	VR_BUTTON_AX = 7,
	VR_BUTTON_8 = 8,
	VR_BUTTON_9 = 9,
	VR_BUTTON_10 = 10,
	VR_BUTTON_11 = 11,
	VR_BUTTON_12 = 12,
	VR_BUTTON_13 = 13,
	VR_PAD = 14,
	VR_TRIGGER = 15
}

export (Buttons) var activate_button: int = Buttons.VR_TRIGGER

# Countdown

export (float) var hold_time = 2.0
var time_held = 0.0

func _set_time_held(p_time_held):
	time_held = p_time_held
	if material:
		$Visualise.visible = time_held > 0.0
		material.set_shader_param("value", time_held/hold_time)

# Size

export (Vector2) var size = Vector2(1.0, 1.0) setget set_size

func set_size(p_size):
	size = p_size
	_update_size()

func _update_size():
	if material: # Note, material won't be set until after we setup our scene
		var mesh : QuadMesh = $Visualise.mesh
		if mesh.size != size:
			mesh.size = size
		
			# updating the size will unset our material, so reset it
			$Visualise.set_surface_material(0, material)

# Color our our visualisation
export (Color) var color = Color(1.0, 1.0, 1.0, 1.0) setget set_color

var material : ShaderMaterial

func set_color(p_color):
	color = p_color
	_update_color()

func _update_color():
	if material:
		material.set_shader_param("albedo", color)

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
	
