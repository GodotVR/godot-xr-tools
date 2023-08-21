@tool
class_name XRToolsTeleportArea
extends Area3D


## Target node
@export var target : Node3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsTeleportArea"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Handle body entered
	body_entered.connect(_on_body_entered)


# Handle body entering area
func _on_body_entered(body : Node3D) -> void:
	# Test if the body is the player
	var player_body := body as XRToolsPlayerBody
	if not player_body:
		return

	# Teleport the player
	player_body.teleport(target.global_transform)
