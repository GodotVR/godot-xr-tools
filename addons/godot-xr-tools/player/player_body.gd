@tool
@icon("res://addons/godot-xr-tools/editor/icons/body.svg")
class_name XRToolsPlayerBody
extends CharacterBody3D


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


## Signal emitted when the player jumps.
signal player_jumped()

## Signal emitted when the player teleports.
signal player_teleported(delta_transform)

## Signal emitted when the player bounces.
signal player_bounced(collider, magnitude)

## Signal emitted when the player has moved (excluding teleport).
## This only captures movement handled by the player body logic.
signal player_moved(delta_transform)

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

@export_group("Player setup")

## Automatically calibrate player body on next frame
@export var player_calibrate_height : bool = true

## Radius of the player body collider
@export var player_radius : float = 0.2: set = set_player_radius

## Player head height (distance between between camera and top of head)
@export var player_head_height : float = 0.1

## Minimum player height
@export var player_height_min : float = 0.6

## Maximum player height
@export var player_height_max : float = 2.5

## Slew-rate for player height overriding (button-crouch)
@export var player_height_rate : float = 4.0

## Eyes forward offset from center of body in player_radius units
@export_range(0.0, 1.0) var eye_forward_offset : float = 0.5

## Mix factor for body orientation
@export_range(0.0, 1.0) var body_forward_mix : float = 0.75

## Maximum distance the head may move away from the player body
@export_range(0.0, 2.0, 0.01) var max_head_distance = 1.0

## Behaviour mode when players head collides, or moves beyond [member max_head_distance].
## Push away, pushes the player body away.
## Fade, fades view to black.
@export_enum("Push away", "Fade", "Disabled") var head_behavior_mode = 1

@export_group("Collisions")

## Lets the player push rigid bodies
@export var push_rigid_bodies : bool = true

## If push_rigid_bodies is enabled, provides a strength factor for the impulse
@export var push_strength_factor : float = 1.0

@export_group("Physics")

## Default ground physics settings
@export var physics : XRToolsGroundPhysicsSettings: set = set_physics

## Option for specifying when ground control is allowed
@export var ground_control : GroundControl = GroundControl.ON_GROUND


## Player 3D Velocity - modified by [XRToolsMovementProvider] nodes
#var velocity : Vector3 = Vector3.ZERO

## Current player gravity
var gravity : Vector3 = Vector3.ZERO

## Set true when the player is on the ground
var on_ground : bool = true

## Set true when the player is near the ground
var near_ground : bool = true

## Normal vector for the ground under the player
var ground_vector : Vector3 = Vector3.UP

## Ground slope angle
var ground_angle : float = 0.0

## Ground node the player is touching
var ground_node : Node3D = null

## Ground physics override (if present)
var ground_physics : XRToolsGroundPhysicsSettings = null

## Ground control velocity - modifiable by [XRToolsMovementProvider] nodes
var ground_control_velocity : Vector2 = Vector2.ZERO

## Player height offset - used for height calibration
var player_height_offset : float = 0.0

## Velocity of the ground under the players feet
var ground_velocity : Vector3 = Vector3.ZERO

## Gravity-based "up" direction
var up_gravity := Vector3.UP

## Player-based "up" direction
var up_player := Vector3.UP

# Array of [XRToolsMovementProvider] nodes for the player
var _movement_providers := Array()

# Player height overrides
var _player_height_overrides := { }

# Player height override - current height
var _player_height_override_current : float = 0.0

# Player height override - target height
var _player_height_override_target : float = 0.0

# Player height override - enabled
var _player_height_override_enabled : bool = false

# Player height override - lerp between real and override
var _player_height_override_lerp : float = 0.0

# Previous ground node
var _previous_ground_node : Node3D = null

# Previous ground local position
var _previous_ground_local : Vector3 = Vector3.ZERO

# Previous ground global position
var _previous_ground_global : Vector3 = Vector3.ZERO

# Player body Collision node
var _collision_node : CollisionShape3D

# Player head shape cast
var _head_shape_cast : ShapeCast3D

# True while we're handling physics
var _in_physics_movement : bool = false

# Fade object
var _fade : XRToolsFade

# Fade value
var _fade_value : float = 0.0

## XROrigin3D node
@onready var origin_node : XROrigin3D = XRHelpers.get_xr_origin(self)

## XRCamera3D node
@onready var camera_node : XRCamera3D = XRHelpers.get_xr_camera(self)

## Left hand XRController3D node
@onready var left_hand_node : XRController3D = XRHelpers.get_left_controller(self)

## Right hand XRController3D node
@onready var right_hand_node : XRController3D = XRHelpers.get_right_controller(self)

## Default physics (if not specified by the user or the current ground)
@onready var default_physics = _guaranteed_physics()


## Function to sort movement providers by order
func sort_by_order(a, b) -> bool:
	return true if a.order < b.order else false


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsPlayerBody"


# Called when the node enters the scene tree for the first time.
func _ready():
	if Engine.is_editor_hint():
		# In editing, keep player body linked to our origin
		set_as_top_level(false)
		transform = Transform3D()
	else:
		# Set as toplevel means our PlayerBody is positioned in global space.
		# It is not moved when its parent moves.
		set_as_top_level(true)
		if get_parent():
			# Make sure we're positioned correctly at the start.
			global_transform = get_parent().global_transform

	# Create our collision shape, height will be updated later
	var capsule = CapsuleShape3D.new()
	capsule.radius = player_radius
	capsule.height = 1.4
	_collision_node = CollisionShape3D.new()
	_collision_node.shape = capsule
	_collision_node.transform.origin = Vector3(0.0, 0.8, 0.0)
	add_child(_collision_node)

	# Create the shape-cast for head collisions
	_head_shape_cast = ShapeCast3D.new()
	_head_shape_cast.enabled = false
	_head_shape_cast.exclude_parent = true
	_head_shape_cast.margin = 0.01
	_head_shape_cast.collision_mask = collision_mask
	_head_shape_cast.max_results = 1
	_head_shape_cast.shape = SphereShape3D.new()
	_head_shape_cast.shape.radius = player_radius
	add_child(_head_shape_cast)

	# Get the movement providers ordered by increasing order
	_movement_providers = get_tree().get_nodes_in_group("movement_providers")
	_movement_providers.sort_custom(sort_by_order)

	# Propagate defaults
	_update_enabled()
	_update_player_radius()


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


func _physics_process(delta: float):
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# If disabled then turn of physics processing and bail out
	if !enabled:
		set_physics_process(false)
		return

	# We're handling physics right now
	_in_physics_movement = true

	# Remember where we are now
	var current_transform : Transform3D = global_transform

	# Calculate the players "up" direction and plane
	up_player = origin_node.global_transform.basis.y

	# Determine environmental gravity
	var gravity_state := PhysicsServer3D.body_get_direct_state(get_rid())
	gravity = gravity_state.total_gravity

	# Update the kinematic body to be under the camera
	_update_body_under_camera(delta)

	# Allow the movement providers a chance to perform pre-movement updates. The providers can:
	# - Adjust the gravity direction
	for p in _movement_providers:
		if p.enabled:
			p.physics_pre_movement(delta, self)

	# Determine the gravity "up" direction and plane
	if gravity.is_equal_approx(Vector3.ZERO):
		# Gravity too weak - use player
		up_gravity = up_player
	else:
		# Use gravity direction
		up_gravity = -gravity.normalized()

	# Update the ground information
	_update_ground_information(delta)

	# Get the player body location before movement occurs
	var position_before_movement := global_transform.origin

	# Run the movement providers in order. The providers can:
	# - Move the kinematic node around (to move the player)
	# - Rotate the XROrigin3D around the camera (to rotate the player)
	# - Read and modify the player velocity
	# - Read and modify the ground-control velocity
	# - Perform exclusive updating of the player (bypassing other movement providers)
	# - Request a jump
	# - Modify gravity direction
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
			velocity += -ground_vector * gravity.length() * delta
		else:
			# Apply gravity
			velocity += gravity * delta
		_apply_velocity_and_control(delta)

	# Apply the player-body movement to the XR origin
	var movement := global_transform.origin - position_before_movement
	origin_node.global_transform.origin += movement

	# Orient the player towards (potentially modified) gravity
	slew_up(-gravity.normalized(), 5.0 * delta)

	# If we moved our player, emit signal
	var delta_transform : Transform3D = global_transform * current_transform.inverse()
	if delta_transform.origin.length() > 0.001:
		player_moved.emit(delta_transform)

	# And we're done!
	_in_physics_movement = false


## Teleport the player body.
## This moves the player without checking for collisions.
func teleport(target : Transform3D) -> void:
	var inv_global_transform : Transform3D = global_transform.inverse()

	# Get the player-to-origin transform
	var player_to_origin : Transform3D = inv_global_transform * origin_node.global_transform

	# Set the player
	global_transform = target

	# Set the origin
	origin_node.global_transform = target * player_to_origin

	# Report the player teleported
	player_teleported.emit(target * inv_global_transform)


## Request a jump
func request_jump(skip_jump_velocity := false):
	# Skip if not on ground
	if !on_ground:
		return

	# Skip if we have any vertical velocity with regards to the ground-plane
	var ground_relative := velocity - ground_velocity
	if abs(ground_relative.dot(ground_vector)) > 0.01:
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


## This method moves the players body using the provided velocity. Movement
## providers may use this function if they are exclusively driving the player.
func move_player(p_velocity: Vector3) -> Vector3:
	velocity = p_velocity
	max_slides = 4
	up_direction = up_gravity

	# Get the player body location before we apply our movement.
	var transform_before_movement : Transform3D = global_transform

	move_and_slide()

	if not _in_physics_movement:
		# Apply the player-body movement to the XR origin
		var movement := global_transform.origin - transform_before_movement.origin
		origin_node.global_transform.origin += movement

		var delta_transform : Transform3D = global_transform * transform_before_movement.inverse()
		if delta_transform.origin.length() >  0.001:
			player_moved.emit(delta_transform)

	# Check if we collided with rigid bodies and apply impulses to them to move them out of the way
	if push_rigid_bodies:
		for idx in range(get_slide_collision_count()):
			var with = get_slide_collision(idx)
			var obj = with.get_collider()

			if obj.is_class("RigidBody3D"):
				var rb : RigidBody3D = obj

				# Get our relative impact velocity
				var impact_velocity = p_velocity - rb.linear_velocity

				# Determine the strength of the impulse we're about to give
				var strength = impact_velocity.dot(-with.get_normal(0)) * push_strength_factor

				# Our impulse is applied in the opposite direction
				# of the normal of the surface we're hitting
				var impulse = -with.get_normal(0) * strength

				# Determine the location at which we're hitting in the object local space
				# but in global orientation
				var pos = with.get_position(0) - rb.global_transform.origin

				# And apply the impulse
				rb.apply_impulse(impulse, pos)

	return velocity

## This method rotates the player by rotating the [XROrigin3D] around the camera.
func rotate_player(angle: float):
	var inv_global_transform : Transform3D = global_transform.inverse()

	var t1 := Transform3D()
	var t2 := Transform3D()
	var rot := Transform3D()

	t1.origin = -camera_node.transform.origin
	t2.origin = camera_node.transform.origin
	rot = rot.rotated(Vector3.DOWN, angle)
	origin_node.transform = (origin_node.transform * t2 * rot * t1).orthonormalized()

	if not _in_physics_movement:
		player_moved.emit(global_transform * inv_global_transform)

## This method slews the players up vector by rotating the [ARVROrigin] around
## the players feet.
func slew_up(up: Vector3, slew: float) -> void:
	# Skip if the up vector is not valid
	if up.is_equal_approx(Vector3.ZERO):
		return

	# Get the current origin
	var current_origin := origin_node.global_transform

	# Save the player foot global and local positions
	var ref_pos_global := global_position
	var ref_pos_local : Vector3 = ref_pos_global * current_origin

	# Calculate the target origin
	var target_origin := current_origin
	target_origin.basis.y = up.normalized()
	target_origin.basis.x = target_origin.basis.y.cross(target_origin.basis.z).normalized()
	target_origin.basis.z = target_origin.basis.x.cross(target_origin.basis.y).normalized()
	target_origin.origin = ref_pos_global - target_origin.basis * ref_pos_local

	# Calculate the new origin
	var new_origin := current_origin.interpolate_with(target_origin, slew).orthonormalized()

	# Update the origin
	origin_node.global_transform = new_origin


## This method calibrates the players height on the assumption
## the player is in rest position
func calibrate_player_height():
	var base_height = camera_node.transform.origin.y + (player_head_height * XRServer.world_scale)
	var player_height = XRToolsUserSettings.player_height * XRServer.world_scale
	player_height_offset = (player_height - base_height) / XRServer.world_scale


## This method sets or clears a named height override
func override_player_height(key, value: float = -1.0):
	# Clear or set the override
	if value < 0.0:
		_player_height_overrides.erase(key)
	else:
		_player_height_overrides[key] = value

	# Evaluate whether a height override is active
	var override = _player_height_overrides.values().min()
	if override != null:
		# Enable override with the target height
		_player_height_override_target = override
		_player_height_override_enabled = true
	else:
		# Disable height override
		_player_height_override_enabled = false


# Estimate body forward direction
func _estimate_body_forward_dir() -> Vector3:
	var forward = Vector3()
	var camera_basis : Basis = camera_node.global_transform.basis
	var camera_forward : Vector3 = -camera_basis.z

	var camera_elevation := camera_forward.dot(up_player)
	if camera_elevation > 0.75:
		# User is looking up
		forward = -camera_basis.y.slide(up_player).normalized()
	elif camera_elevation < -0.75:
		# User is looking down
		forward = camera_basis.y.slide(up_player).normalized()
	else:
		forward = camera_forward.slide(up_player).normalized()

	if (left_hand_node and left_hand_node.get_is_active()
		and right_hand_node and right_hand_node.get_is_active()
		and body_forward_mix > 0.0):
		# See if we can mix in our estimated forward vector based on controller position
		# Note, in Godot 4.0 we should check tracker confidence

		var tangent = right_hand_node.global_transform.origin - left_hand_node.global_transform.origin
		tangent = tangent.slide(up_player).normalized()
		var hands_forward = up_player.cross(tangent).normalized()

		# Rotate our forward towards our hand direction but not more than 60 degrees
		var dot = forward.dot(hands_forward)
		var cross = forward.cross(hands_forward).normalized()
		var angle = clamp(acos(dot) * body_forward_mix, 0.0, 0.33 * PI)
		forward = forward.rotated(cross, angle)

	return forward


# This method updates the player body to match the player position
func _update_body_under_camera(delta : float):
	# Initially calibration of player height
	if player_calibrate_height:
		calibrate_player_height()
		player_calibrate_height = false

	var adj_player_radius = player_radius * XRServer.world_scale
	var adj_player_head_height = player_head_height * XRServer.world_scale

	# Calculate the player height based on the camera position in the origin and the calibration
	var player_height: float = clamp(
			camera_node.transform.origin.y
					+ adj_player_head_height
					+ (player_height_offset * XRServer.world_scale),
			player_height_min * XRServer.world_scale,
			player_height_max * XRServer.world_scale)

	# Manage any player height overriding such as:
	# - Slewing between software override heights
	# - Slewing the lerp between player and software-override heights
	if _player_height_override_enabled:
		# Update the current override height to the target height
		if _player_height_override_lerp <= 0.0:
			# Override not in use, snap to target
			_player_height_override_current = _player_height_override_target
		elif _player_height_override_current < _player_height_override_target:
			# Override in use, slew up to target override height
			_player_height_override_current = min(
				_player_height_override_current + player_height_rate * delta,
				_player_height_override_target)
		elif _player_height_override_current > _player_height_override_target:
			# Override in use, slew down to target override height
			_player_height_override_current = max(
				_player_height_override_current - player_height_rate * delta,
				_player_height_override_target)

		# Slew towards height being controlled by software-override
		_player_height_override_lerp = min(
			_player_height_override_lerp + player_height_rate * delta,
			1.0)
	else:
		# Slew towards height being controlled by player
		_player_height_override_lerp = max(
			_player_height_override_lerp - player_height_rate * delta,
			0.0)

	# Blend the player height between the player and software-override
	player_height = lerp(
		player_height,
		_player_height_override_current,
		_player_height_override_lerp)

	# Ensure player height makes mathematical sense
	player_height = max(player_height, adj_player_radius)

	# Test if the player is trying to get taller
	var current_height : float = _collision_node.shape.height
	if player_height > current_height:
		# Calculate how tall we would like to get this frame
		var target_height : float = min(
			current_height + player_height_rate * delta,
			player_height)

		# Calculate a reduced height - slghtly smaller than the current player
		# height so we can cast a virtual head up and probe the where we hit the
		# ceiling.
		var reduced_height : float = max(
			current_height - 0.1,
			adj_player_radius)

		# Calculate how much we want to grow to hit the target height
		var grow := target_height - reduced_height

		# Cast the virtual head up from the reduced-height position up to the
		# target height to check for ceiling collisions.
		_head_shape_cast.shape.radius = adj_player_radius
		_head_shape_cast.transform.origin.y = reduced_height - adj_player_radius
		_head_shape_cast.collision_mask = collision_mask
		_head_shape_cast.target_position = Vector3.UP * grow
		_head_shape_cast.force_shapecast_update()

		# Use the ceiling collision information to decide how much to grow the
		# player height
		var safe := _head_shape_cast.get_closest_collision_safe_fraction()
		player_height = max(
			reduced_height + grow * safe,
			current_height)

	# Adjust the collision shape to match the player geometry
	_collision_node.shape.radius = adj_player_radius
	_collision_node.shape.height = player_height
	_collision_node.transform.origin.y = (player_height / 2.0)

	# Center the kinematic body on the ground under the camera
	var target_transform := global_transform
	var camera_transform := camera_node.global_transform
	target_transform.basis = origin_node.global_transform.basis
	target_transform.origin = camera_transform.origin
	target_transform.origin += up_player * (adj_player_head_height - player_height)

	# The camera/eyes are towards the front of the body, so move the body back slightly
	var forward_dir := _estimate_body_forward_dir()
	if forward_dir.length() > 0.01:
		target_transform = target_transform.looking_at(target_transform.origin + forward_dir, up_player)
		target_transform.origin -= forward_dir.normalized() * eye_forward_offset * adj_player_radius

	# If head behavior is disabled, just move
	if head_behavior_mode == 2:
		global_transform = target_transform
		return

	# Apply rotation
	global_basis = target_transform.basis

	# Always apply height
	global_position += (target_transform.origin - global_position).project(global_basis.y)

	# But do lateral movement with move and collide
	var body_movement = target_transform.origin - global_position

	var collision : KinematicCollision3D = move_and_collide(body_movement)
	var fade : bool = false
	if collision and collision.get_collision_count() > 0:
		var camera_local_transform = global_transform.inverse() * camera_node.global_transform
		var camera_local_position = camera_local_transform.origin

		# Move it to our head center
		camera_local_position += camera_local_transform.basis.z * eye_forward_offset * adj_player_radius

		# If we can't move here, check if our head can move
		_head_shape_cast.shape.radius = adj_player_head_height
		_head_shape_cast.transform.origin.y = player_height - adj_player_head_height
		_head_shape_cast.collision_mask = collision_mask
		_head_shape_cast.target_position = (camera_local_position - _head_shape_cast.transform.origin) * Vector3(1.0, 0.0, 1.0)

		var target_move_distance = _head_shape_cast.target_position.length()

		# Cast shape
		_head_shape_cast.force_shapecast_update()

		# See how far we can move
		var safe := min(_head_shape_cast.get_closest_collision_safe_fraction(), max_head_distance / target_move_distance)
		if safe < 1.0:
			# print("Attempted to move head from ", _head_shape_cast.transform.origin, " to ", camera_local_position, " => ", _head_shape_cast.target_position, ", safe: ", safe)

			if head_behavior_mode == 0:
				# Push body back, we actually move our player body into the collision,
				# by the amount of movement left after the collision.
				# Then in our actual move and slide we'll get pushed out.
				# Do note that safe isn't super accurate.
				var push_back_by = body_movement * (1.0 - safe)
				global_position += push_back_by
			else:
				# Fade to black
				fade = true

	if fade:
		if not _fade:
			# Use global fade if we have one
			_fade = XRToolsFade.get_fade_node()
			if not _fade:
				# Else create a local instance
				var fade_scene : PackedScene = load("res://addons/godot-xr-tools/effects/fade.tscn")
				_fade = fade_scene.instantiate()
				add_child(_fade, false, Node.INTERNAL_MODE_BACK)

		_fade_value = max(_fade_value + delta * 3.0, 0.0)

		_fade.set_fade_level(self, Color(0, 0, 0, _fade_value))
	elif _fade and _fade_value > 0.0:
		_fade_value = max(_fade_value - delta * 3.0, 0.0)

		_fade.set_fade_level(self, Color(0, 0, 0, _fade_value))


# Called when we're removed from the scene tree
func _exit_tree():
	if _fade:
		# Just in case our fade was global, make sure we clean up.
		_fade.set_fade_level(self, Color(0 ,0 ,0 ,0 ))


# This method updates the information about the ground under the players feet
func _update_ground_information(delta: float):
	# Test how close we are to the ground
	var ground_collision := move_and_collide(
			up_gravity * -NEAR_GROUND_DISTANCE, true)

	# Handle no collision (or too far away to care about)
	if !ground_collision:
		near_ground = false
		on_ground = false
		ground_vector = up_gravity
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
	ground_angle = rad_to_deg(ground_collision.get_angle(0, up_gravity))
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
	var horizontal_velocity := local_velocity.slide(up_gravity)
	var vertical_velocity := local_velocity - horizontal_velocity

	# If the player is on the ground then give them control
	if _can_apply_ground_control() and ground_control_velocity.length() >= 0.1:
		# If ground control is being supplied then update the horizontal velocity
		var control_velocity := Vector3.ZERO
		var camera_transform := camera_node.global_transform
		var dir_forward := camera_transform.basis.z.slide(up_gravity).normalized()
		var dir_right := camera_transform.basis.x.slide(up_gravity).normalized()
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
	if on_ground:
		var current_max_slope := XRToolsGroundPhysicsSettings.get_move_max_slope(
				ground_physics, default_physics)
		if ground_angle > current_max_slope:
			# Get a vector in the down-hill direction
			var down_direction := ground_vector.slide(up_gravity).normalized()
			var vdot: float = down_direction.dot(horizontal_velocity)
			if vdot < 0:
				horizontal_velocity -= down_direction * vdot

	# Combine the velocities back to a 3-space velocity
	local_velocity = horizontal_velocity + vertical_velocity

	# Move the player body with the desired velocity
	velocity = move_player(local_velocity + ground_velocity)

	# Apply ground-friction after the move
	if _can_apply_ground_control() and ground_control_velocity.length() < 0.1:
		# User is not trying to move, so apply the ground drag
		var current_drag := XRToolsGroundPhysicsSettings.get_move_drag(
				ground_physics, default_physics)
		var drag_factor: float = clamp(current_drag * delta, 0, 1)

		# Apply drag to horizontal velocity relative to ground
		local_velocity = velocity - ground_velocity
		horizontal_velocity = local_velocity.slide(up_gravity)
		vertical_velocity = local_velocity - horizontal_velocity
		horizontal_velocity = horizontal_velocity.lerp(Vector3.ZERO, drag_factor)
		velocity = horizontal_velocity + vertical_velocity + ground_velocity

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
			local_velocity += 2 * collision.get_normal() * magnitude * bounciness
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
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check the origin node
	var test_origin_node := XRHelpers.get_xr_origin(self)
	if !test_origin_node:
		warnings.append("Unable to find XR Origin node")

	# Check the camera node
	var test_camera_node := XRHelpers.get_xr_camera(self)
	if !test_camera_node:
		warnings.append("Unable to find XR Camera node")

	# Verify the player radius is valid
	if player_radius <= 0:
		warnings.append("Player radius must be configured")

	# Verify the player height minimum is valid
	if player_height_min < player_radius * 2.0:
		warnings.append("Player height minimum smaller than 2x radius")

	# Verify the player height maximum is valid
	if player_height_max < player_height_min:
		warnings.append("Player height maximum cannot be smaller than minimum")

	if head_behavior_mode == 1 and player_radius <= player_head_height:
		warnings.append("When using fade mode, player radius should be larger than head height")

	# Verify eye-forward does not allow near-clip-plane look through
	var eyes_to_collider = (1.0 - eye_forward_offset) * player_radius
	if test_camera_node and eyes_to_collider < test_camera_node.near:
		warnings.append(
				"Eyes too far forwards. Move eyes back or decrease camera near clipping plane")

	# If specified, verify the ground physics is a valid type
	if physics and !physics is XRToolsGroundPhysicsSettings:
		warnings.append("Physics resource must be a GroundPhysicsSettings")

	# Return warnings
	return warnings


# Check property config
func _validate_property(property):
	if property.name == "position" or property.name == "rotation" or property.name == "scale" \
		or property.name == "rotation_edit_mode" or property.name == "rotation_order" \
		or property.name == "top_level":
		# We control these, don't let the user set them.
		property.usage = PROPERTY_USAGE_NONE


## Find an [XRToolsPlayerBody] node.
##
## This function searches from the specified node for an [XRToolsPlayerBody]
## assuming the node is a sibling of the body under an [XROrigin3D].
static func find_instance(node: Node) -> XRToolsPlayerBody:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_origin(node),
		"*",
		"XRToolsPlayerBody") as XRToolsPlayerBody
