extends Node


## User setting for snap-turn
export var snap_turning : bool = true

## User setting for player height adjust
export var player_height_adjust : float = 0.0 setget set_player_height_adjust


## Settings file name to persist user settings
var settings_file_name : String = "user://xtools_user_settings.json"


# Called when the node enters the scene tree for the first time.
func _ready():
	_load()


## Reset to default values
func reset_to_defaults() -> void:
	# Reset to defaults
	snap_turning = XRTools.get_default_snap_turning()
	player_height_adjust = 0.0


## Set the player height adjust property
func set_player_height_adjust(new_value : float) -> void:
	player_height_adjust = clamp(new_value, -1.0, 1.0)


## Save the settings to file
func save() -> void:
	# Convert the settings to a dictionary
	var settings := {
		"input" : {
			"default_snap_turning" : snap_turning
		},
		"player" : {
			"height_adjust" : player_height_adjust
		}
	}

	# Convert the settings dictionary to text
	var settings_text := to_json(settings)

	# Attempt to open the settings file for writing
	var file := File.new()
	if file.open(settings_file_name, File.WRITE) != OK:
		return

	# Write the settings text to the file
	file.store_line(settings_text)
	file.close()


## Load the settings from file
func _load() -> void:
	# First reset our values
	reset_to_defaults()

	# Skip if no settings file found
	var file := File.new()
	if !file.file_exists(settings_file_name):
		return

	# Attempt to open the settings file for reading
	if file.open(settings_file_name, File.READ) != OK:
		# File open failed with an error
		return

	# Read the settings text
	var settings_text := file.get_as_text()
	file.close()

	# Parse the settings text and verify it's a dictionary
	var settings_raw = parse_json(settings_text)
	if typeof(settings_raw) != TYPE_DICTIONARY:
		return

	# Parse our input settings
	var settings : Dictionary = settings_raw
	if settings.has("input"):
		var input : Dictionary = settings["input"]
		if input.has("default_snap_turning"):
			snap_turning = input["default_snap_turning"]

	# Parse our player settings
	if settings.has("player"):
		var player : Dictionary = settings["player"]
		if player.has("height_adjust"):
			player_height_adjust = player["height_adjust"]
