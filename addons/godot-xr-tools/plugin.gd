tool
extends EditorPlugin
class_name XRTools


# enum our axis
enum Axis {
	VR_PRIMARY_X_AXIS = 0,
	VR_PRIMARY_Y_AXIS = 1,
	VR_SECONDARY_X_AXIS = 6,
	VR_SECONDARY_Y_AXIS = 7,
	VR_TRIGGER_AXIS = 2,
	VR_GRIP_AXIS = 4
}


# enum our buttons
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


static func get_grip_threshold() -> float:
	# can return null which is not a float, so don't type this!
	var threshold = ProjectSettings.get_setting("godot_xr_tools/input/grip_threshold")

	if threshold == null:
		# plugin disabled or setting not saved, return our default.
		threshold = 0.7
	if !(threshold >= 0.2 and threshold <= 0.8):
		# out of bounds? reset to default
		threshold = 0.7
	
	return threshold

static func set_grip_threshold(p_threshold : float) -> void:
	if !(p_threshold >= 0.2 and p_threshold <= 0.8):
		print("Threshold out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/grip_threshold", p_threshold)

func _define_project_setting(p_name : String, p_type : int, p_hint : int = PROPERTY_HINT_NONE , p_hint_string : String = "", p_default_val = "") -> void:
	# p_default_val can be any type!!

	if !ProjectSettings.has_setting(p_name):
		ProjectSettings.set_setting(p_name, p_default_val)

	var property_info : Dictionary = {
		"name" : p_name,
		"type" : p_type,
		"hint" : p_hint,
		"hint_string" : p_hint_string
	}

	ProjectSettings.add_property_info(property_info)
	ProjectSettings.set_initial_value(p_name, p_default_val)


func _enter_tree():
	# our plugin is loaded

	# provide meta data for our project settings
	_define_project_setting("godot_xr_tools/input/grip_threshold", TYPE_REAL, PROPERTY_HINT_RANGE, "0.2,0.8,0.05", 0.7)


func _exit_tree():
	# our plugin is turned off
	pass
