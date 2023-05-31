@tool
@icon("res://addons/godot-xr-tools/editor/icons/audio.svg")
class_name XRToolsAreaAudio
extends AudioStreamPlayer3D


## XRTools Area Audio
##
## This node is attached as a child of a Area3D,
## since all the interactables are actualy Extensions of the Area3D,
## this node will work on those as well


## XRToolsAreaAudioType to associate with this Area Audio
@export var area_audio_type : XRToolsAreaAudioType

@onready var area : Area3D = get_parent()


# Add support for is_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsAreaAudio"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for enter
	area.body_entered.connect(_on_body_entered)
	# Listen for exit
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(_body):
	if playing:
		stop()
	stream = area_audio_type.touch_sound
	play()


func _on_body_exited(_body):
	if playing:
			stop()


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if !area_audio_type:
		warnings.append("Area audio type not specified")

	# Return warnings
	return warnings
