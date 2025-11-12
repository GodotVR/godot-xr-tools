@tool
@icon("res://addons/godot-xr-tools/editor/icons/foot.svg")
class_name XRToolsSurfaceAudio
extends Node


## XRTools Surface Audio Node
##
## This node is attached as a child of a StaticObject to give it a surface
## audio type. This will cause the XRToolsMovementFootStep to play the correct
## foot-step sounds when walking on the object.


## XRToolsSurfaceAudioType to associate with this surface
@export var surface_audio_type : XRToolsSurfaceAudioType


# Add support for is_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsSurfaceAudio"


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify the camera
	if !surface_audio_type:
		warnings.append("Surface audio type not specified")

	# Return warnings
	return warnings
