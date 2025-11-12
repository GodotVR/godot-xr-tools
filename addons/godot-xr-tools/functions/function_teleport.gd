@tool
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")
class_name XRToolsFunctionTeleport
extends XRToolsHandPalmOffset


## XR Tools Function Teleport Script
##
## This script provides teleport functionality.
##
## Add this scene as a sub scene of your [XRController3D] node to implement
## a teleport function on that controller.


# Default teleport collision mask of all
const DEFAULT_MASK := 0b1111_1111_1111_1111_1111_1111_1111_1111

# Default material
# gdlint:ignore = load-constant-name
const _DefaultMaterial := preload("res://addons/godot-xr-tools/materials/capsule.tres")


## If true, teleporting is enabled
@export var enabled : bool = true: set = set_enabled

## Teleport button action
@export var teleport_button_action : String = "trigger_click"

## Teleport rotation action
@export var rotation_action : String = "primary"

# Teleport Path Group
@export_group("Visuals")

## Teleport allowed color property
@export var can_teleport_color : Color = Color(0.0, 1.0, 0.0, 1.0)

## Teleport denied color property
@export var cant_teleport_color : Color = Color(1.0, 0.0, 0.0, 1.0)

## Teleport no-collision color property
@export var no_collision_color : Color = Color(45.0 / 255.0, 80.0 / 255.0, 220.0 / 255.0, 1.0)

## Teleport-arc strength
@export var strength : float = 5.0

## Teleport texture
@export var arc_texture : Texture2D \
	= preload("res://addons/godot-xr-tools/images/teleport_arrow.png") \
	: set = set_arc_texture

## Target texture
@export var target_texture : Texture2D \
	= preload("res://addons/godot-xr-tools/images/teleport_target.png") \
	: set = set_target_texture

# Player Group
@export_group("Player")

## Player height property
@export var player_height : float = 1.8: set = set_player_height

## Player radius property
@export var player_radius : float = 0.4: set = set_player_radius

## Player scene
@export var player_scene : PackedScene: set = set_player_scene

# Target Group
@export_group("Collision")

## Maximum floor slope
@export var max_slope : float = 20.0

## Collision mask
@export_flags_3d_physics var collision_mask : int = 1023

## Valid teleport layer mask
@export_flags_3d_physics var valid_teleport_mask : int = DEFAULT_MASK


## Player capsule material (ignored for custom player scenes)
var player_material : StandardMaterial3D = _DefaultMaterial :  set = set_player_material


var is_on_floor : bool = true
var is_teleporting : bool = false
var can_teleport : bool = true
var teleport_rotation : float = 0.0
var floor_normal : Vector3 = Vector3.UP
var last_target_transform : Transform3D = Transform3D()
var collision_shape : Shape3D
var step_size : float = 0.5


# Custom player scene
var player : Node3D


# World scale
@onready var ws : float = XRServer.world_scale

## Capsule shown when not using a custom player mesh
@onready var capsule : MeshInstance3D = $Target/Player_figure/Capsule

## [XRToolsPlayerBody] node.
@onready var player_body := XRToolsPlayerBody.find_instance(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsFunctionTeleport"


func _enter_tree():
	var bt:= Transform3D()
	bt.origin = Vector3(0.0, 0.0, -0.1)
	set_base_transform(bt)

	super._enter_tree()

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
	collision_shape = CapsuleShape3D.new()

	# Apply properties
	_update_arc_texture()
	_update_target_texture()
	_update_player_scene()
	_update_player_height()
	_update_player_radius()
	_update_player_material()


func _physics_process(delta):
	# Do not process physics if in the editor
	if Engine.is_editor_hint():
		return

	# Skip if required nodes are missing
	if !player_body or !_controller:
		return

	# if we're not enabled no point in doing mode
	if !enabled:
		# reset these
		is_teleporting = false
		$Teleport.visible = false
		$Target.visible = false

		# and stop this from running until we enable again
		set_physics_process(false)
		return

	# check if our world scale has changed..
	var new_ws := XRServer.world_scale
	if ws != new_ws:
		ws = new_ws
		$Teleport.mesh.size = Vector2(0.05 * ws, 1.0)
		$Target.mesh.size = Vector2(ws, ws)
		$Target/Player_figure.scale = Vector3(ws, ws, ws)

	if _controller and _controller.get_is_active() and \
			_controller.is_button_pressed(teleport_button_action):
		if !is_teleporting:
			is_teleporting = true
			$Teleport.visible = true
			$Target.visible = true
			teleport_rotation = 0.0

		# get our physics engine state
		var state := get_world_3d().direct_space_state
		var query := PhysicsShapeQueryParameters3D.new()

		# init stuff about our query that doesn't change
		query.collision_mask = collision_mask
		query.margin = collision_shape.margin
		query.shape_rid = collision_shape.get_rid()

		# make a transform for offsetting our shape, it's always
		# lying on its side by default...
		var shape_transform := Transform3D(
				Basis(),
				Vector3(0.0, player_height / 2.0, 0.0))

		# update location
		var teleport_global_transform : Transform3D = $Teleport.global_transform
		var target_global_origin := teleport_global_transform.origin
		var up := player_body.up_player
		var down := -up.normalized() / ws

		############################################################
		# New teleport logic
		# We're going to use test move in steps to find out where we hit something...
		# This can be optimised loads by determining the lenght based on the angle
		# between sections extending the length when we're in a flat part of the arch
		# Where we do get a collission we may want to fine tune the collision
		var cast_length := 0.0
		var fine_tune := 1.0
		var hit_something := false
		var max_slope_cos := cos(deg_to_rad(max_slope))
		for i in range(1,26):
			var new_cast_length := cast_length + (step_size / fine_tune)
			var global_target := Vector3(0.0, 0.0, -new_cast_length)

			# our quadratic values
			var t := global_target.z / strength
			var t2 := t * t

			# target to world space
			global_target = teleport_global_transform * global_target

			# adjust for gravity
			global_target += down * t2

			# test our new location for collisions
			query.transform = Transform3D(
				player_body.global_transform.basis,
				global_target) * shape_transform
			var cast_result := state.collide_shape(query, 10)
			if cast_result.is_empty():
				# we didn't collide with anything so check our next section...
				cast_length = new_cast_length
				target_global_origin = global_target
			elif (fine_tune <= 16.0):
				# try again with a small step size
				fine_tune *= 2.0
			else:
				# if we don't collide make sure we keep using our current origin point
				var collided_at := target_global_origin

				# check for collision
				var step_delta := global_target - target_global_origin
				if up.dot(step_delta) > 0:
					# if we're moving up, we hit the ceiling of something, we
					# don't really care what
					is_on_floor = false
				else:
					# now we cast a ray downwards to see if we're on a surface
					var ray_query := PhysicsRayQueryParameters3D.new()
					ray_query.from = target_global_origin + (up * 0.5 * player_height)
					ray_query.to = target_global_origin - (up * 1.1 * player_height)
					ray_query.collision_mask = collision_mask

					var intersects := state.intersect_ray(ray_query)
					if intersects.is_empty():
						is_on_floor = false
					else:
						# did we collide with a floor or a wall?
						floor_normal = intersects["normal"]
						var dot := up.dot(floor_normal)

						if dot > max_slope_cos:
							is_on_floor = true
						else:
							is_on_floor = false

						# Update our collision point if it's moved enough, this
						# solves a little bit of jittering
						var diff : Vector3 = collided_at - intersects["position"]

						if diff.length() > 0.1:
							collided_at = intersects["position"]

						# Fail if the hit target isn't in our valid mask
						var collider_mask : int = intersects["collider"].collision_layer
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
		$Teleport.get_surface_override_material(0).set_shader_parameter("down", down)
		$Teleport.get_surface_override_material(0).set_shader_parameter("length", cast_length)
		if hit_something:
			var color := can_teleport_color
			var normal := up
			if is_on_floor:
				# if we're on the floor we'll reorientate our target to match.
				normal = floor_normal
				can_teleport = true
			else:
				can_teleport = false
				color = cant_teleport_color

			# check our axis to see if we need to rotate
			teleport_rotation += (delta * _controller.get_vector2(rotation_action).x * -4.0)

			# update target and colour
			var target_basis := Basis()
			target_basis.y = normal
			target_basis.x = teleport_global_transform.basis.x.slide(normal).normalized()
			target_basis.z = target_basis.x.cross(target_basis.y)

			target_basis = target_basis.rotated(normal, teleport_rotation)
			last_target_transform.basis = target_basis
			last_target_transform.origin = target_global_origin + up * 0.001
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

			# Make our target using the players up vector
			var new_transform := last_target_transform
			new_transform.basis.y = player_body.up_player
			new_transform.basis.x = new_transform.basis.y.cross(new_transform.basis.z).normalized()
			new_transform.basis.z = new_transform.basis.x.cross(new_transform.basis.y).normalized()

			# Teleport the player
			player_body.teleport(new_transform)

		# and disable
		is_teleporting = false
		$Teleport.visible = false
		$Target.visible = false


# This method verifies the teleport has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings : PackedStringArray = super._get_configuration_warnings()

	# Verify we can find the XRToolsPlayerBody
	if !XRToolsPlayerBody.find_instance(self):
		warnings.append("This node must be within a branch of an XRToolsPlayerBody node")

	# Return warnings
	return warnings


# Provide custom property information
func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name" : "Player",
			"type" : TYPE_NIL,
			"usage" : PROPERTY_USAGE_GROUP
		},
		{
			"name" : "player_material",
			"class_name" : "StandardMaterial3D",
			"type" : TYPE_OBJECT,
			"usage" : PROPERTY_USAGE_NO_EDITOR if player_scene else PROPERTY_USAGE_DEFAULT,
			"hint" : PROPERTY_HINT_RESOURCE_TYPE,
			"hint_string" : "StandardMaterial3D"
		}
	]


# Allow revert of custom properties
func _property_can_revert(property : StringName) -> bool:
	return property == "player_material"


# Provide revert values for custom properties
func _property_get_revert(property : StringName): # Variant
	if property == "player_material":
		return _DefaultMaterial


# Set enabled property
func set_enabled(new_value : bool) -> void:
	enabled = new_value
	if enabled:
		# make sure our physics process is on
		set_physics_process(true)
	else:
		# we turn this off in physics process just in case we want to do some cleanup
		pass


# Set the arc texture
func set_arc_texture(p_arc_texture : Texture2D) -> void:
	arc_texture = p_arc_texture
	if is_inside_tree():
		_update_arc_texture()


# Set the target texture
func set_target_texture(p_target_texture : Texture2D) -> void:
	target_texture = p_target_texture
	if is_inside_tree():
		_update_target_texture()


# Set player height property
func set_player_height(p_height : float) -> void:
	player_height = p_height
	if is_inside_tree():
		_update_player_height()


# Set player radius property
func set_player_radius(p_radius : float) -> void:
	player_radius = p_radius
	if is_inside_tree():
		_update_player_radius()


# Set the player scene
func set_player_scene(p_player_scene : PackedScene) -> void:
	player_scene = p_player_scene
	notify_property_list_changed()
	if is_inside_tree():
		_update_player_scene()


# Set the player material
func set_player_material(p_player_material : StandardMaterial3D) -> void:
	player_material = p_player_material
	if is_inside_tree():
		_update_player_material()


# Update arc texture
func _update_arc_texture():
	var material : ShaderMaterial = $Teleport.get_surface_override_material(0)
	if material and arc_texture:
		material.set_shader_parameter("arrow_texture", arc_texture)


# Update target texture
func _update_target_texture():
	var material : StandardMaterial3D = $Target.get_surface_override_material(0)
	if material and target_texture:
		material.albedo_texture = target_texture


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


# Update the player scene
func _update_player_scene() -> void:
	# Free the current player
	if player:
		player.queue_free()
		player = null

	# If specified, instantiate a new player
	if player_scene:
		player = player_scene.instantiate()
		$Target/Player_figure.add_child(player)

	# Show the capsule mesh only if we have no player
	capsule.visible = player == null


# Update player material
func _update_player_material():
	if player_material:
		capsule.set_surface_override_material(0, player_material)
