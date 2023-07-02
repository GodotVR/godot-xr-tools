extends Node3D

signal player_height_changed(new_height)

func _on_player_height_changed(new_height):
	emit_signal("player_height_changed", new_height)

# Called when the node enters the scene tree for the first time.
func _ready():
	var scene = $Screen/Viewport2Din3D.get_scene_instance()
	if scene:
		scene.connect("player_height_changed", _on_player_height_changed)
