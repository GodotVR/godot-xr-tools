tool
class_name XRToolsMovementFootstep
extends XRToolsMovementProvider


## XRTools Movement Foot Step Player
##
## This movement provider detects walking on different surfaces, and plays audio
## sounds associated with walking on the surfaces.


# Some value indicating the player wants to walk at a moderate speed
const WALK_SOUND_THRESHOLD := 0.3

# Number of audio players to pool
const AUDIO_POOL_SIZE := 3


## Movement provider order
export var order : int = 1001

## Audio dB
export(float, -80.0, 80.0) var audio_db : float = 0.0

## Audio dB
export(float, -24.0, 6.0) var audio_max_db : float = 3.0

## Audio size
export(float, 0.1, 100.0) var audio_size : float = 3.0

## Audio max distance
export(float, 0.0, 4096.0) var audio_distance : float = 10.0


# step time and rate
var step_rate = 0.5
var step_time = 0.0

# Last on_ground state of the player
var _old_on_ground := true

# Node representing the location of the players foot
var _foot_spatial : Spatial

# Pool of idle AudioStreamPlayer3D nodes
var _audio_pool_idle : Array

# Last ground node
var _ground_node : Node

# Surface audio type associated with last ground node
var _ground_node_audio_type : XRToolsSurfaceAudioType


## PlayerBody - Player Physics Body Script
onready var player_body := XRToolsPlayerBody.find_instance(self)


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementFootstep" or .is_class(name)


func _ready():
	# Construct the foot spatial - we will move it around as the player moves.
	_foot_spatial = Spatial.new()
	_foot_spatial.name = "FootSpatial"
	add_child(_foot_spatial)

	# Construct the pool of audio players
	for i in AUDIO_POOL_SIZE:
		var player := AudioStreamPlayer3D.new()
		player.name = "AudioPlayer%d" % (i + 1)
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_SQUARE_DISTANCE
		player.unit_db = audio_db
		player.unit_size = audio_size
		player.max_db = audio_max_db
		player.max_distance = audio_distance
		player.connect("finished", self, "_on_player_finished", [ player ])
		_foot_spatial.add_child(player)
		_audio_pool_idle.append(player)

	# Set as always active
	is_active = true

	# Listen for the player jumping
	player_body.connect("player_jumped", self, "_on_player_jumped")


func physics_movement(_delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Update the spatial location of the foot
	_update_foot_spatial()
	
	# Update the ground audio information
	_update_ground_audio()
	
	# Detect landing on ground
	if not _old_on_ground and player_body.on_ground:
		# Play the ground hit sound
		_play_ground_hit()

	# Update the old on_ground state
	_old_on_ground = player_body.on_ground
	if not player_body.on_ground:
		step_time = 0
		return
	
	# Count down the step timer, and skip if silenced
	step_time = max(0, step_time - _delta)
	if step_time > 0:
		return

	# Play walking sounds if the player is trying to walk
	if player_body.ground_control_velocity.length() > WALK_SOUND_THRESHOLD:
		# Play the step sound and set the step delay timer
		_play_step_sound()
		step_time = step_rate


# Called when the player jumps
func _on_player_jumped() -> void:
	# Play the hit sound for whatever ground the player was standing on
	_play_ground_hit()


# Update ther foot spatial to be where the players foot is
func _update_foot_spatial() -> void:
	# Project the players camera down to the XZ plane (real-world space)
	var local_foot := Plane.PLANE_XZ.project(player_body.camera_node.translation)

	# Move the foot_spatial to the local foot in the global origin space
	_foot_spatial.global_translation = player_body.origin_node.global_transform.xform(local_foot)


# Update the ground audio information
func _update_ground_audio() -> void:
	# Skip if no change
	if player_body.ground_node == _ground_node:
		return

	# Save the new ground node
	_ground_node = player_body.ground_node

	# Handle no ground
	if not _ground_node:
		_ground_node_audio_type = null
		return

	# Find the surface audio for the ground (if any)
	var ground_audio : XRToolsSurfaceAudio = XRTools.find_child(
			_ground_node,
			"*", 
			"XRToolsSurfaceAudio")
	if ground_audio:
		_ground_node_audio_type = ground_audio.surface_audio_type
	else:
		_ground_node_audio_type = null


# Play the hit sound made when the player lands on the ground
func _play_ground_hit() -> void:
	# Skip if no ground audio
	if not _ground_node_audio_type:
		return

	# Get an idle audio player
	var player := _get_idle_audio_player()
	if not player:
		return

	# Play the hit sound
	player.stream = _ground_node_audio_type.hit_sound
	player.pitch_scale = 1.0
	player.play()


# Play a step sound for the current ground
func _play_step_sound() -> void:
	# Skip if no ground audio
	if not _ground_node_audio_type:
		return

	# Get an idle audio player
	var player := _get_idle_audio_player()
	if not player:
		return

	# Pick the sound index
	var idx := randi() % _ground_node_audio_type.walk_sounds.size()

	# Pick the playback pitck
	var pitch := rand_range(
			_ground_node_audio_type.walk_pitch_minimum,
			_ground_node_audio_type.walk_pitch_maximum)

	# Play the walk sound
	player.stream = _ground_node_audio_type.walk_sounds[idx]
	player.pitch_scale = pitch
	player.play()


# Called to get an idle AudioStreamPlayer3D to play a sound
func _get_idle_audio_player() -> AudioStreamPlayer3D:
	# Return the next idle player
	if _audio_pool_idle.size() > 0:
		return _audio_pool_idle.pop_front()

	# No players available
	push_warning("XRToolsMovementFootstep idle audio pool empty")
	return null


# Called when an AudioStreamPlayer3D in our pool finishes playing its sound
func _on_player_finished(player : AudioStreamPlayer3D) -> void:
	_audio_pool_idle.append(player)


## Find an [XRToolsMovementFootstep] node.
##
## This function searches from the specified node for an [XRToolsMovementFootstep]
## assuming the node is a sibling of the body under an [ARVROrigin].
static func find_instance(node: Node) -> XRToolsMovementFootstep:
	return XRTools.find_child(
		ARVRHelpers.get_arvr_origin(node),
		"*",
		"XRToolsMovementFootstep") as XRToolsMovementFootstep
