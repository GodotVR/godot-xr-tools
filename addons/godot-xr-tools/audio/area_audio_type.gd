@tool
@icon("res://addons/godot-xr-tools/editor/icons/audio.svg")
class_name XRToolsAreaAudioType
extends Resource


## XRTools Area Audio Type Resource
##
## This resource defines the audio stream to play when
## a objects enters it


## Surface name
@export var name : String = ""

## Optional audio stream to play when the player lands on this surface
@export var touch_sound : AudioStream


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if name == "":
		warnings.append("Area audio type must have a name")

	# Return warnings
	return warnings
