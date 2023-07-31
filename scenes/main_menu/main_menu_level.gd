@tool
extends DemoSceneBase

func _update_demo_positions() -> void:
	# Update and count the visible teleporters
	var count = 0
	var visible_children := []
	for teleporter in $Demos.get_children():
		teleporter.set_collision_disabled(!teleporter.visible)
		if teleporter.visible:
			count += 1
			visible_children.append(teleporter)

	# Arrange the visible teleporters
	if count > 1:
		var angle = 2.0 * PI / count
		for i in count:
			var t = Transform3D()
			t.origin = Vector3(0.0, 0.0, -10.0)
			t = t.rotated(Vector3.UP, angle * i)

			visible_children[i].transform = t


func _ready():
	super()
	_update_demo_positions()

	for teleporter in $Demos.get_children():
		teleporter.connect("visibility_changed",_update_demo_positions)


func _on_Demos_child_entered_tree(_node):
	_update_demo_positions()


func _on_Demos_child_exiting_tree(_node):
	_update_demo_positions()


func _on_settings_ui_player_height_changed(new_height):
	$XROrigin3D/PlayerBody.calibrate_player_height()
