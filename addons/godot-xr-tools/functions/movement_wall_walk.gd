@tool
class_name XRToolsMovementWallWalk
extends XRToolsMovementProvider


# Default wall-walk mask of 4:wall-walk
const DEFAULT_MASK := 0b0000_0000_0000_0000_0000_0000_0000_1000


## Wall walking provider order
@export var order : int = 25

## Set our follow layer mask
@export_flags_3d_physics var follow_mask : int = DEFAULT_MASK

## Wall stick distance
@export var stick_distance : float = 1.0

## Wall stick strength
@export var stick_strength : float = 9.8


func physics_pre_movement(_delta: float, player_body: XRToolsPlayerBody):
	# Test for collision with wall under feet
	var wall_collision := player_body.move_and_collide(
		player_body.up_player * -stick_distance, true, true, true)
	if !wall_collision:
		return

	# Get the wall information
	var wall_node := wall_collision.get_collider()
	var wall_normal := wall_collision.get_normal()

	# Skip if the wall node doesn't have a collision layer
	if not "collision_layer" in wall_node:
		return

	# Skip if the wall doesn't match the follow layer
	var wall_layer : int = wall_node.collision_layer
	if (wall_layer & follow_mask) == 0:
		return

	# Modify the player gravity
	player_body.gravity = -wall_normal * stick_strength
