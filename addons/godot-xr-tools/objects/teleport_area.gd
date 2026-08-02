@tool
class_name XRToolsTeleportArea
extends Area3D

## Checks for an [XRToolsPlayerBody] entering, and teleports them to a specific
## [Node3D]

## Node at the target location
@export var target: Node3D


# When the node enters the scene tree for the first time.
func _ready() -> void:
	# Handle body entered
	body_entered.connect(_on_body_entered)


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsTeleportArea"


# Handles bodies entering this area
func _on_body_entered(body: Node3D) -> void:
	# Test if the body is the player
	var player_body := body as XRToolsPlayerBody
	if not player_body:
		return

	# Teleport the player
	player_body.teleport(target.global_transform)
