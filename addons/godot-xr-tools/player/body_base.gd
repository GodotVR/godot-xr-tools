@tool
@icon("res://addons/godot-xr-tools/editor/icons/body.svg")
class_name XRToolsBodyBase
extends CharacterBody3D

## TODO move shared parts from player_body and character_body into here
## NOTE variables that are not explicitely marked as export
## should be considered protected to this class!!

## Signal emitted when the player jumps
signal player_jumped()

## Signal emitted when the player bounces
signal player_bounced(collider, magnitude)

## Enumeration indicating when ground control can be used
enum GroundControl {
	ON_GROUND,		## Apply ground control only when on ground
	NEAR_GROUND,	## Apply ground control when near ground
	ALWAYS			## Apply ground control always
}

## Ground distance considered "on" the ground
const ON_GROUND_DISTANCE := 0.1

## Ground distance considered "near" the ground
const NEAR_GROUND_DISTANCE := 1.0

## If true, the player body performs physics processing and movement
@export var enabled : bool = true: set = set_enabled

## Default ground physics settings
@export var physics : XRToolsGroundPhysicsSettings: set = set_physics

## Option for specifying when ground control is allowed
@export var ground_control : GroundControl = GroundControl.ON_GROUND

## Default physics (if not specified by the user or the current ground)
@onready var default_physics = _guaranteed_physics()

## XROrigin3D node
@onready var origin_node : XROrigin3D = XRHelpers.get_xr_origin(self)

## XRCamera3D node
@onready var camera_node : XRCamera3D = XRHelpers.get_xr_camera(self)

## Left hand XRController3D node
@onready var left_hand_node : XRController3D = XRHelpers.get_left_controller(self)

## Right hand XRController3D node
@onready var right_hand_node : XRController3D = XRHelpers.get_right_controller(self)

# Array of [XRToolsMovementProvider] nodes for the player
var _movement_providers := Array()

# Jump cool-down counter
var _jump_cooldown := 0

## Current player gravity
var gravity : Vector3 = Vector3.ZERO

## Gravity-based "up" direction
var up_gravity_vector := Vector3.UP

## Player-based "up" direction
var up_player_vector := Vector3.UP

## Gravity-based "up" plane
var up_gravity_plane := Plane(Vector3.UP, 0.0)

## Player-based "up" plane
var up_player_plane := Plane(Vector3.UP, 0.0)

## Set true when the player is on the ground
var on_ground : bool = true

## Set true when the player is near the ground
var near_ground : bool = true

## Velocity of the ground under the players feet
var ground_velocity : Vector3 = Vector3.ZERO

## Normal vector for the ground under the player
var ground_vector : Vector3 = Vector3.UP

## Ground node the player is touching
var ground_node : Node3D = null

## Ground slope angle
var ground_angle : float = 0.0

## Ground physics override (if present)
var ground_physics : XRToolsGroundPhysicsSettings = null

## Ground control velocity - modifiable by [XRToolsMovementProvider] nodes
var ground_control_velocity : Vector2 = Vector2.ZERO

# Previous ground node
var _previous_ground_node : Node3D = null

# Previous ground local position
var _previous_ground_local : Vector3 = Vector3.ZERO

# Previous ground global position
var _previous_ground_global : Vector3 = Vector3.ZERO

## Player height offset - used for height calibration
var player_height_offset : float = 0.0

# Player height overrides
var _player_height_overrides := { }

# Player height override (enabled when non-negative)
var _player_height_override : float = -1.0


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsBodyBase"

func set_enabled(new_value) -> void:
	enabled = new_value
	if is_inside_tree():
		_update_enabled()

func _update_enabled() -> void:
	# Update physics processing
	if enabled:
		set_physics_process(true)

func set_physics(new_value: XRToolsGroundPhysicsSettings) -> void:
	# Save the property
	physics = new_value
	default_physics = _guaranteed_physics()

# Get a guaranteed-valid physics
func _guaranteed_physics():
	# Ensure we have a guaranteed-valid XRToolsGroundPhysicsSettings value
	var valid_physics := physics as XRToolsGroundPhysicsSettings
	if !valid_physics:
		valid_physics = XRToolsGroundPhysicsSettings.new()
		valid_physics.resource_name = "default"

	# Return the guaranteed-valid physics
	return valid_physics

## Request a jump
func request_jump(skip_jump_velocity := false):
	# Skip if cooling down from a previous jump
	if _jump_cooldown:
		return;

	# Skip if not on ground
	if !on_ground:
		return

	# Skip if jump disabled on this ground
	var jump_velocity := XRToolsGroundPhysicsSettings.get_jump_velocity(
			ground_physics, default_physics)
	if jump_velocity == 0.0:
		return

	# Skip if the ground is too steep to jump
	var max_slope := XRToolsGroundPhysicsSettings.get_jump_max_slope(
			ground_physics, default_physics)
	if ground_angle > max_slope:
		return

	# Perform the jump
	if !skip_jump_velocity:
		velocity += ground_vector * jump_velocity * XRServer.world_scale

	# Report the jump
	emit_signal("player_jumped")
	_jump_cooldown = 4

## This method sets or clears a named height override
func override_player_height(key, value: float = -1.0):
	# Clear or set the override
	if value < 0.0:
		_player_height_overrides.erase(key)
	else:
		_player_height_overrides[key] = value

	# Set or clear the override value
	var override = _player_height_overrides.values().min()
	_player_height_override = override if override != null else -1.0

## This method moves the players body using the provided velocity. Movement
## providers may use this function if they are exclusively driving the player.
func move_body(p_velocity: Vector3) -> Vector3:
	velocity = p_velocity
	max_slides = 4
	up_direction = up_gravity_vector
	# push_rigid_bodies seems to no longer be supported...
	move_and_slide()
	return velocity

## Function to sort movement providers by order
func _sort_by_order(a, b) -> bool:
	return true if a.order < b.order else false

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the movement providers ordered by increasing order
	_movement_providers = get_tree().get_nodes_in_group("movement_providers")
	_movement_providers.sort_custom(_sort_by_order)

	# Propagate defaults
	_update_enabled()

# This method updates the information about the ground under the players feet
func _update_ground_information(delta: float):
	# Test how close we are to the ground
	var ground_collision := move_and_collide(
			up_gravity_vector * -NEAR_GROUND_DISTANCE, true)

	# Handle no collision (or too far away to care about)
	if !ground_collision:
		near_ground = false
		on_ground = false
		ground_vector = up_gravity_vector
		ground_angle = 0.0
		ground_node = null
		ground_physics = null
		_previous_ground_node = null
		return

	# Categorize the type of ground contact
	near_ground = true
	on_ground = ground_collision.get_travel().length() <= ON_GROUND_DISTANCE

	# Save the ground information from the collision
	ground_vector = ground_collision.get_normal()
	ground_angle = rad_to_deg(ground_collision.get_angle(0, up_gravity_vector))
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
	var horizontal_velocity := up_gravity_plane.project(local_velocity)
	var vertical_velocity := local_velocity - horizontal_velocity

	# If the player is on the ground then give them control
	if _can_apply_ground_control():
		# If ground control is being supplied then update the horizontal velocity
		var control_velocity := Vector3.ZERO
		if abs(ground_control_velocity.x) > 0.1 or abs(ground_control_velocity.y) > 0.1:
			var camera_transform := camera_node.global_transform
			var dir_forward := up_gravity_plane.project(camera_transform.basis.z).normalized()
			var dir_right := up_gravity_plane.project(camera_transform.basis.x).normalized()
			control_velocity = (
					dir_forward * -ground_control_velocity.y +
					dir_right * ground_control_velocity.x
			) * XRServer.world_scale

			# Apply control velocity to horizontal velocity based on traction
			var current_traction := XRToolsGroundPhysicsSettings.get_move_traction(
					ground_physics, default_physics)
			var traction_factor: float = clamp(current_traction * delta, 0.0, 1.0)
			horizontal_velocity = horizontal_velocity.lerp(control_velocity, traction_factor)

			# Prevent the player from moving up steep slopes
			var current_max_slope := XRToolsGroundPhysicsSettings.get_move_max_slope(
					ground_physics, default_physics)
			if ground_angle > current_max_slope:
				# Get a vector in the down-hill direction
				var down_direction := up_gravity_plane.project(ground_vector).normalized()
				var vdot: float = down_direction.dot(horizontal_velocity)
				if vdot < 0:
					horizontal_velocity -= down_direction * vdot
		else:
			# User is not trying to move, so apply the ground drag
			var current_drag := XRToolsGroundPhysicsSettings.get_move_drag(
					ground_physics, default_physics)
			var drag_factor: float = clamp(current_drag * delta, 0, 1)
			horizontal_velocity = horizontal_velocity.lerp(control_velocity, drag_factor)

	# Combine the velocities back to a 3-space velocity
	local_velocity = horizontal_velocity + vertical_velocity

	# Move the player body with the desired velocity
	velocity = move_body(local_velocity + ground_velocity)

	# Perform bounce test if a collision occurred
	if get_slide_collision_count():
		# Get the collider the player collided with
		var collision := get_slide_collision(0)
		var collision_node := collision.get_collider()

		# Check for a GroundPhysics node attached to the collider
		var collision_physics_node := \
				collision_node.get_node_or_null("GroundPhysics") as XRToolsGroundPhysics

		# Get the collision physics associated with the collider
		var collision_physics = XRToolsGroundPhysics.get_physics(
				collision_physics_node, default_physics)

		# Get the bounce parameters associated with the collider
		var bounce_threshold := XRToolsGroundPhysicsSettings.get_bounce_threshold(
				collision_physics, default_physics)
		var bounciness := XRToolsGroundPhysicsSettings.get_bounciness(
				collision_physics, default_physics)
		var magnitude := -collision.get_normal().dot(local_velocity)

		# Detect if bounce should be performed
		if bounciness > 0.0 and magnitude >= bounce_threshold:
			local_velocity += 2 * collision.normal * magnitude * bounciness
			velocity = local_velocity + ground_velocity
			emit_signal("player_bounced", collision_node, magnitude)

	# Hack to ensure feet stick to ground (if not jumping)
	# TODO: FIX
	#if abs(velocity.y) < 0.001:
	#	velocity.y = ground_velocity.y

# Test if the player can apply ground control given the settings and the ground state.
func _can_apply_ground_control() -> bool:
	match ground_control:
		GroundControl.ON_GROUND:
			return on_ground

		GroundControl.NEAR_GROUND:
			return near_ground

		GroundControl.ALWAYS:
			return true

		_:
			return false
