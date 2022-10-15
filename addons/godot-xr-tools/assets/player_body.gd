@tool
class_name XRToolsPlayerBody
extends Node
@icon("res://addons/godot-xr-tools/editor/icons/body.svg")


## XR Tools Player Physics Body Script
##
## This node provides the player with a physics body. The body is a 
## [CapsuleShape3D] which tracks the player location as measured by the 
## [XRCamera3D] for the players head.
##
## The player body can detect when the player is in the air, on the ground,
## or on a steep slope.
##
## Player movement is achieved by a number of movement providers attached to
## either the player or their controllers.
##
## After the player body moves, the [XROrigin3D] is updated as necessary to 
## track the players movement.


## Signal emitted when the player jumps
signal player_jumped()

## Signal emitted when the player bounces
signal player_bounced(collider, magnitude)


## Horizontal vector - used to extract horizontal-only components of a Vector3
const HORIZONTAL := Vector3(1.0, 0.0, 1.0)


## If true, the player body performs physics processing and movement
@export var enabled : bool = true: set = set_enabled

## Radius of the player body collider
@export var player_radius : float = 0.4: set = set_player_radius

## Player head height (distance between between camera and top of head)
@export var player_head_height : float = 0.1

## Minimum player height
@export var player_height_min : float = 1.0

## Maximum player height
@export var player_height_max : float = 2.2

## Eyes forward offset from center of body in player_radius units
@export_range(0.0, 1.0) var eye_forward_offset : float = 0.66

## Force of gravity on the player
@export var gravity : float = -9.8

## Lets the player push rigid bodies
@export var push_rigid_bodies : bool = true

## Default ground physics settings
@export var physics : XRToolsGroundPhysicsSettings: set = set_physics

## Collision layer for the player body
@export_flags_3d_physics var collision_layer : int = 1 << 19: set = set_collision_layer

## Collision mask for the player body
@export_flags_3d_physics var collision_mask : int = 1023: set = set_collision_mask


## Player 3D Velocity - modified by [XRToolsMovementProvider] nodes
var velocity : Vector3 = Vector3.ZERO

## Set true when the player is on the ground
var on_ground : bool = true

## Normal vector for the ground under the player
var ground_vector : Vector3 = Vector3.UP

## Ground slope angle
var ground_angle : float = 0.0

## Ground node the player is touching
var ground_node : Node3D = null

## Ground physics override (if present)
var ground_physics : XRToolsGroundPhysicsSettings = null

## Ground control velocity - modified by [XRToolsMovementProvider] nodes
var ground_control_velocity : Vector2 = Vector2.ZERO

## Player height offset - used for height calibration
var player_height_offset : float = 0.0

## Velocity of the ground under the players feet
var ground_velocity : Vector3 = Vector3.ZERO


## Array of [XRToolsMovementProvider] nodes for the player
var _movement_providers := Array()

## Jump cool-down counter
var _jump_cooldown := 0

## Player height overrides
var _player_height_overrides := { }

## Player height override (enabled when non-negative)
var _player_height_override : float = -1.0

## Previous ground node
var _previous_ground_node : Node3D = null

## Previous ground local position
var _previous_ground_local : Vector3 = Vector3.ZERO

## Previous ground global position
var _previous_ground_global : Vector3 = Vector3.ZERO


## XROrigin3D node
@onready var origin_node : XROrigin3D = XRHelpers.get_xr_origin(self)

## XRCamera3D node
@onready var camera_node : XRCamera3D = XRHelpers.get_xr_camera(self)

## Player body node
@onready var kinematic_node : CharacterBody3D = $CharacterBody3D

## Default physics (if not specified by the player or the current ground)
@onready var default_physics = _guaranteed_physics()

## Player body collision node
@onready var _collision_node : CollisionShape3D = $CharacterBody3D/CollisionShape3D


## Function to sort movement providers by order
func sort_by_order(a, b) -> bool:
	return true if a.order < b.order else false


## Called when the node enters the scene tree for the first time.
func _ready():
	# Get the movement providers ordered by increasing order
	_movement_providers = get_tree().get_nodes_in_group("movement_providers")
	_movement_providers.sort_custom(sort_by_order)

	# Propagate defaults
	_update_enabled()
	_update_player_radius()
	_update_collision_layer()
	_update_collision_mask()

func set_enabled(new_value) -> void:
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

func set_physics(new_value: XRToolsGroundPhysicsSettings) -> void:
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
	if Engine.is_editor_hint():
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
	# - Rotate the XROrigin3D around the camera (to rotate the player)
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

	# Apply the player-body movement to the XR origin
	var movement := kinematic_node.global_transform.origin - position_before_movement
	origin_node.global_transform.origin += movement

## Request a jump
func request_jump(skip_jump_velocity := false):
	# Skip if cooling down from a previous jump
	if _jump_cooldown:
		return;

	# Skip if not on ground
	if !on_ground:
		return

	# Skip if jump disabled on this ground
	var jump_velocity := XRToolsGroundPhysicsSettings.get_jump_velocity(ground_physics, default_physics)
	if jump_velocity == 0.0:
		return

	# Skip if the ground is too steep to jump
	var max_slope := XRToolsGroundPhysicsSettings.get_jump_max_slope(ground_physics, default_physics)
	if ground_angle > max_slope:
		return

	# Perform the jump
	if !skip_jump_velocity:
		velocity += ground_vector * jump_velocity * XRServer.world_scale

	# Report the jump
	emit_signal("player_jumped")
	_jump_cooldown = 4

## This function moves the players body using the provided velocity. Movement
## providers may use this function if they are exclusively driving the player.
func move_body(p_velocity: Vector3) -> Vector3:
	kinematic_node.velocity = p_velocity
	kinematic_node.up_direction = Vector3.UP
	kinematic_node.floor_stop_on_slope = false
	kinematic_node.floor_max_angle = 0.785398
	kinematic_node.max_slides = 4
	# push_rigid_bodies seems to no longer be supported...
	var can_move = kinematic_node.move_and_slide()
	return kinematic_node.velocity

## Set or clear a named height override
func override_player_height(key, value: float = -1.0):
	# Clear or set the override
	if value < 0.0:
		_player_height_overrides.erase(key)
	else:
		_player_height_overrides[key] = value

	# Set or clear the override value
	var override = _player_height_overrides.values().min()
	_player_height_override = override if override != null else -1.0

## This method updates the player body to match the player position
func _update_body_under_camera():
	# Calculate the player height based on the camera position in the origin and the calibration
	var player_height: float = clamp(
		camera_node.transform.origin.y + player_head_height + player_height_offset,
		player_height_min * XRServer.world_scale,
		player_height_max * XRServer.world_scale)

	# Allow forced overriding of height
	if _player_height_override >= 0.0:
		player_height = _player_height_override

	# Ensure player height makes mathematical sense
	player_height = max(player_height, player_radius)

	# Adjust the collision shape to match the player geometry
	_collision_node.shape.radius = player_radius
	_collision_node.shape.height = player_height
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
	var ground_collision := kinematic_node.move_and_collide(Vector3(0.0, -0.1, 0.0), true)
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
	ground_vector = ground_collision.get_normal()
	ground_angle = rad_to_deg(ground_collision.get_angle())
	ground_node = ground_collision.get_collider()

	# Select the ground physics
	var physics_node := ground_node.get_node_or_null("GroundPhysics") as XRToolsGroundPhysics
	ground_physics = XRToolsGroundPhysics.get_physics(physics_node, default_physics)

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
	_previous_ground_global = ground_collision.get_position()
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
			control_velocity = (dir_forward * -ground_control_velocity.y + dir_right * ground_control_velocity.x) * XRServer.world_scale

			# Apply control velocity to horizontal velocity based on traction
			var current_traction := XRToolsGroundPhysicsSettings.get_move_traction(ground_physics, default_physics)
			var traction_factor: float = clamp(current_traction * delta, 0.0, 1.0)
			horizontal_velocity = horizontal_velocity.lerp(control_velocity, traction_factor)

			# Prevent the player from moving up steep slopes
			var current_max_slope := XRToolsGroundPhysicsSettings.get_move_max_slope(ground_physics, default_physics)
			if ground_angle > current_max_slope:
				# Get a vector in the down-hill direction
				var down_direction := (ground_vector * HORIZONTAL).normalized()
				var vdot: float = down_direction.dot(horizontal_velocity)
				if vdot < 0:
					horizontal_velocity -= down_direction * vdot
		else:
			# User is not trying to move, so apply the ground drag
			var current_drag := XRToolsGroundPhysicsSettings.get_move_drag(ground_physics, default_physics)
			var drag_factor: float = clamp(current_drag * delta, 0, 1)
			horizontal_velocity = horizontal_velocity.lerp(control_velocity, drag_factor)

	# Combine the velocities back to a 3-space velocity
	local_velocity = horizontal_velocity + vertical_velocity

	# Move the player body with the desired velocity
	velocity = move_body(local_velocity + ground_velocity)

	# Perform bounce test if a collision occurred
	if kinematic_node.get_slide_collision_count():
		# Detect bounciness
		var collision := kinematic_node.get_slide_collision(0)
		var collision_node := collision.get_collider()
		var collision_physics_node := collision_node.get_node_or_null("GroundPhysics") as XRToolsGroundPhysics
		var collision_physics = XRToolsGroundPhysics.get_physics(collision_physics_node, default_physics)
		var bounce_threshold := XRToolsGroundPhysicsSettings.get_bounce_threshold(collision_physics, default_physics)
		var bounciness := XRToolsGroundPhysicsSettings.get_bounciness(collision_physics, default_physics)
		var magnitude := -collision.get_normal().dot(local_velocity)

		# Detect if bounce should be performed
		if bounciness > 0.0 and magnitude >= bounce_threshold:
			local_velocity += 2 * collision.normal * magnitude * bounciness
			velocity = local_velocity + ground_velocity
			emit_signal("player_bounced", collision_node, magnitude)

	# Hack to ensure feet stick to ground (if not jumping)
	if abs(velocity.y) < 0.001:
		velocity.y = ground_velocity.y

# Get a guaranteed-valid physics
func _guaranteed_physics():
	# Ensure we have a guaranteed-valid XRToolsGroundPhysicsSettings value
	var valid_physics := physics as XRToolsGroundPhysicsSettings
	if !valid_physics:
		valid_physics = XRToolsGroundPhysicsSettings.new()
		valid_physics.resource_name = "default"

	# Return the guaranteed-valid physics
	return valid_physics

# This method verifies the XRToolsPlayerBody has a valid configuration. Specifically it
# checks the following:
# - XROrigin3D can be identified
# - XRCamera3D can be identified
# - Player radius is valid
# - Maximum slope is valid
func _get_configuration_warning():
	# Check the origin node
	var test_origin_node = XRHelpers.get_xr_origin(self)
	if !test_origin_node:
		return "Unable to find XR Origin node"

	# Check the camera node
	var test_camera_node = XRHelpers.get_xr_camera(self)
	if !test_camera_node:
		return "Unable to find XR Camera node"

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
	if physics and !physics is XRToolsGroundPhysicsSettings:
		return "Physics resource must be a GroundPhysicsSettings"

	# Passed basic validation
	return ""

## Find the Player Body from a player node and an optional path
static func get_player_body(node: Node, path: NodePath = NodePath("")) -> XRToolsPlayerBody:
	var player_body: XRToolsPlayerBody

	# Try using the node path first
	if path:
		player_body = node.get_node(path) as XRToolsPlayerBody
		if player_body:
			return player_body

	# Get the origin
	var xr_origin := XRHelpers.get_xr_origin(node)
	if !xr_origin:
		return null

	# Attempt to get by the default name
	player_body = xr_origin.get_node_or_null("PlayerBody") as XRToolsPlayerBody
	if player_body:
		return player_body

	# Search all children of the origin for the XRToolsPlayerBody
	for child in xr_origin.get_children():
		player_body = child as XRToolsPlayerBody
		if player_body:
			return player_body

	# Could not find XRToolsPlayerBody
	return null
