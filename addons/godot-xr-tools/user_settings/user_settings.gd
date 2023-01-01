extends Node

enum WebXRPrimary {
	AUTO,
	THUMBSTICK,
	TRACKPAD,
}

const WebXRPrimaryName := {
	WebXRPrimary.AUTO: "auto",
	WebXRPrimary.THUMBSTICK: "thumbstick",
	WebXRPrimary.TRACKPAD: "trackpad",
}

## User setting for snap-turn
@export var snap_turning : bool = true

## User setting for player height adjust
@export var player_height_adjust : float = 0.0: set = set_player_height_adjust

## User setting for WebXR primary
@export_enum(WebXRPrimary) var webxr_primary : int = WebXRPrimary.AUTO: set = set_webxr_primary

## Settings file name to persist user settings
var settings_file_name : String = "user://xtools_user_settings.json"

## Records the first input to generate input (thumbstick or trackpad).
var webxr_auto_primary := 0


## Emitted when the WebXR primary is changed (either by the user or auto detected).
signal webxr_primary_changed (value)


# Called when the node enters the scene tree for the first time.
func _ready():
	var webxr_interface = XRServer.find_interface("WebXR")
	if webxr_interface:
		XRServer.tracker_added.connect(self._on_webxr_tracker_added)

	_load()


## Reset to default values
func reset_to_defaults() -> void:
	# Reset to defaults
	snap_turning = XRTools.get_default_snap_turning()
	player_height_adjust = 0.0
	webxr_primary = WebXRPrimary.AUTO
	webxr_auto_primary = 0


## Set the player height adjust property
func set_player_height_adjust(new_value : float) -> void:
	player_height_adjust = clamp(new_value, -1.0, 1.0)


## Set the WebXR primary
func set_webxr_primary(new_value : int) -> void:
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
func get_real_webxr_primary() -> int:
	if webxr_primary == WebXRPrimary.AUTO:
		return webxr_auto_primary
	return webxr_primary


## Save the settings to file
func save() -> void:
	# Construct the settings dictionary
	var data = {
		"input" : {
			"default_snap_turning" : snap_turning,
		},
		"player" : {
			"height_adjust" : player_height_adjust
		},
		"webxr" : {
			"webxr_primary" : webxr_primary,
		}
	}

	# Save to file
	var file := FileAccess.open(settings_file_name, FileAccess.WRITE)
	if file:
		file.store_line(JSON.stringify(data))


## Load the settings from file
func _load() -> void:
	# First reset our values
	reset_to_defaults()

	# Now attempt to load our settings file
	if !FileAccess.file_exists(settings_file_name):
		return

	# Attempt to open the file
	var file := FileAccess.open(settings_file_name, FileAccess.READ)
	if not file:
		return

	# Read the file as text
	var text = file.get_as_text()

	# Parse the settings dictionary
	var data : Dictionary = JSON.parse_string(text)

	# Parse our input settings
	if data.has("input"):
		var input : Dictionary = data["input"]
		if input.has("default_snap_turning"):
			snap_turning = input["default_snap_turning"]

	# Parse our player settings
	if data.has("player"):
		var player : Dictionary = data["player"]
		if player.has("height_adjust"):
			player_height_adjust = player["height_adjust"]

	# Parse our WebXR settings
	if data.has("webxr"):
		var webxr : Dictionary = data["webxr"]
		if webxr.has("webxr_primary"):
			webxr_primary = webxr["webxr_primary"]


## Used to connect to tracker events when using WebXR.
func _on_webxr_tracker_added(tracker_name: StringName, type: int) -> void:
	if tracker_name == &"left_hand" or tracker_name == &"right_hand":
		var tracker := XRServer.get_tracker(tracker_name)
		tracker.input_axis_changed.connect(self._on_webxr_axis_changed)


## Used to auto detect which "primary" input gets used first.
func _on_webxr_axis_changed(name: String, vector: Vector2) -> void:
	if webxr_auto_primary == 0:
		if name == "thumbstick":
			webxr_auto_primary = WebXRPrimary.THUMBSTICK
		elif name == "trackpad":
			webxr_auto_primary = WebXRPrimary.TRACKPAD

		if webxr_auto_primary != 0:
			# Let the developer know which one is chosen.
			webxr_primary_changed.emit(webxr_auto_primary)
