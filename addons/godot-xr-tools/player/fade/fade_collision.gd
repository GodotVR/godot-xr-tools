@tool
class_name XRToolsFadeCollision
extends Node3D


## Layers to collide with
@export_flags_3d_physics var collision_layers := 3

## Collision distance at which fading begins
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var fade_start_distance := 0.3

## Collision distance for totally obscuring the view
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var fade_full_distance := 0.15


# Shape to use for collision detection
var _collision_shape: Shape3D

# Parameters to use for collision detection
var _collision_parameters: PhysicsShapeQueryParameters3D

# World space to use for collision detection
var _space: PhysicsDirectSpaceState3D


# When the node enters the scene tree for the first time.
func _ready() -> void:
	# Construct a sphere for the collision shape
	_collision_shape = SphereShape3D.new()
	_collision_shape.radius = fade_start_distance

	# Construct the collosion parameters
	_collision_parameters = PhysicsShapeQueryParameters3D.new()
	_collision_parameters.collision_mask = collision_layers
	_collision_parameters.set_shape(_collision_shape)

	# Get the space to test collisions in
	_space = get_world_3d().direct_space_state


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(_delta: float) -> void:
	# Update the collision parameters to include our global location
	_collision_parameters.transform = global_transform

	# Find closest collision
	var results := _space.get_rest_info(_collision_parameters)
	if "point" in results:
		# Collision detected, calculate distance to closet collision point
		var delta_pos: Vector3 = global_transform.origin - results["point"]
		var length := delta_pos.length()

		# Fade based on distance
		var alpha := inverse_lerp(fade_start_distance, fade_full_distance, length)
		XRToolsFade.set_fade(self, Color(0, 0, 0, alpha))
	else:
		# No collision
		XRToolsFade.set_fade(self, Color(0, 0, 0, 0))


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsFadeCollision"
