tool
extends XRToolsSceneBase

func _update_demo_positions() -> void:
	# Update and count the visible teleporters
	var count = 0
	var visible_children := []
	for teleporter in $Demos.get_children():
		teleporter.active = teleporter.visible
		teleporter.set_collision_disabled(!teleporter.visible)
		if teleporter.visible:
			count += 1
			visible_children.append(teleporter)

	# Arrange the visible teleporters
	if count > 1:
		var angle = 2.0 * PI / count
		for i in count:
			var t = Transform()
			t.origin = Vector3(0.0, 0.0, -10.0)
			t = t.rotated(Vector3.UP, angle * i)

			visible_children[i].transform = t


func _ready():
	_update_demo_positions()

	for teleporter in $Demos.get_children():
		teleporter.connect("visibility_changed", self, "_update_demo_positions")


func _on_Demos_child_entered_tree(_node):
	_update_demo_positions()


func _on_Demos_child_exiting_tree(_node):
	_update_demo_positions()
