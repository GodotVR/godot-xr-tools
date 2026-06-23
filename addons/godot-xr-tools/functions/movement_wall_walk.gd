@tool
class_name XRToolsMovementWallWalk
extends XRToolsMovementProvider

##  XR Tools Movement Provider for Wall-Walking
##
## Wall walking is a common feature in many 2D and 3D games, and has started
## appearing in VR games (for players with strong stomachs).[br][br]
##
## This movement provider allows the player to walk on objects that have a
## physics layer matching the provider’s mask.


## Default wall-walk mask of 4:wall-walk
const DEFAULT_MASK := 0b0000_0000_0000_0000_0000_0000_0000_1000


## Order in which movement is processed
@export var order: int = 25

## Physics layers that support wall walking
@export_flags_3d_physics var follow_mask := DEFAULT_MASK

## How far away from the wall the player can jump
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var stick_distance := 1.0

## Pseudo-gravity exerted on the player while wall-walking
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s^2") var stick_strength := 9.8


func physics_pre_movement(
		_delta: float,
		player_body: XRToolsPlayerBody,
) -> void:
	# Test for collision with wall under feet
	var wall_collision := player_body.move_and_collide(
			player_body.up_player * -stick_distance,
			true,
	)
	if not wall_collision:
		return

	# Get the wall information
	var wall_node := wall_collision.get_collider()
	var wall_normal := wall_collision.get_normal()

	# Skip if the wall node doesn't have a collision layer
	if not "collision_layer" in wall_node:
		return

	# Skip if the wall doesn't match the follow layer
	var wall_layer: int = wall_node.collision_layer
	if (wall_layer & follow_mask) == 0:
		return

	# Modify the player gravity
	player_body.gravity = -wall_normal * stick_strength
