extends Node


## Emitted when the WebXR primary is changed (either by the user or auto detected).
signal webxr_primary_changed (value)


enum WebXRPrimary {
	AUTO,
	THUMBSTICK,
	TRACKPAD,
}


@export_group("Input")

## User setting for snap-turn
@export var snap_turning : bool = true

## User setting for y axis dead zone
@export var y_axis_dead_zone : float = 0.1

## User setting for y axis dead zone
@export var x_axis_dead_zone : float = 0.2

## Used to control rumble like volume
@export_range(0.0, 1.0, 0.05) var haptics_scale := 1.0

@export_group("Player")

## User setting for player height
@export var player_height : float = 1.85: set = set_player_height

@export_group("WebXR")

## User setting for WebXR primary
@export var webxr_primary : WebXRPrimary = WebXRPrimary.AUTO: set = set_webxr_primary


## Settings file name to persist user settings
var settings_file_name : String = "user://xtools_user_settings.json"

## Records the first input to generate input (thumbstick or trackpad).
var webxr_auto_primary := 0


# Called when the node enters the scene tree for the first time.
func _ready():
	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRServer.tracker_added.connect(self._on_webxr_tracker_added)

	_load()


## Reset to default values
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

## Set the player height property
func set_player_height(new_value : float) -> void:
	player_height = clamp(new_value, 1.0, 2.5)

## Set the WebXR primary
func set_webxr_primary(new_value : WebXRPrimary) -> void:
	webxr_primary = new_value
	if webxr_primary == WebXRPrimary.AUTO:
		if webxr_auto_primary == 0:
			# Don't emit the signal yet, wait until we detect which to use.
			pass
		else:
			webxr_primary_changed.emit(webxr_auto_primary)
	else:
		webxr_primary_changed.emit(webxr_primary)


## Gets the WebXR primary (taking into account auto detection).
func get_real_webxr_primary() -> WebXRPrimary:
	if webxr_primary == WebXRPrimary.AUTO:
		return webxr_auto_primary
	return webxr_primary


## Save the settings to file
func save() -> void:
	# Convert the settings to a dictionary
	var settings := {
		"input" : {
			"default_snap_turning" : snap_turning,
			"y_axis_dead_zone" : y_axis_dead_zone,
			"x_axis_dead_zone" : x_axis_dead_zone,
			"haptics_scale": haptics_scale
		},
		"player" : {
			"height" : player_height
		},
		"webxr" : {
			"webxr_primary" : webxr_primary,
		}
	}

	# Convert the settings dictionary to text
	var settings_text := JSON.stringify(settings)

	# Attempt to open the settings file for writing
	var file := FileAccess.open(settings_file_name, FileAccess.WRITE)
	if not file:
		push_warning("Unable to write to %s" % settings_file_name)
		return

	# Write the settings text to the file
	file.store_line(settings_text)
	file.close()


## Get the action associated with a WebXR primary choice
static func get_webxr_primary_action(primary : WebXRPrimary) -> String:
	match primary:
		WebXRPrimary.THUMBSTICK:
			return "thumbstick"

		WebXRPrimary.TRACKPAD:
			return "trackpad"

		_:
			return "auto"


## Load the settings from file
func _load() -> void:
	# First reset our values
	reset_to_defaults()

	# Skip if no settings file found
	if !FileAccess.file_exists(settings_file_name):
		return

	# Attempt to open the settings file for reading
	var file := FileAccess.open(settings_file_name, FileAccess.READ)
	if not file:
		push_warning("Unable to read from %s" % settings_file_name)
		return

	# Read the settings text
	var settings_text := file.get_as_text()
	file.close()

	# Parse the settings text and verify it's a dictionary
	var settings_raw = JSON.parse_string(settings_text)
	if typeof(settings_raw) != TYPE_DICTIONARY:
		push_warning("Settings file %s is corrupt" % settings_file_name)
		return

	# Parse our input settings
	var settings : Dictionary = settings_raw
	if settings.has("input"):
		var input : Dictionary = settings["input"]
		if input.has("default_snap_turning"):
			snap_turning = input["default_snap_turning"]
		if input.has("y_axis_dead_zone"):
			y_axis_dead_zone = input["y_axis_dead_zone"]
		if input.has("x_axis_dead_zone"):
			x_axis_dead_zone = input["x_axis_dead_zone"]
		if input.has("haptics_scale"):
			haptics_scale = input["haptics_scale"]

	# Parse our player settings
	if settings.has("player"):
		var player : Dictionary = settings["player"]
		if player.has("height"):
			player_height = player["height"]

	# Parse our WebXR settings
	if settings.has("webxr"):
		var webxr : Dictionary = settings["webxr"]
		if webxr.has("webxr_primary"):
			webxr_primary = webxr["webxr_primary"]


## Used to connect to tracker events when using WebXR.
func _on_webxr_tracker_added(tracker_name: StringName, _type: int) -> void:
	if tracker_name == &"left_hand" or tracker_name == &"right_hand":
		var tracker := XRServer.get_tracker(tracker_name)
		tracker.input_vector2_changed.connect(self._on_webxr_vector2_changed)


## Used to auto detect which "primary" input gets used first.
func _on_webxr_vector2_changed(name: String, _vector: Vector2) -> void:
	if webxr_auto_primary == 0:
		if name == "thumbstick":
			webxr_auto_primary = WebXRPrimary.THUMBSTICK
		elif name == "trackpad":
			webxr_auto_primary = WebXRPrimary.TRACKPAD

		if webxr_auto_primary != 0:
			# Let the developer know which one is chosen.
			webxr_primary_changed.emit(webxr_auto_primary)

## Helper function to remap input vector with deadzone values
func get_adjusted_vector2(p_controller, p_input_action):
	var vector = Vector2.ZERO
	var original_vector = p_controller.get_vector2(p_input_action)

	if abs(original_vector.y) > y_axis_dead_zone:
		vector.y = remap(abs(original_vector.y), y_axis_dead_zone, 1, 0, 1)
		if original_vector.y < 0:
			vector.y *= -1

	if abs(original_vector.x) > x_axis_dead_zone:
		vector.x = remap(abs(original_vector.x), x_axis_dead_zone, 1, 0, 1)
		if original_vector.x < 0:
			vector.x *= -1

	return vector

