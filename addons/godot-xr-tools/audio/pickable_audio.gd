@tool
@icon("res://addons/godot-xr-tools/editor/icons/audio.svg")
class_name XRToolsPickableAudio
extends Node


## XRTools Pickable Afx
##
## This node is attached as a child of a Pickable,
## it plays audio for drop and hit based on velocity,
## along with a audio for when the object is being picked up.


## XRToolsPickableAfxType to associate with this pickable
@export var pickable_audio_type  : XRToolsPickableAudioType

@onready var pickable : XRToolsPickable = get_parent()
@export var player : AudioStreamPlayer3D
## delta throttle is 1/10 of delta
@onready var delta_throttle : float = 0.1


# Add support for is_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickableAudio"


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# Listen for when this object enters a body
	pickable.body_entered.connect(_on_body_entered)
	# Listen for when this object is picked up or dropped
	pickable.picked_up.connect(_on_picked_up)
	pickable.dropped.connect(_on_dropped)


func _physics_process(delta):
	if !pickable.sleeping:
		if pickable.linear_velocity.length() > 5:
			player.volume_db = 0
		else:
			player.volume_db -= pickable.linear_velocity.length() * delta_throttle


# Called when this object is picked up
func _on_picked_up(pickable) -> void:
	player.volume_db = 0
	if player.playing:
		player.stop()
	player.stream = pickable_audio_type.grab_sound
	player.play()


# Called when this object is dropped
func _on_dropped(pickable) -> void:
	for body in pickable.get_colliding_bodies():
		if player.playing:
			player.stop()


func _on_body_entered(body):
	if player.playing:
			player.stop()
	if pickable.is_picked_up():
		player.stream = pickable_audio_type.hit_sound
	else:
		player.stream = pickable_audio_type.drop_sound
	player.play()


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if !pickable_audio_type:
		warnings.append("Pickable audio type not specified")

	# Return warnings
	return warnings
