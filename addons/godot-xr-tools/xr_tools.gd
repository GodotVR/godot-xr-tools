class_name XRTools
extends Node

# This class contains global definitions for our XRTools library

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
	VR_TRIGGER = 15,
	VR_ACTION = 255 ## Only supported in function pointer, should solve that differently!!
}


static func get_grip_threshold() -> float:
	# can return null which is not a float, so don't type this!
	var threshold = 0.7

	if ProjectSettings.has_setting("godot_xr_tools/input/grip_threshold"):
		threshold = ProjectSettings.get_setting("godot_xr_tools/input/grip_threshold")

	if !(threshold >= 0.2 and threshold <= 0.8):
		# out of bounds? reset to default
		threshold = 0.7

	return threshold

static func set_grip_threshold(p_threshold : float) -> void:
	if !(p_threshold >= 0.2 and p_threshold <= 0.8):
		print("Threshold out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/grip_threshold", p_threshold)


static func get_snap_turning_deadzone() -> float:
	# can return null which is not a float, so don't type this!
	var deadzone = 0.25
	
	if ProjectSettings.has_setting("godot_xr_tools/input/snap_turning_deadzone"):
		deadzone = ProjectSettings.get_setting("godot_xr_tools/input/snap_turning_deadzone")

	if !(deadzone >= 0.0 and deadzone <= 0.5):
		# out of bounds? reset to default
		deadzone = 0.25

	return deadzone

static func set_snap_turning_deadzone(p_deadzone : float) -> void:
	if !(p_deadzone >= 0.0 and p_deadzone <= 0.5):
		print("Deadzone out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/input/snap_turning_deadzone", p_deadzone)


static func get_default_snap_turning() -> bool:
	var default = true
	
	if ProjectSettings.has_setting("godot_xr_tools/input/default_snap_turning"):
		default = ProjectSettings.get_setting("godot_xr_tools/input/default_snap_turning")

	# default may not be bool, so JIC
	return default == true

static func set_default_snap_turning(p_default : bool) -> void:
	ProjectSettings.set_setting("godot_xr_tools/input/default_snap_turning", p_default)


static func get_player_standard_height() -> float:
	var standard_height = 1.85
	
	if ProjectSettings.has_setting("godot_xr_tools/player/standard_height"):
		standard_height = ProjectSettings.get_setting("godot_xr_tools/player/standard_height")

	if !(standard_height >= 1.0 and standard_height <= 2.5):
		# out of bounds? reset to default
		standard_height = 1.85

	return standard_height

static func set_player_standard_height(p_height : float) -> void:
	if !(p_height >= 1.0 and p_height <= 2.5):
		print("Standard height out of bounds")
		return

	ProjectSettings.set_setting("godot_xr_tools/player/standard_height", p_height)
