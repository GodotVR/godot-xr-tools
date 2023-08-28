@tool
class_name XRToolsMovementFootstep
extends XRToolsMovementProvider


## XR Tools Movement Provider for Footsteps
##
## This movement provider detects walking on different surfaces.
## It plays audio sounds associated with the surface the player is
## currently walking on.


## Signal emitted when a footstep is generated
signal footstep(name)


# Number of audio players to pool
const AUDIO_POOL_SIZE := 3


## Movement provider order
@export var order : int = 1001

## Default XRToolsSurfaceAudioType when not overridden
@export var default_surface_audio_type : XRToolsSurfaceAudioType

## Speed at which the player is considered walking
@export var walk_speed := 0.4

## Step per meter by time
@export var steps_per_meter = 1.0


# step time
var step_time = 0.0

# Last on_ground state of the player
var _old_on_ground := true

# Node representing the location of the players foot
var _foot_spatial : Node3D

# Pool of idle AudioStreamPlayer3D nodes
var _audio_pool_idle : Array[AudioStreamPlayer3D]

# Last ground node
var _ground_node : Node

# Surface audio type associated with last ground node
var _ground_node_audio_type : XRToolsSurfaceAudioType


## PlayerBody - Player Physics Body Script
@onready var player_body := XRToolsPlayerBody.find_instance(self)


# Add support for is_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementFootstep" or super(name)


func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Construct the foot spatial - we will move it around as the player moves.
	_foot_spatial = Node3D.new()
	_foot_spatial.name = "FootSpatial"
	add_child(_foot_spatial)

	# Make the array of players in _audio_pool_idle
	for i in AUDIO_POOL_SIZE:
		var player = $PlayerSettings.duplicate()
		player.name = "PlayerCopy%d" % (i + 1)
		_foot_spatial.add_child(player)
		_audio_pool_idle.append(player)
		player.finished.connect(_on_player_finished.bind(player))

	# Set as always active
	is_active = true

	# Listen for the player jumping
	player_body.player_jumped.connect(_on_player_jumped)


# This method checks for configuration issues.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Verify player settings node exists
	if not $PlayerSettings:
		warnings.append("Missing player settings node")

	# Return warnings
	return warnings


func physics_movement(_delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Update the spatial location of the foot
	_update_foot_spatial()

	# Update the ground audio information
	_update_ground_audio()

	# Skip if footsteps have been disabled
	if not enabled:
		step_time = 0
		return

	# Detect landing on ground
	if not _old_on_ground and player_body.on_ground:
		# Play the ground hit sound
		_play_ground_hit()

	# Update the old on_ground state
	_old_on_ground = player_body.on_ground
	if not player_body.on_ground:
		step_time = 0 	# Reset when not on ground
		return

	# Handle slow/stopped
	if player_body.ground_control_velocity.length() < walk_speed:
		step_time = 0	# Reset when slow/stopped
		return

	# Count up the step timer, and skip if not take a step yet
	step_time += _delta * player_body.ground_control_velocity.length()
	if step_time > steps_per_meter:
		_play_step_sound()
		step_time = 0


# Update the foot spatial to be where the players foot is
func _update_foot_spatial() -> void:
	# Project the players camera down to the XZ plane (real-world space)
	var local_foot := player_body.camera_node.position.slide(Vector3.UP)

	# Move the foot_spatial to the local foot in the global origin space
	_foot_spatial.global_position = player_body.origin_node.global_transform * local_foot


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
	var ground_audio : XRToolsSurfaceAudio = XRTools.find_xr_child(
		_ground_node, "*", "XRToolsSurfaceAudio")
	if ground_audio:
		_ground_node_audio_type = ground_audio.surface_audio_type
	else:
		_ground_node_audio_type = default_surface_audio_type


# Called when the player jumps
func _on_player_jumped() -> void:
	# Skip if no jump sound
	if not _ground_node_audio_type:
		return

	# Play the jump sound
	_play_sound(
			_ground_node_audio_type.name,
			_ground_node_audio_type.jump_sound)


# Play the hit sound made when the player lands on the ground
func _play_ground_hit() -> void:
	# Skip if no hit sound
	if not _ground_node_audio_type:
		return

	# Play the hit sound
	_play_sound(
			_ground_node_audio_type.name,
			_ground_node_audio_type.hit_sound)


# Play a step sound for the current ground
func _play_step_sound() -> void:
	# Skip if no walk audio
	if not _ground_node_audio_type or _ground_node_audio_type.walk_sounds.size() == 0:
		return

	# Pick the sound index
	var idx := randi() % _ground_node_audio_type.walk_sounds.size()

	# Pick the playback pitck
	var pitch := randf_range(
			_ground_node_audio_type.walk_pitch_minimum,
			_ground_node_audio_type.walk_pitch_maximum)

	# Play the walk sound
	_play_sound(
			_ground_node_audio_type.name,
			_ground_node_audio_type.walk_sounds[idx],
			pitch)


# Play the specified audio stream at the requested pitch using an
# AudioStreamPlayer3D in the idle pool of players.
func _play_sound(name : String, stream : AudioStream, pitch : float = 1.0) -> void:
	# Skip if no stream provided
	if not stream:
		return

	# Emit the footstep signal
	footstep.emit(name)

	# Verify we have an audio player
	if _audio_pool_idle.size() == 0:
		push_warning("XRToolsMovementFootstep idle audio pool empty")
		return

	# Play the sound
	var player : AudioStreamPlayer3D = _audio_pool_idle.pop_front()
	player.stream = stream
	player.pitch_scale = pitch
	player.play()


# Called when an AudioStreamPlayer3D in our pool finishes playing its sound
func _on_player_finished(player : AudioStreamPlayer3D) -> void:
	_audio_pool_idle.append(player)


## Find an [XRToolsMovementFootstep] node.
##
## This function searches from the specified node for an [XRToolsMovementFootstep]
## assuming the node is a sibling of the body under an [ARVROrigin].
static func find_instance(node: Node) -> XRToolsMovementFootstep:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_origin(node),
		"*",
		"XRToolsMovementFootstep") as XRToolsMovementFootstep
