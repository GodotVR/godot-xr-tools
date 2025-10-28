@tool
extends Node3D

@export_multiline var label : String = "XRNode3D":
	set(value):
		label = value
		if is_inside_tree():
			_update_label()

func _update_label():
	$Label3D.text = label

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_label()
