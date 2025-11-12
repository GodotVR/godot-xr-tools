@tool
@icon("res://addons/godot-xr-tools/editor/icons/audio.svg")
class_name XRToolsPickableAudio
extends AudioStreamPlayer3D


## XRTools Pickable Audio
##
## This node is attached as a child of a Pickable,
## it plays audio for drop and hit based on velocity,
## along with a audio for when the object is being picked up.


## XRToolsPickableAudioType to associate with this pickable
@export var pickable_audio_type  : XRToolsPickableAudioType

## delta throttle is 1/10 of delta
@onready var delta_throttle : float = 0.1

@onready var _pickable : XRToolsPickable = get_parent()


# Add support for is_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsPickableAudio"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for when this object enters a body
	_pickable.body_entered.connect(_on_body_entered)
	# Listen for when this object is picked up or dropped
	_pickable.picked_up.connect(_on_picked_up)
	_pickable.dropped.connect(_on_dropped)


func _physics_process(_delta):
	if !_pickable.sleeping:
		if _pickable.linear_velocity.length() > 5:
			volume_db = 0
		else:
			volume_db -= _pickable.linear_velocity.length() * delta_throttle


# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	volume_db = 0
	if playing:
		stop()
	stream = pickable_audio_type.grab_sound
	play()


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	for body in _pickable.get_colliding_bodies():
		if playing:
			stop()


func _on_body_entered(_body):
	if playing:
			stop()
	if _pickable.is_picked_up():
		stream = pickable_audio_type.hit_sound
	else:
		stream = pickable_audio_type.drop_sound
	play()


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if !pickable_audio_type:
		warnings.append("Pickable audio type not specified")

	# Return warnings
	return warnings
