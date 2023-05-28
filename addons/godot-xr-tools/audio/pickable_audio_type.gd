@tool
@icon("res://addons/godot-xr-tools/editor/icons/audio.svg")
class_name XRToolsPickableAudioType
extends Resource


## XRTools Pickable Audio Type Resource
##
## This resource defines the audio streams to play when
## the pickable is being picked up/ dropped/ hit something while being held


## Surface name
@export var name : String = ""

## Optional audio stream to play when the player picks up the pickable
@export var grab_sound : AudioStream

## Optional audio stream to play when the player drops the pickable
@export var drop_sound : AudioStream

## Optional audio stream to play when the item is beign held by the player
@export var hit_sound : AudioStream


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if name == "":
		warnings.append("Pickable audio type must have a name")

	# Return warnings
	return warnings
