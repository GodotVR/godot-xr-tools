@tool
class_name PlayerBody
extends Node

##
## Player Physics Body Script
##
## @desc:
##     This script works with the PlayerBody asset to provide the player with
##     a PlayerBody. This PlayerBody is a capsule tracking the players hear
##     via the XRCamera3D node.
##
##     The PlayerBody can detect when the player is in the air, on the ground,
##     or on a steep slope.
##
##     The PlayerBody works with movement providers to allow the player to move
##     around the environment.
##
##     At the end of each physics process step the XROrigin3D is updated to
##     track any movement to the PlayerBody.
##


## Signal emitted when the player jumps
signal player_jumped()


# Horizontal vector (multiply by this to get only the horizontal components
const HORIZONTAL := Vector3(1.0, 0.0, 1.0)


## PlayerBody enabled flag
@export var enabled = true:
	set(new_value):
		enabled = new_value
		if is_inside_tree():
			_update_enabled()

## Player radius
@export var player_radius : float = 0.4:
	set(new_value):
		player_radius = new_value
		if is_inside_tree():
			_update_player_radius()

## Player camera to head top
@export var player_cam_to_head_top : float = 0.1

## Eyes forward offset from center of body in player_radius units
@export_range(0.0, 1.0) var eye_forward_offset : float = 0.66

## Force of gravity on the player
@export var gravity : float = -9.8

## Lets the player push rigid bodies
@export var push_rigid_bodies : bool = true

## GroundPhysicsSettings to apply - can only be typed in Godot 4+
@export var physics : Resource:
	set(new_value):
		# Save the property
		physics = new_value
		default_physics = _guaranteed_physics()

# Set our collision layer
@export_flags_3d_physics var collision_layer : int = 1 << 19:
	set(new_value):
		collision_layer = new_value
		if is_inside_tree():
			_update_collision_layer()

# Set our collision mask
@export_flags_3d_physics var collision_mask : int = 1023:
	set(new_value):
		collision_mask = new_value
		if is_inside_tree():
			_update_collision_mask()


## Player Velocity - modifiable by MovementProvider nodes
var velocity := Vector3.ZERO

## Player On Ground flag - used by MovementProvider nodes
var on_ground := true

## Ground 'up' vector - used by MovementProvider nodes
var ground_vector := Vector3.UP

## Ground slope angle - used by MovementProvider nodes
var ground_angle := 0.0

## Ground node the player is touching
var ground_node: Node = null

## Ground physics override (if present)
var ground_physics: GroundPhysicsSettings = null

## Ground control velocity - modified by MovementProvider nodes
var ground_control_velocity := Vector2.ZERO

# Movement providers
var _movement_providers := Array()

# Jump cool-down counter
var _jump_cooldown := 0


## XROrigin3D node
@onready var origin_node: XROrigin3D = XRHelpers.get_xr_origin(self)

## XRCamera3D node
@onready var camera_node: XRCamera3D = XRHelpers.get_xr_camera(self)

## Player CharacterBody3D node
@onready var kinematic_node: CharacterBody3D = $CharacterBody3D

# Default physics (if not specified by the user or the current ground)
@onready var default_physics = _guaranteed_physics()

# Collision node
@onready var _collision_node: CollisionShape3D = $CharacterBody3D/CollisionShape3D


# Function to sort movement providers by order
func sort_by_order(a, b) -> bool:
	return true if a.order < b.order else false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the movement providers ordered by increasing order
	_movement_providers = get_tree().get_nodes_in_group("movement_providers")
	_movement_providers.sort_custom(sort_by_order)

	# Propagate defaults
	_update_enabled()
	_update_player_radius()
	_update_collision_layer()
	_update_collision_mask()

func _update_enabled() -> void:
	# Update collision_shape
	if _collision_node:
		_collision_node.disabled = !enabled

	# Update physics processing
	if enabled:
		set_physics_process(true)

func _update_player_radius() -> void:
	if _collision_node and _collision_node.shape:
		_collision_node.shape.radius = player_radius

func _update_collision_layer() -> void:
	if kinematic_node:
		kinematic_node.collision_layer = collision_layer

func _update_collision_mask() -> void:
	if kinematic_node:
		kinematic_node.collision_mask = collision_mask

func _physics_process(delta):
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
	_update_ground_information()

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
		if p.enabled or p.is_active:
			if p.physics_movement(delta, self):
				exclusive = true
				break

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

# Request a jump
func request_jump(skip_jump_velocity := false):
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
		velocity += ground_vector * jump_velocity * XRServer.world_scale

	# Report the jump
	emit_signal("player_jumped")
	_jump_cooldown = 4

# Perform a move_and_slide on the kinematic node
func move_and_slide(p_velocity: Vector3) -> Vector3:
	kinematic_node.velocity = p_velocity
	kinematic_node.up_direction = Vector3.UP
	kinematic_node.floor_stop_on_slope = false
	kinematic_node.floor_max_angle = 0.785398
	kinematic_node.max_slides = 4
	# push_rigid_bodies seems to no longer be supported...
	var can_move = kinematic_node.move_and_slide()
	return kinematic_node.velocity

# This method updates the body to match the player position
func _update_body_under_camera():
	# Calculate the player height based on the origin and camera position
	var player_height := camera_node.transform.origin.y + player_cam_to_head_top
	if player_height < player_radius:
		player_height = player_radius

	# Adjust the collision shape to match the player geometry
	_collision_node.shape.radius = player_radius
	_collision_node.shape.height = player_height
	_collision_node.transform.origin.y = (player_height / 2.0)

	# Center the kinematic body on the ground under the camera
	var curr_transform := kinematic_node.global_transform
	var camera_transform := camera_node.global_transform
	curr_transform.origin = camera_transform.origin
	curr_transform.origin.y = origin_node.global_transform.origin.y

	# The camera/eyes are towards the front of the body, so move the body back slightly
	var forward_dir := -camera_transform.basis.z * HORIZONTAL
	if forward_dir.length() > 0.01:
		curr_transform.origin -= forward_dir.normalized() * eye_forward_offset * player_radius

	# Set the body position
	kinematic_node.global_transform = curr_transform

# This method updates the information about the ground under the players feet
func _update_ground_information():
	# Update the ground information
	var ground_collision := kinematic_node.move_and_collide(Vector3(0.0, -0.05, 0.0), true)
	if !ground_collision:
		on_ground = false
		ground_vector = Vector3.UP
		ground_angle = 0.0
		ground_node = null
		ground_physics = null
	else:
		on_ground = true
		ground_vector = ground_collision.get_normal()
		ground_angle = rad2deg(ground_collision.get_angle())
		ground_node = ground_collision.get_collider()

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

# This method applies the player velocity and ground-control velocity to the physical body
func _apply_velocity_and_control(delta: float):
	# Split the velocity into horizontal and vertical components
	var horizontal_velocity := velocity * HORIZONTAL
	var vertical_velocity := velocity * Vector3.UP

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
			var current_traction := GroundPhysicsSettings.get_move_traction(ground_physics, default_physics)
			var traction_factor = clamp(current_traction * delta, 0.0, 1.0)
			horizontal_velocity = horizontal_velocity.lerp(control_velocity, traction_factor)

			# Prevent the player from moving up steep slopes
			var current_max_slope := GroundPhysicsSettings.get_move_max_slope(ground_physics, default_physics)
			if ground_angle > current_max_slope:
				# Get a vector in the down-hill direction
				var down_direction := (ground_vector * HORIZONTAL).normalized()
				var vdot = down_direction.dot(horizontal_velocity)
				if vdot < 0:
					horizontal_velocity -= down_direction * vdot
		else:
			# User is not trying to move, so apply the ground drag
			var current_drag := GroundPhysicsSettings.get_move_drag(ground_physics, default_physics)
			horizontal_velocity *= 1.0 - current_drag * delta

	# Combine the velocities back to a 3-space velocity
	velocity = horizontal_velocity + vertical_velocity

	# Move the player body with the desired velocity
	velocity = move_and_slide(velocity)

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
static func get_player_body(node: Node, path: NodePath = NodePath()) -> PlayerBody:
	var player_body: PlayerBody

	# Try using the node path first
	if path:
		player_body = node.get_node(path) as PlayerBody
		if player_body:
			return player_body

	# Get the origin
	var xr_origin := XRHelpers.get_xr_origin(node)
	if !xr_origin:
		return null

	# Attempt to get by the default name
	player_body = xr_origin.get_node_or_null("PlayerBody") as PlayerBody
	if player_body:
		return player_body

	# Search all children of the origin for the player body
	for child in xr_origin.get_children():
		player_body = child as PlayerBody
		if player_body:
			return player_body

	# Could not find player body
	return null
