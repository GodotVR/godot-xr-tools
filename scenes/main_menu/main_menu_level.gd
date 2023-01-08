@tool
extends "../scene_base.gd"

func _update_demo_positions() -> void:
	var count = 0#$Demos.get_child_count()
	var vis_chd := []
	for _tp in $Demos.get_children():
		_tp.active=_tp.visible
		if _tp.visible:
			count+=1
			vis_chd.append(_tp)
	if count > 1:
		var angle = 2.0 * PI / count
		for i in count:
			var t = Transform3D()
			t.origin = Vector3(0.0, 0.0, -10.0)
			t = t.rotated(Vector3.UP, angle * i)

			vis_chd[i].transform = t


func _ready():
	super._ready()
	_update_demo_positions()
	
	for _c in $Demos.get_children():
		_c.connect("visibility_changed",_update_demo_positions)


func _on_Demos_child_entered_tree(_node):
	_update_demo_positions()


func _on_Demos_child_exiting_tree(_node):
	_update_demo_positions()
