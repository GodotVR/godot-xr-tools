tool
extends EditorPlugin


func _define_project_setting(
		p_name : String,
		p_type : int,
		p_hint : int = PROPERTY_HINT_NONE,
		p_hint_string : String = "",
		p_default_val = "") -> void:
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

	# Add input grip threshold to the project settings
	_define_project_setting(
			"godot_xr_tools/input/grip_threshold",
			TYPE_REAL,
			PROPERTY_HINT_RANGE,
			"0.2,0.8,0.05",
			0.7)

	# Add input snap turning dead-zone to the project settings
	_define_project_setting(
			"godot_xr_tools/input/snap_turning_deadzone",
			TYPE_REAL,
			PROPERTY_HINT_RANGE,
			"0.0,0.5,0.05",
			0.25)

	# Add input default snap turning to the project settings
	_define_project_setting(
			"godot_xr_tools/input/default_snap_turning",
			TYPE_BOOL,
			PROPERTY_HINT_NONE,
			"",
			true)

	# Add player standard height to the project settings
	_define_project_setting(
			"godot_xr_tools/player/standard_height",
			TYPE_REAL,
			PROPERTY_HINT_RANGE,
			"1.0,2.5,0.05",
			1.85)

	# Register our autoload user settings object
	add_autoload_singleton(
			"XRToolsUserSettings",
			"res://addons/godot-xr-tools/user_settings/user_settings.gd")


func _exit_tree():
	# our plugin is turned off
	pass
