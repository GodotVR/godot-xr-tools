tool
class_name PlayerBody
extends Node

##
## Player Physics Body Script
##
## @desc:
##     This script works with the PlayerBody asset to provide the player with
##     a PlayerBody. This PlayerBody is a capsule tracking the players hear
##     via the ARVRCamera node.
##
##     The PlayerBody can detect when the player is in the air, on the ground,
##     or on a steep slope.
##
##     The PlayerBody works with movement providers to allow the player to move
##     around the environment.
##
##     At the end of each physics process step the ARVROrigin is updated to
##     track any movement to the PlayerBody.
##


## Signal emitted when the player jumps
signal player_jumped()


# Horizontal vector (multiply by this to get only the horizontal components
const HORIZONTAL := Vector3(1.0, 0.0, 1.0)


## PlayerBody enabled flag
export var enabled := true setget set_enabled

## Player radius
export var player_radius := 0.4 setget set_player_radius

## Player head height (distance between between camera and top of head)
export var player_head_height := 0.1

## Minimum player height
export var player_height_min := 1.0

## Maximum player height
export var player_height_max := 2.2

## Eyes forward offset from center of body in player_radius units
export (float, 0.0, 1.0) var eye_forward_offset := 0.66

## Force of gravity on the player
export var gravity := -9.8

## Lets the player push rigid bodies
export var push_rigid_bodies := true

## GroundPhysicsSettings to apply - can only be typed in Godot 4+
export (Resource) var physics = null setget set_physics

# Set our collision layer
export (int, LAYERS_3D_PHYSICS) var collision_layer = 1 << 19 setget set_collision_layer

# Set our collision mask
export (int, LAYERS_3D_PHYSICS) var collision_mask = 1023 setget set_collision_mask


## Player Velocity - modifiable by MovementProvider nodes
var velocity := Vector3.ZERO

## Player On Ground flag - used by MovementProvider nodes
var on_ground := true

## Ground 'up' vector - used by MovementProvider nodes
var ground_vector := Vector3.UP

## Ground slope angle - used by MovementProvider nodes
var ground_angle := 0.0

## Ground node the player is touching
var ground_node: Spatial = null

## Ground physics override (if present)
var ground_physics: GroundPhysicsSettings = null

## Ground control velocity - modified by MovementProvider nodes
var ground_control_velocity := Vector2.ZERO

## Player height offset (for height calibration)
var player_height_offset := 0.0

## Velocity of the ground under the players feet
var ground_velocity := Vector3.ZERO


# Movement providers
var _movement_providers := Array()

# Jump cool-down counter
var _jump_cooldown := 0

## Player height overrides
var _player_height_overrides := { }

# Player height override (enabled when non-negative)
var _player_height_override := -1.0

# Previous ground node
var _previous_ground_node: Spatial = null

# Previous ground local position
var _previous_ground_local := Vector3.ZERO

# Previous ground global position
var _previous_ground_global := Vector3.ZERO


## ARVROrigin node
onready var origin_node := ARVRHelpers.get_arvr_origin(self)

## ARVRCamera node
onready var camera_node := ARVRHelpers.get_arvr_camera(self)

## Player KinematicBody node
onready var kinematic_node: KinematicBody = $KinematicBody

# Default physics (if not specified by the user or the current ground)
onready var default_physics = _guaranteed_physics()

# Collision node
onready var _collision_node: CollisionShape = $KinematicBody/CollisionShape


# Class to sort movement providers by order
class SortProviderByOrder:
	static func sort_by_order(a, b) -> bool:
		return true if a.order < b.order else false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the movement providers ordered by increasing order
	_movement_providers = get_tree().get_nodes_in_group("movement_providers")
	_movement_providers.sort_custom(SortProviderByOrder, "sort_by_order")

	# Propagate defaults
	_update_enabled()
	_update_player_radius()
	_update_collision_layer()
	_update_collision_mask()

func set_enabled(new_value):
	enabled = new_value
	if is_inside_tree():
		_update_enabled()

func _update_enabled() -> void:
	# Update collision_shape
	if _collision_node:
		_collision_node.disabled = !enabled

	# Update physics processing
	if enabled:
		set_physics_process(true)

func set_player_radius(new_value: float) -> void:
	player_radius = new_value
	if is_inside_tree():
		_update_player_radius()

func _update_player_radius() -> void:
	if _collision_node and _collision_node.shape:
		_collision_node.shape.radius = player_radius

func set_physics(new_value: Resource) -> void:
	# Save the property
	physics = new_value
	default_physics = _guaranteed_physics()

func set_collision_layer(new_layer: int) -> void:
	collision_layer = new_layer
	if is_inside_tree():
		_update_collision_layer()

func _update_collision_layer() -> void:
	if kinematic_node:
		kinematic_node.collision_layer = collision_layer

func set_collision_mask(new_mask: int) -> void:
	collision_mask = new_mask
	if is_inside_tree():
		_update_collision_mask()

func _update_collision_mask() -> void:
	if kinematic_node:
		kinematic_node.collision_mask = collision_mask

func _physics_process(delta: float):
	# Do not run physics if in the editor
	if Engine.editor_hint:
		return

	# If disabled then turn of physics processing and bail out
	if !enabled:
		set_physics_process(false)
		return

	# Decrement the jump cool-down on each physics update
	if _jump_cooldown:
		_jump_cooldown -= 1

	# Update the kinematic body to be under the camera
	_update_body_under_camera()

	# Update the ground information
	_update_ground_information(delta)

	# Get the player body location before movement occurs
	var position_before_movement := kinematic_node.global_transform.origin

	# Run the movement providers in order. The providers can:
	# - Move the kinematic node around (to move the player)
	# - Rotate the ARVROrigin around the camera (to rotate the player)
	# - Read and modify the player velocity
	# - Read and modify the ground-control velocity
	# - Perform exclusive updating of the player (bypassing other movement providers)
	# - Request a jump
	ground_control_velocity = Vector2.ZERO
	var exclusive := false
	for p in _movement_providers:
		if p.is_active or (p.enabled and not exclusive):
			if p.physics_movement(delta, self, exclusive):
				exclusive = true

	# If no controller has performed an exclusive-update then apply gravity and
	# perform any ground-control
	if !exclusive:
		if on_ground and ground_physics.stop_on_slope and ground_angle < ground_physics.move_max_slope:
			# Apply gravity towards slope to prevent sliding
			velocity += ground_vector * gravity * delta
		else:
			# Apply gravity down
			velocity += Vector3.UP * gravity * delta
		_apply_velocity_and_control(delta)

	# Apply the player-body movement to the ARVR origin
	var movement := kinematic_node.global_transform.origin - position_before_movement
	origin_node.global_transform.origin += movement

# Request a jump
func request_jump(var skip_jump_velocity := false):
	# Skip if cooling down from a previous jump
	if _jump_cooldown:
		return;

	# Skip if not on ground
	if !on_ground:
		return

	# Skip if jump disabled on this ground
	var jump_velocity := GroundPhysicsSettings.get_jump_velocity(ground_physics, default_physics)
	if jump_velocity == 0.0:
		return

	# Skip if the ground is too steep to jump
	var max_slope := GroundPhysicsSettings.get_jump_max_slope(ground_physics, default_physics)
	if ground_angle > max_slope:
		return

	# Perform the jump
	if !skip_jump_velocity:
		velocity += ground_vector * jump_velocity * ARVRServer.world_scale

	# Report the jump
	emit_signal("player_jumped")
	_jump_cooldown = 4

# Perform a move_and_slide on the kinematic node
func move_and_slide(var velocity: Vector3) -> Vector3:
	return kinematic_node.move_and_slide(velocity, Vector3.UP, false, 4, 0.785398, push_rigid_bodies)

# Set or clear a named height override
func override_player_height(key, value: float = -1.0):
	# Clear or set the override
	if value < 0.0:
		_player_height_overrides.erase(key)
	else:
		_player_height_overrides[key] = value

	# Set or clear the override value
	var override = _player_height_overrides.values().min()
	_player_height_override = override if override != null else -1.0

# This method updates the body to match the player position
func _update_body_under_camera():
	# Calculate the player height based on the camera position in the origin and the calibration
	var player_height := clamp(
		camera_node.transform.origin.y + player_head_height + player_height_offset,
		player_height_min * ARVRServer.world_scale,
		player_height_max * ARVRServer.world_scale)

	# Allow forced overriding of height
	if _player_height_override >= 0.0:
		player_height = _player_height_override

	# Ensure player height makes mathematical sense
	player_height = max(player_height, player_radius * 2.0)

	# Adjust the collision shape to match the player geometry
	_collision_node.shape.radius = player_radius
	_collision_node.shape.height = player_height - (player_radius * 2.0)
	_collision_node.transform.origin.y = (player_height / 2.0)

	# Center the kinematic body on the ground under the camera
	var curr_transform := kinematic_node.global_transform
	var camera_transform := camera_node.global_transform
	curr_transform.origin = camera_transform.origin
	curr_transform.origin.y += player_head_height - player_height

	# The camera/eyes are towards the front of the body, so move the body back slightly
	var forward_dir := -camera_transform.basis.z * HORIZONTAL
	if forward_dir.length() > 0.01:
		curr_transform.origin -= forward_dir.normalized() * eye_forward_offset * player_radius

	# Set the body position
	kinematic_node.global_transform = curr_transform

# This method updates the information about the ground under the players feet
func _update_ground_information(delta: float):
	# Update the ground information
	var ground_collision := kinematic_node.move_and_collide(Vector3(0.0, -0.1, 0.0), true, true, true)
	if !ground_collision:
		on_ground = false
		ground_vector = Vector3.UP
		ground_angle = 0.0
		ground_node = null
		ground_physics = null
		_previous_ground_node = null
		return

	# Save the ground information from the collision
	on_ground = true
	ground_vector = ground_collision.normal
	ground_angle = rad2deg(ground_collision.get_angle())
	ground_node = ground_collision.collider

	# Select the ground physics
	var physics_node := ground_node.get_node_or_null("GroundPhysics") as GroundPhysics
	if physics_node:
		ground_physics = physics_node.physics
	else:
		ground_physics = default_physics

	# Detect if we're sliding on a wall
	# TODO: consider reworking this magic angle
	if ground_angle > 85:
		on_ground = false

	# Detect ground velocity under players feet
	if _previous_ground_node == ground_node:
		var pos_old := _previous_ground_global
		var pos_new := ground_node.to_global(_previous_ground_local)
		ground_velocity = (pos_new - pos_old) / delta
	
	# Update ground velocity information
	_previous_ground_node = ground_node
	_previous_ground_global = ground_collision.position
	_previous_ground_local = ground_node.to_local(_previous_ground_global)


# This method applies the player velocity and ground-control velocity to the physical body
func _apply_velocity_and_control(delta: float):
	# Calculate local velocity
	var local_velocity := velocity - ground_velocity
	
	# Split the velocity into horizontal and vertical components
	var horizontal_velocity := local_velocity * HORIZONTAL
	var vertical_velocity := local_velocity * Vector3.UP

	# If the player is on the ground then give them control
	if on_ground:
		# If ground control is being supplied then update the horizontal velocity
		var control_velocity := Vector3.ZERO
		if abs(ground_control_velocity.x) > 0.1 or abs(ground_control_velocity.y) > 0.1:
			var camera_transform := camera_node.global_transform
			var dir_forward := (camera_transform.basis.z * HORIZONTAL).normalized()
			var dir_right := (camera_transform.basis.x * HORIZONTAL).normalized()
			control_velocity = (dir_forward * -ground_control_velocity.y + dir_right * ground_control_velocity.x) * ARVRServer.world_scale

			# Apply control velocity to horizontal velocity based on traction
			var current_traction := GroundPhysicsSettings.get_move_traction(ground_physics, default_physics)
			var traction_factor := clamp(current_traction * delta, 0.0, 1.0)
			horizontal_velocity = lerp(horizontal_velocity, control_velocity, traction_factor)

			# Prevent the player from moving up steep slopes
			var current_max_slope := GroundPhysicsSettings.get_move_max_slope(ground_physics, default_physics)
			if ground_angle > current_max_slope:
				# Get a vector in the down-hill direction
				var down_direction := (ground_vector * HORIZONTAL).normalized()
				var vdot := down_direction.dot(horizontal_velocity)
				if vdot < 0:
					horizontal_velocity -= down_direction * vdot
		else:
			# User is not trying to move, so apply the ground drag
			var current_drag := GroundPhysicsSettings.get_move_drag(ground_physics, default_physics)
			var drag_factor := clamp(current_drag * delta, 0, 1)
			horizontal_velocity = lerp(horizontal_velocity, control_velocity, drag_factor)

	# Combine the velocities back to a 3-space velocity
	local_velocity = horizontal_velocity + vertical_velocity

	# Move the player body with the desired velocity
	velocity = move_and_slide(local_velocity + ground_velocity)

	# Hack to ensure feet stick to ground (if not jumping)
	if abs(velocity.y) < 0.001:
		velocity.y = ground_velocity.y

# Get a guaranteed-valid physics
func _guaranteed_physics():
	# Ensure we have a guaranteed-valid GroundPhysicsSettings value
	var valid_physics := physics as GroundPhysicsSettings
	if !valid_physics:
		valid_physics = GroundPhysicsSettings.new()
		valid_physics.resource_name = "default"

	# Return the guaranteed-valid physics
	return valid_physics

# This method verifies the PlayerBody has a valid configuration. Specifically it
# checks the following:
# - ARVROrigin can be identified
# - ARVRCamera can be identified
# - Player radius is valid
# - Maximum slope is valid
func _get_configuration_warning():
	# Check the origin node
	var test_origin_node = ARVRHelpers.get_arvr_origin(self)
	if !test_origin_node:
		return "Unable to find ARVR Origin node"

	# Check the camera node
	var test_camera_node = ARVRHelpers.get_arvr_camera(self)
	if !test_camera_node:
		return "Unable to find ARVR Camera node"

	# Verify the player radius is valid
	if player_radius <= 0:
		return "Player radius must be configured"

	# Verify the player height minimum is valid
	if player_height_min < player_radius * 2.0:
		return "Player height minimum smaller than 2x radius"

	# Verify the player height maximum is valid
	if player_height_max < player_height_min:
		return "Player height maximum cannot be smaller than minimum"

	# Verify eye-forward does not allow near-clip-plane look through
	var eyes_to_collider = (1.0 - eye_forward_offset) * player_radius
	if eyes_to_collider < test_camera_node.near:
		return "Eyes too far forwards. Move eyes back or decrease camera near clipping plane"

	# If specified, verify the ground physics is a valid type
	if physics and !physics is GroundPhysicsSettings:
		return "Physics resource must be a GroundPhysicsSetting"

	# Passed basic validation
	return ""

## Find the Player Body from a player node and an optional path
static func get_player_body(node: Node, var path: NodePath = "") -> PlayerBody:
	var player_body: PlayerBody

	# Try using the node path first
	if path:
		player_body = node.get_node(path) as PlayerBody
		if player_body:
			return player_body

	# Get the origin
	var arvr_origin := ARVRHelpers.get_arvr_origin(node)
	if !arvr_origin:
		return null

	# Attempt to get by the default name
	player_body = arvr_origin.get_node_or_null("PlayerBody") as PlayerBody
	if player_body:
		return player_body

	# Search all children of the origin for the player body
	for child in arvr_origin.get_children():
		player_body = child as PlayerBody
		if player_body:
			return player_body

	# Could not find player body
	return null
