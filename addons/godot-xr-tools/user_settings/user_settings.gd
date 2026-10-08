extends Node

## Emitted when the WebXR primary is changed (either by the user or auto-detected).
signal webxr_primary_changed(value: WebXRPrimary)


enum WebXRPrimary {
	AUTO,
	THUMBSTICK,
	TRACKPAD,
}


@export_group("Input")

## Whether the user wants snap-turning instead of smooth turning
@export var snap_turning := true

## Y-axis deadzone for controller joysticks
@export var y_axis_dead_zone := 0.1

## X-axis deadzone for controller joysticks
@export var x_axis_dead_zone := 0.2

## Intensity of rumble (where 1.0 is the highest and 0.0 is none at all)
@export_range(0.0, 1.0, 0.05) var haptics_scale := 1.0

@export_group("Player")

## Player's height from the floor
@export var player_height := 1.85: set = set_player_height

@export_group("WebXR")

## User setting for WebXR primary
@export var webxr_primary := WebXRPrimary.AUTO: set = set_webxr_primary


## File name to persist user settings
var settings_file_name := "user://xr_tools_user_settings.cfg"

## Records the first input to generate input (thumbstick or trackpad).
var webxr_auto_primary := 0


# When the node enters the scene tree for the first time.
func _ready() -> void:
	var webxr_interface := XRServer.find_interface("WebXR")
	if webxr_interface:
		XRServer.tracker_added.connect(self._on_webxr_tracker_added)

	_load()


## Helps remap input vector with deadzone values
func get_adjusted_vector2(
		p_controller: XRController3D,
		p_input_action: String,
) -> Vector2:
	var vector := Vector2.ZERO
	var original_vector := p_controller.get_vector2(p_input_action)

	if abs(original_vector.y) > y_axis_dead_zone:
		vector.y = remap(abs(original_vector.y), y_axis_dead_zone, 1, 0, 1)
		if original_vector.y < 0:
			vector.y *= -1

	if abs(original_vector.x) > x_axis_dead_zone:
		vector.x = remap(abs(original_vector.x), x_axis_dead_zone, 1, 0, 1)
		if original_vector.x < 0:
			vector.x *= -1

	return vector


## Gets the WebXR primary (taking into account auto-detection).
func get_real_webxr_primary() -> WebXRPrimary:
	if webxr_primary == WebXRPrimary.AUTO:
		return webxr_auto_primary
	return webxr_primary


## Gets the action associated with a WebXR primary choice
func get_webxr_primary_action(primary: WebXRPrimary) -> String:
	match primary:
		WebXRPrimary.THUMBSTICK:
			return "thumbstick"

		WebXRPrimary.TRACKPAD:
			return "trackpad"

		_:
			return "auto"


## Resets settings to default values
func reset_to_defaults() -> void:
	# Reset to defaults.
	# Where applicable we obtain our project settings
	snap_turning = XRTools.get_default_snap_turning()
	y_axis_dead_zone = XRTools.get_y_axis_dead_zone()
	x_axis_dead_zone = XRTools.get_x_axis_dead_zone()
	player_height = XRTools.get_player_standard_height()
	webxr_primary = WebXRPrimary.AUTO
	webxr_auto_primary = 0
	haptics_scale = XRToolsRumbleManager.get_default_haptics_scale()


## Saves the settings to a .cfg file
func save() -> void:
	# Create a new Config File
	var config := ConfigFile.new()

	# Add the settings to the Config File
	config.set_value("input", "default_snap_turning", snap_turning)
	config.set_value("input", "x_axis_dead_zone", x_axis_dead_zone)
	config.set_value("input", "y_axis_dead_zone", y_axis_dead_zone)
	config.set_value("input", "haptics_scale", haptics_scale)

	config.set_value("player", "height", player_height)

	config.set_value("webxr", "primary", webxr_primary)

	# Save the Config File
	config.save(settings_file_name)


## Sets the player's height
func set_player_height(new_value: float) -> void:
	player_height = clampf(new_value, 1.0, 2.5)


## Sets the WebXR primary
func set_webxr_primary(new_value: WebXRPrimary) -> void:
	webxr_primary = new_value
	if webxr_primary == WebXRPrimary.AUTO:
		if webxr_auto_primary == 0:
			# Don't emit the signal yet, wait until we detect which to use.
			pass
		else:
			webxr_primary_changed.emit(webxr_auto_primary)
	else:
		webxr_primary_changed.emit(webxr_primary)


# Loads the settings from the Config File
func _load() -> void:
	# First reset our values
	reset_to_defaults()

	# Skip if no settings file found
	if not FileAccess.file_exists(settings_file_name):
		return

	# Attempt to open the settings file for reading
	var config := ConfigFile.new()
	var err = config.load(settings_file_name)

	if err != OK:
		push_warning("Unable to read from %s" % settings_file_name)
		return

	# Load the settings from the Config File
	snap_turning = config.get_value(
			"input",
			"default_snap_turning",
			XRTools.get_default_snap_turning(),
	)
	x_axis_dead_zone = config.get_value(
			"input",
			"x_axis_dead_zone",
			XRTools.get_x_axis_dead_zone(),
	)
	y_axis_dead_zone = config.get_value(
			"input",
			"y_axis_dead_zone",
			XRTools.get_y_axis_dead_zone(),
	)
	haptics_scale = config.get_value(
			"input",
			"haptics_scale",
			XRToolsRumbleManager.get_default_haptics_scale(),
	)

	player_height = config.get_value(
			"player",
			"height",
			XRTools.get_player_standard_height(),
	)

	webxr_primary = config.get_value("webxr", "primary", WebXRPrimary.AUTO)


# Connects to tracker events when using WebXR.
func _on_webxr_tracker_added(tracker_name: StringName, _type: int) -> void:
	if tracker_name == &"left_hand" or tracker_name == &"right_hand":
		var tracker := XRServer.get_tracker(tracker_name)
		tracker.input_vector2_changed.connect(self._on_webxr_vector2_changed)


# Auto-detects which "primary" input gets used first.
func _on_webxr_vector2_changed(name: String, _vector: Vector2) -> void:
	if webxr_auto_primary == 0:
		if name == "thumbstick":
			webxr_auto_primary = WebXRPrimary.THUMBSTICK
		elif name == "trackpad":
			webxr_auto_primary = WebXRPrimary.TRACKPAD

		if webxr_auto_primary != 0:
			# Let the developer know which one is chosen.
			webxr_primary_changed.emit(webxr_auto_primary)
