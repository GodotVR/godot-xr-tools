@tool
extends Node3D

@export_multiline var label : String = "XRNode3D":
	set(value):
		label = value
		if is_inside_tree():
			_update_label()

@export_flags_3d_render var layers = 7:
	set(value):
		layers = value
		if is_inside_tree():
			_update_layers()


func _update_label():
	$Label3D.text = label


func _update_layers():
	$Forward.layers = layers
	$Forward/Z.layers = layers
	$Up.layers = layers
	$Up/Y.layers = layers
	$Left.layers = layers
	$Left/X.layers = layers
	$Label3D.layers = layers


# Called when the node enters the scene tree for the first time.
func _ready():
	_update_label()
	_update_layers()
