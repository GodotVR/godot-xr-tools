tool
extends XRToolsSceneBase

func _update_demo_positions() -> void:
	var count = $Demos.get_child_count()
	if count > 1:
		var angle = 2.0 * PI / count
		for i in count:
			var t = Transform()
			t.origin = Vector3(0.0, 0.0, -7.0)
			t = t.rotated(Vector3.UP, angle * i)
			
			$Demos.get_child(i).transform = t


func _ready():
	_update_demo_positions()


func _on_Demos_child_entered_tree(_node):
	_update_demo_positions()


func _on_Demos_child_exiting_tree(_node):
	_update_demo_positions()
