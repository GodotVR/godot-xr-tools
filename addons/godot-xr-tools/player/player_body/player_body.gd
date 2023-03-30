@tool
@icon("res://addons/godot-xr-tools/editor/icons/body.svg")
class_name XRToolsPlayerBody
extends XRToolsBodyBase


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


## Radius of the player body collider
@export var player_radius : float = 0.2: set = set_player_radius

## Player head height (distance between between camera and top of head)
@export var player_head_height : float = 0.1

## Minimum player height
@export var player_height_min : float = 0.6

## Maximum player height
@export var player_height_max : float = 2.2

## Eyes forward offset from center of body in player_radius units
@export_range(0.0, 1.0) var eye_forward_offset : float = 0.5

## Mix factor for body orientation
@export_range(0.0, 1.0) var body_forward_mix : float = 0.75

## Lets the player push rigid bodies
@export var push_rigid_bodies : bool = true


## Player 3D Velocity - modified by [XRToolsMovementProvider] nodes
#var velocity : Vector3 = Vector3.ZERO

# Player body Collision node
var _collision_node : CollisionShape3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPlayerBody"


# Called when the node enters the scene tree for the first time.
func _ready():
	super()

	# Set as toplevel means our PlayerBody is positioned in global space.
	# It is not moved when its parent moves.
	set_as_top_level(true)

	# Create our collision shape, height will be updated later
	var capsule = CapsuleShape3D.new()
	capsule.radius = player_radius
	capsule.height = 1.4
	_collision_node = CollisionShape3D.new()
	_collision_node.shape = capsule
	_collision_node.transform.origin = Vector3(0.0, 0.8, 0.0)
	add_child(_collision_node)

	# Propagate defaults
	_update_player_radius()

func _update_enabled() -> void:
	# Update collision_shape
	if _collision_node:
		_collision_node.disabled = !enabled

	super()

func set_player_radius(new_value: float) -> void:
	player_radius = new_value
	if is_inside_tree():
		_update_player_radius()

func _update_player_radius() -> void:
	if _collision_node and _collision_node.shape:
		_collision_node.shape.radius = player_radius

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

	# Calculate the players "up" direction and plane
	up_player_vector = origin_node.global_transform.basis.y
	up_player_plane = Plane(up_player_vector, 0.0)

	# Determine environmental gravity
	var gravity_state := PhysicsServer3D.body_get_direct_state(get_rid())
	gravity = gravity_state.total_gravity

	# Update the kinematic body to be under the camera
	_update_body_under_camera()

	# Allow the movement providers a chance to perform pre-movement updates. The providers can:
	# - Adjust the gravity direction
	for p in _movement_providers:
		if p.enabled:
			p.physics_pre_movement(delta, self)

	# Determine the gravity "up" direction and plane
	if gravity.is_equal_approx(Vector3.ZERO):
		# Gravity too weak - use player
		up_gravity_vector = up_player_vector
		up_gravity_plane = up_player_plane
	else:
		# Use gravity direction
		up_gravity_vector = -gravity.normalized()
		up_gravity_plane = Plane(up_gravity_vector, 0.0)

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




## This method rotates the player by rotating the [XROrigin3D] around the camera.
func rotate_player(angle: float):
	var t1 := Transform3D()
	var t2 := Transform3D()
	var rot := Transform3D()

	t1.origin = -camera_node.transform.origin
	t2.origin = camera_node.transform.origin
	rot = rot.rotated(Vector3.DOWN, angle)
	origin_node.transform = (origin_node.transform * t2 * rot * t1).orthonormalized()

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

# Estimate body forward direction
func _estimate_body_forward_dir() -> Vector3:
	var forward = Vector3()
	var camera_basis : Basis = camera_node.global_transform.basis
	var camera_forward : Vector3 = -camera_basis.z;

	var camera_elevation := camera_forward.dot(up_player_vector)
	if camera_elevation > 0.75:
		# User is looking up
		forward = up_player_plane.project(-camera_basis.y).normalized()
	elif camera_elevation < -0.75:
		# User is looking down
		forward = up_player_plane.project(camera_basis.y).normalized()
	else:
		forward = up_player_plane.project(camera_forward).normalized()

	if (left_hand_node and left_hand_node.get_is_active()
		and right_hand_node and right_hand_node.get_is_active()
		and body_forward_mix > 0.0):
		# See if we can mix in our estimated forward vector based on controller position
		# Note, in Godot 4.0 we should check tracker confidence

		var tangent = right_hand_node.global_transform.origin - left_hand_node.global_transform.origin
		tangent = up_player_plane.project(tangent).normalized()
		var hands_forward = up_player_vector.cross(tangent).normalized()

		# Rotate our forward towards our hand direction but not more than 60 degrees
		var dot = forward.dot(hands_forward)
		var cross = forward.cross(hands_forward).normalized()
		var angle = clamp(acos(dot) * body_forward_mix, 0.0, 0.33 * PI)
		forward = forward.rotated(cross, angle)

	return forward

# This method updates the player body to match the player position
func _update_body_under_camera():
	# Calculate the player height based on the camera position in the origin and the calibration
	var player_height: float = clamp(
			camera_node.transform.origin.y + player_head_height +
					player_height_offset + XRToolsUserSettings.player_height_adjust,
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
	var curr_transform := global_transform
	var camera_transform := camera_node.global_transform
	curr_transform.basis = origin_node.global_transform.basis
	curr_transform.origin = camera_transform.origin
	curr_transform.origin += up_player_vector * (player_head_height - player_height)

	# The camera/eyes are towards the front of the body, so move the body back slightly
	var forward_dir := _estimate_body_forward_dir()
	if forward_dir.length() > 0.01:
		curr_transform = curr_transform.looking_at(curr_transform.origin + forward_dir, up_player_vector)
		curr_transform.origin -= forward_dir.normalized() * eye_forward_offset * player_radius

	# Set the body position
	global_transform = curr_transform

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

## Find an [XRToolsPlayerBody] node.
##
## This function searches from the specified node for an [XRToolsPlayerBody]
## assuming the node is a sibling of the body under an [XROrigin3D].
static func find_instance(node: Node) -> XRToolsPlayerBody:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_origin(node),
		"*",
		"XRToolsPlayerBody") as XRToolsPlayerBody
