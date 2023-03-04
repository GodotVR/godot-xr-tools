@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionTeleport
extends CharacterBody3D

# should really change this to Node3D once #17401 is resolved


## XR Tools Function Teleport Script
##
## This script provides teleport functionality.
##
## Add this scene as a sub scene of your ARVRController node to implement
## a teleport function on that controller.


# Default teleport collision mask of all
const DEFAULT_MASK := 0b1111_1111_1111_1111_1111_1111_1111_1111


## If true, teleporting is enabled
@export var enabled : bool = true: set = set_enabled

## Teleport allowed color property
@export var can_teleport_color : Color = Color(0.0, 1.0, 0.0, 1.0)

## Teleport denied color property
@export var cant_teleport_color : Color = Color(1.0, 0.0, 0.0, 1.0)

## Teleport no-collision color property
@export var no_collision_color : Color = Color(45.0 / 255.0, 80.0 / 255.0, 220.0 / 255.0, 1.0)

## Player height property
@export var player_height : float = 1.8: set = set_player_height

## Player radius property
@export var player_radius : float = 0.4: set = set_player_radius

## Teleport-arc strength
@export var strength : float = 5.0

## Maximum floor slope
@export var max_slope : float = 20.0

## Valid teleport layer mask
@export_flags_3d_physics var valid_teleport_mask : int = DEFAULT_MASK

# once this is no longer a kinematic body, we'll need this..
# export (int, LAYERS_3D_PHYSICS) var collision_mask = 1

## Teleport button action
@export var teleport_button_action : String = "trigger_click"

## Teleport rotation action
@export var rotation_action : String = "primary"


var is_on_floor : bool = true
var is_teleporting : bool = false
var can_teleport : bool = true
var teleport_rotation : float = 0.0;
var floor_normal : Vector3 = Vector3.UP
var last_target_transform : Transform3D = Transform3D()
var collision_shape : Shape3D
var step_size : float = 0.5


# World scale
@onready var ws : float = XRServer.world_scale

# By default we show a capsule to indicate where the player lands.
# Turn on editable children,
# hide the capsule,
# and add your own player character as child.
@onready var capsule : MeshInstance3D = get_node("Target/Player_figure/Capsule")

## [XROrigin3D] node.
@onready var origin_node := XRHelpers.get_xr_origin(self)

## [XRCamera3D] node.
@onready var camera_node := XRHelpers.get_xr_camera(self)

## [XRController3D] node.
@onready var controller := XRHelpers.get_xr_controller(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsFunctionTeleport"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# It's inactive when we start
	$Teleport.visible = false
	$Target.visible = false

	# Scale to our world scale
	$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
	$Target.mesh.size = Vector2(ws, ws)
	$Target/Player_figure.scale = Vector3(ws, ws, ws)

	# get our capsule shape
	collision_shape = $CollisionShape3D.shape
	$CollisionShape3D.shape = null

	# now remove our collision shape, we are not using our kinematic body
	remove_child($CollisionShape3D)

	# call set player to ensure our collision shape is sized
	_update_player_height()
	_update_player_radius()


func _physics_process(delta):
	# Do not process physics if in the editor
	if Engine.is_editor_hint():
		return

	# Skip if required nodes are missing
	if !origin_node or !camera_node or !controller:
		return

	# if we're not enabled no point in doing mode
	if !enabled:
		# reset these
		is_teleporting = false;
		$Teleport.visible = false
		$Target.visible = false

		# and stop this from running until we enable again
		set_physics_process(false)
		return

	# check if our world scale has changed..
	var new_ws = XRServer.world_scale
	if ws != new_ws:
		ws = new_ws
		$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
		$Target.mesh.size = Vector2(ws, ws)
		$Target/Player_figure.scale = Vector3(ws, ws, ws)

	if controller and controller.get_is_active() and \
			controller.is_button_pressed(teleport_button_action):
		if !is_teleporting:
			is_teleporting = true
			$Teleport.visible = true
			$Target.visible = true
			teleport_rotation = 0.0

		# get our physics engine state
		var space = PhysicsServer3D.body_get_space(self.get_rid())
		var state = PhysicsServer3D.space_get_direct_state(space)
		var query = PhysicsShapeQueryParameters3D.new()

		# init stuff about our query that doesn't change
		query.collision_mask = collision_mask
		query.margin = get_safe_margin()
		query.shape_rid = collision_shape.get_rid()

		# make a transform for offsetting our shape, it's always
		# lying on its side by default...
		var shape_transform = Transform3D(
				Basis(),
				Vector3(0.0, player_height / 2.0, 0.0))

		# update location
		var teleport_global_transform = $Teleport.global_transform
		var target_global_origin = teleport_global_transform.origin
		var down = Vector3(0.0, -1.0 / ws, 0.0)

		############################################################
		# New teleport logic
		# We're going to use test move in steps to find out where we hit something...
		# This can be optimised loads by determining the lenght based on the angle
		# between sections extending the length when we're in a flat part of the arch
		# Where we do get a collission we may want to fine tune the collision
		var cast_length = 0.0
		var fine_tune = 1.0
		var hit_something = false
		var max_slope_cos = cos(deg_to_rad(max_slope))
		for i in range(1,26):
			var new_cast_length = cast_length + (step_size / fine_tune)
			var global_target = Vector3(0.0, 0.0, -new_cast_length)

			# our quadratic values
			var t = global_target.z / strength
			var t2 = t * t

			# target to world space
			global_target = teleport_global_transform * global_target

			# adjust for gravity
			global_target += down * t2

			# test our new location for collisions
			query.transform = Transform3D(Basis(), global_target) * shape_transform
			var cast_result = state.collide_shape(query, 10)
			if cast_result.is_empty():
				# we didn't collide with anything so check our next section...
				cast_length = new_cast_length
				target_global_origin = global_target
			elif (fine_tune <= 16.0):
				# try again with a small step size
				fine_tune *= 2.0
			else:
				# if we don't collide make sure we keep using our current origin point
				var collided_at = target_global_origin

				# check for collision
				if global_target.y > target_global_origin.y:
					# if we're moving up, we hit the ceiling of something, we
					# don't really care what
					is_on_floor = false
				else:
					# now we cast a ray downwards to see if we're on a surface
					var ray_query = PhysicsRayQueryParameters3D.new()
					ray_query.from = target_global_origin + (Vector3.UP * 0.5 * player_height)
					ray_query.to = target_global_origin - (Vector3.UP * 1.1 * player_height)
					ray_query.collision_mask = collision_mask

					var intersects = state.intersect_ray(ray_query)
					if intersects.is_empty():
						is_on_floor = false
					else:
						# did we collide with a floor or a wall?
						floor_normal = intersects["normal"]
						var dot = floor_normal.dot(Vector3.UP)

						if dot > max_slope_cos:
							is_on_floor = true
						else:
							is_on_floor = false

						# Update our collision point if it's moved enough, this
						# solves a little bit of jittering
						var diff = collided_at - intersects["position"]

						if diff.length() > 0.1:
							collided_at = intersects["position"]

						# Fail if the hit target isn't in our valid mask
						var collider_mask = intersects["collider"].collision_layer
						if not valid_teleport_mask & collider_mask:
							is_on_floor = false

				# we are colliding, find our if we're colliding on a wall or
				# floor, one we can do, the other nope...
				cast_length += (collided_at - target_global_origin).length()
				target_global_origin = collided_at
				hit_something = true
				break

		# and just update our shader
		$Teleport.get_surface_override_material(0).set_shader_parameter("scale_t", 1.0 / strength)
		$Teleport.get_surface_override_material(0).set_shader_parameter("ws", ws)
		$Teleport.get_surface_override_material(0).set_shader_parameter("length", cast_length)
		if hit_something:
			var color = can_teleport_color
			var normal = Vector3.UP
			if is_on_floor:
				# if we're on the floor we'll reorientate our target to match.
				normal = floor_normal
				can_teleport = true
			else:
				can_teleport = false
				color = cant_teleport_color

			# check our axis to see if we need to rotate
			teleport_rotation += (delta * controller.get_vector2(rotation_action).x * -4.0)

			# update target and colour
			var target_basis = Basis()
			target_basis.z = Vector3(
					teleport_global_transform.basis.z.x,
					0.0,
					teleport_global_transform.basis.z.z).normalized()
			target_basis.y = normal
			target_basis.x = target_basis.y.cross(target_basis.z)
			target_basis.z = target_basis.x.cross(target_basis.y)

			target_basis = target_basis.rotated(normal, teleport_rotation)
			last_target_transform.basis = target_basis
			last_target_transform.origin = target_global_origin + Vector3(0.0, 0.001, 0.0)
			$Target.global_transform = last_target_transform

			$Teleport.get_surface_override_material(0).set_shader_parameter("mix_color", color)
			$Target.get_surface_override_material(0).albedo_color = color
			$Target.visible = can_teleport
		else:
			can_teleport = false
			$Target.visible = false
			$Teleport.get_surface_override_material(0).set_shader_parameter("mix_color", no_collision_color)
	elif is_teleporting:
		if can_teleport:

			# make our target horizontal again
			var new_transform = last_target_transform
			new_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			new_transform.basis.x = new_transform.basis.y.cross(new_transform.basis.z).normalized()
			new_transform.basis.z = new_transform.basis.x.cross(new_transform.basis.y).normalized()

			# Find out our user's feet's transformation.
			# The feet are on the ground, but have the same X,Z as the camera
			var cam_transform = camera_node.transform
			var user_feet_transform = Transform3D()
			user_feet_transform.origin = cam_transform.origin
			user_feet_transform.origin.y = 0

			# ensure this transform is upright
			user_feet_transform.basis.y = Vector3(0.0, 1.0, 0.0)
			user_feet_transform.basis.x = user_feet_transform.basis.y.cross(
					cam_transform.basis.z).normalized()
			user_feet_transform.basis.z = user_feet_transform.basis.x.cross(
					user_feet_transform.basis.y).normalized()

			# now move the origin such that the new global user_feet_transform
			# would be == new_transform
			origin_node.global_transform = new_transform * user_feet_transform.inverse()

		# and disable
		is_teleporting = false;
		$Teleport.visible = false
		$Target.visible = false


# This method verifies the teleport has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify we can find the XROrigin3D
	if !XRHelpers.get_xr_origin(self):
		warnings.append("This node must be within a branch of an XROrigin3D node")

	# Verify we can find the XRCamera3D
	if !XRHelpers.get_xr_camera(self):
		warnings.append("Unable to find XRCamera3D node")

	# Verify we can find the XRController3D
	if !XRHelpers.get_xr_controller(self):
		warnings.append("This node must be within a branch of an XRController3D node")

	# Return warnings
	return warnings


# Set enabled property
func set_enabled(new_value : bool) -> void:
	enabled = new_value
	if enabled:
		# make sure our physics process is on
		set_physics_process(true)
	else:
		# we turn this off in physics process just in case we want to do some cleanup
		pass


# Set player height property
func set_player_height(p_height : float) -> void:
	player_height = p_height
	_update_player_height()


# Set player radius property
func set_player_radius(p_radius : float) -> void:
	player_radius = p_radius
	_update_player_radius()


# Player height update handler
func _update_player_height() -> void:
	if collision_shape:
		collision_shape.height = player_height - (2.0 * player_radius)

	if capsule:
		capsule.mesh.height = player_height
		capsule.position = Vector3(0.0, player_height/2.0, 0.0)


# Player radius update handler
func _update_player_radius():
	if collision_shape:
		collision_shape.height = player_height
		collision_shape.radius = player_radius

	if capsule:
		capsule.mesh.height = player_height
		capsule.mesh.radius = player_radius
