@tool
extends Node3D

@export var color : Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color = value
		if is_inside_tree():
			_on_color_changed()

@export_flags_3d_render var layers = 7:
	set(value):
		layers = value
		if is_inside_tree():
			_on_layers_changed()


func _on_color_changed():
	var material : StandardMaterial3D = $Stem.material_override
	material.albedo_color = color


func _on_layers_changed():
	$Stem.layers = layers
	$Head.layers = layers


func _ready():
	_on_color_changed()
	_on_layers_changed()
