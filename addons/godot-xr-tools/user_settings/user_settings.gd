extends Node

# our settings
export var snap_turning : bool = true
export var player_height_adjust : float = 0.0 setget set_player_height_adjust

var settings_file_name = "user://xtools_user_settings.json"

func set_player_height_adjust(new_value : float) -> void:
	player_height_adjust = clamp(new_value, -1.0, 1.0)


func reset_to_defaults():
	# Reset to defaults
	snap_turning = XRTools.get_default_snap_turning()
	player_height_adjust = 0.0


func _load():
	# First reset our values
	reset_to_defaults()

	# Now attempt to load our settings file
	var file = File.new()
	if !file.file_exists(settings_file_name):
		return

	if file.open(settings_file_name, File.READ):
		var text = file.get_as_text()
		file.close()

		var data : Dictionary = parse_json(text)

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

func save():
	var data = {
		"input" : {
			"default_snap_turning" : snap_turning
		},
		"player" : {
			"height_adjust" : player_height_adjust
		}
	}

	var file = File.new()
	if file.open(settings_file_name, File.WRITE):
		file.store_line(to_json(data))
		file.close()

# Called when the node enters the scene tree for the first time.
func _ready():
	_load()
