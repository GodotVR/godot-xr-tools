tool
class_name XRToolsSurfaceAudioType, "res://addons/godot-xr-tools/editor/icons/body.svg"
extends Resource


## XRTools Surface Type Resource
##
## This resource defines a type of surface, and the audio streams to play when
## the user steps on it


## Surface name
export var name : String = ""

## Optional audio stream to play when the player jumps on this surface
export var jump_sound : AudioStream

## Optional audio stream to play when the player lands on this surface
export var hit_sound : AudioStream

## Audio streams to play when the player walks on this surface
export(Array, AudioStream) var walk_sounds : Array = []

## Walking sound minimum pitch (to randomize steps)
export(float, 0.5, 1.0) var walk_pitch_minimum : float = 0.8

## Walking sound maximum pitch (to randomize steps)
export(float, 1.0, 2.0) var walk_pitch_maximum : float = 1.2


# This method checks for configuration issues.
func _get_configuration_warning():
	# Verify the name
	if name == "":
		return "Surface audio type must have a name"

	# No configuration issues detected
	return ""
