@tool
@icon("res://addons/godot-xr-tools/editor/icons/body.svg")
class_name XRToolsCharacterBody
extends XRToolsBodyBase

## XR Tools character body center player body implemention
##
## This node implements a newer version on the player body logic.
##
## In this approach the character body is our root node and
## the player can be moved through user input much like in a
## non-VR game.

## Helper variables to keep our code readable
@onready var _collision_node = $CollisionShape3D
@onready var _neck_position_node = $XROrigin3D/XRCamera3D/NeckJoint

## Fade distance
var player_fade_distance_start = 0.01
var player_fade_distance_max = 0.05

## Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsCharacterBody"

func _update_enabled() -> void:
	# Update collision_shape
	if _collision_node:
		_collision_node.disabled = !enabled

	super()

## Teleports the player to this location
func center_player_on(p_global_transform : Transform3D):
	# Note that we use the up of this transform as our player up
	up_player_vector = p_global_transform.basis.y
	up_player_plane = Plane(up_player_vector, 0.0)

	# Use our neck joint to center our player
	var t : Transform3D = _neck_position_node.global_transform * global_transform.inverse()

	# Remove height
	t.origin.y = 0.0

	# Remove tilt
	var forward : Vector3 = -t.basis.z
	var elevation : float = -forward.dot(up_player_vector)
	if elevation > 0.75:
		# User is looking up
		forward = up_player_plane.project(-t.basis.y).normalized()
	elif elevation < -0.75:
		# User is looking down
		forward = up_player_plane.project(t.basis.y).normalized()
	else:
		forward = up_player_plane.project(forward).normalized()

	t = t.looking_at(t.origin + forward, up_player_vector)

	# Apply inverse to origin
	origin_node.transform = t.affine_inverse()

	# Finally place our character body at the transform
	global_transform = p_global_transform

# Called when the node enters the scene tree for the first time.
func _ready():
	super()

## Attempt to move the character body to the players physical position
func _process_on_physical_movement(delta) -> bool:
	# Remember our current velocity, we'll apply that later
	var current_velocity = velocity

	# Start by rotating the player to face the same way our real player is
	var camera_basis: Basis = origin_node.transform.basis * camera_node.transform.basis
	var forward: Vector2 = Vector2(camera_basis.z.x, camera_basis.z.z)
	var angle: float = forward.angle_to(Vector2(0.0, 1.0))

	# Rotate our character body
	transform.basis = transform.basis.rotated(Vector3.UP, angle)

	# Reverse this rotation our origin node
	origin_node.transform = Transform3D().rotated(Vector3.UP, -angle) * origin_node.transform

	# Now apply movement, first move our player body to the right location
	var org_player_body: Vector3 = global_transform.origin
	var player_body_location: Vector3 = origin_node.transform * camera_node.transform * _neck_position_node.transform.origin
	player_body_location.y = 0.0
	player_body_location = global_transform * player_body_location

	velocity = (player_body_location - org_player_body) / delta
	move_and_slide()

	# Now move our XROrigin back
	var delta_movement = global_transform.origin - org_player_body
	origin_node.global_transform.origin -= delta_movement

	# Return our value
	velocity = current_velocity

	var distance_from_player_location : float = (player_body_location - global_transform.origin).length()
	if distance_from_player_location > player_fade_distance_start:
		## TODO black out screen

		return distance_from_player_location > player_fade_distance_max
	else:
		return false

func _update_ground_information(delta):
	pass

func _apply_velocity_and_control(delta):
	pass

func _physics_process(delta):
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# If disabled then turn of physics processing and bail out
	if !enabled:
		set_physics_process(false)
		return

	if _jump_cooldown:
		_jump_cooldown -= 1

	# Calculate the players "up" direction and plane
	up_player_vector = global_transform.basis.y
	up_player_plane = Plane(up_player_vector, 0.0)

	# Determine environmental gravity
	var gravity_state := PhysicsServer3D.body_get_direct_state(get_rid())
	gravity = gravity_state.total_gravity

	# TODO Adjust collision shape based on player position

	# Reposition player body based on physical movement
	var is_colliding = _process_on_physical_movement(delta)
	if is_colliding:
		# If we couldn't move the player properly we don't want
		# to process controller input but we do want to apply our
		# current velocity...
		
		# TODO implement velocity
		pass
	else:
		# Handle further movement input

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
			if on_ground and ground_physics and ground_physics.stop_on_slope and ground_angle < ground_physics.move_max_slope:
				# Apply gravity towards slope to prevent sliding
				velocity += -ground_vector * gravity.length() * delta
			else:
				# Apply gravity
				velocity += gravity * delta
			_apply_velocity_and_control(delta)

		# Orient the player towards (potentially modified) gravity
		# slew_up(-gravity.normalized(), 5.0 * delta)

## Find an [XRToolsCharacterBody] node.
##
## This function searches from the specified node for an [XRToolsCharacterBody]
## assuming the node is the parent of the body under an [XROrigin3D].
static func find_instance(node: Node) -> XRToolsCharacterBody:
	var xr_origin = XRHelpers.get_xr_origin(node)
	if xr_origin:
		var character_body : XRToolsCharacterBody = xr_origin.get_parent()
		return character_body
	else:
		return null
