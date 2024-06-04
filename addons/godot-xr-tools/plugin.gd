@tool
extends EditorPlugin


## Menu ID for enabling OpenXR
const MENU_ID_ENABLE_OPENXR := 1001

## Menu ID for setting the physics layers
const MENU_ID_SET_PHYSICS_LAYERS := 1002


# XR Tools popup menu
var _xr_tools_menu : PopupMenu


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
	if ProjectSettings.has_method("set_as_basic"):
		ProjectSettings.call("set_as_basic", p_name, true)
	ProjectSettings.set_initial_value(p_name, p_default_val)


func _enable_openxr() -> void:
	ProjectSettings.set("xr/openxr/enabled", true)
	ProjectSettings.set("xr/shaders/enabled", true)
	ProjectSettings.save()


func _set_physics_layers() -> void:
	ProjectSettings.set("layer_names/3d_physics/layer_1", "Static World")
	ProjectSettings.set("layer_names/3d_physics/layer_2", "Dynamic World")
	ProjectSettings.set("layer_names/3d_physics/layer_3", "Pickable Objects")
	ProjectSettings.set("layer_names/3d_physics/layer_4", "Wall Walking")
	ProjectSettings.set("layer_names/3d_physics/layer_5", "Grappling Target")
	ProjectSettings.set("layer_names/3d_physics/layer_17", "Held Objects")
	ProjectSettings.set("layer_names/3d_physics/layer_18", "Player Hands")
	ProjectSettings.set("layer_names/3d_physics/layer_19", "Grab Handles")
	ProjectSettings.set("layer_names/3d_physics/layer_20", "Player Body")
	ProjectSettings.set("layer_names/3d_physics/layer_21", "Pointable Objects")
	ProjectSettings.set("layer_names/3d_physics/layer_22", "Hand Pose Areas")
	ProjectSettings.set("layer_names/3d_physics/layer_23", "UI Objects")
	ProjectSettings.save()


func _on_xr_tools_menu_pressed(id : int) -> void:
	match id:
		MENU_ID_ENABLE_OPENXR:
			_enable_openxr()
			return

		MENU_ID_SET_PHYSICS_LAYERS:
			_set_physics_layers()
			return


func _enter_tree():
	# Construct the popup menu
	_xr_tools_menu = PopupMenu.new()
	_xr_tools_menu.name = "XR Tools"
	_xr_tools_menu.id_pressed.connect(_on_xr_tools_menu_pressed)
	add_tool_submenu_item("XR Tools", _xr_tools_menu)

	# Add tool menu items
	_xr_tools_menu.add_item("Enable OpenXR", MENU_ID_ENABLE_OPENXR)
	_xr_tools_menu.add_item("Set Physics Layers", MENU_ID_SET_PHYSICS_LAYERS)

	# Add input grip threshold to the project settings
	_define_project_setting(
			"godot_xr_tools/input/grip_threshold",
			TYPE_FLOAT,
			PROPERTY_HINT_RANGE,
			"0.2,0.8,0.05",
			0.7)

	# Add input haptics_scale to the project settings
	_define_project_setting(
			"godot_xr_tools/input/haptics_scale",
			TYPE_FLOAT,
			PROPERTY_HINT_RANGE,
			"0.0,1.0,0.1",
			1.0)

	# Add input y_axis_dead_zone to the project settings
	_define_project_setting(
			"godot_xr_tools/input/y_axis_dead_zone",
			TYPE_FLOAT,
			PROPERTY_HINT_RANGE,
			"0.0,0.5,0.01",
			0.1)

	# Add input x_axis_dead_zone to the project settings
	_define_project_setting(
			"godot_xr_tools/input/x_axis_dead_zone",
			TYPE_FLOAT,
			PROPERTY_HINT_RANGE,
			"0.0,0.5,0.01",
			0.2)

	# Add input snap turning dead-zone to the project settings
	_define_project_setting(
			"godot_xr_tools/input/snap_turning_deadzone",
			TYPE_FLOAT,
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
			TYPE_FLOAT,
			PROPERTY_HINT_RANGE,
			"1.0,2.5,0.05",
			1.85)

	# Register our autoload user settings object
	add_autoload_singleton(
			"XRToolsUserSettings",
			"res://addons/godot-xr-tools/user_settings/user_settings.gd")
	add_autoload_singleton(
			"XRToolsRumbleManager",
			"res://addons/godot-xr-tools/rumble/rumble_manager.gd")


func _exit_tree():
	# our plugin is turned off
	pass
