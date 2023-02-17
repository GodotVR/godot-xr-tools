tool
class_name XRToolsSurfaceAudio, "res://addons/godot-xr-tools/editor/icons/foot.svg"
extends Node


## XRTools Surface Audio Node
##
## This node is attached as a child of a StaticObject to give it a surface
## audio type. This will cause the XRToolsMovementFootStep to play the correct
## foot-step sounds when walking on the object.


## XRToolsSurfaceAudioType to associate with this surface
export var surface_audio_type : Resource


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsSurfaceAudio" or .is_class(name)


# This method checks for configuration issues.
func _get_configuration_warning():
	# Verify the camera
	if !surface_audio_type:
		return "Surface audio type not specified"

	# Verify hit sound
	if !surface_audio_type is XRToolsSurfaceAudioType:
		return "Surface audio type is not an XRToolsSurfaceAudioType"

	# No configuration issues detected
	return ""
