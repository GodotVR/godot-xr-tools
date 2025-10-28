@tool
extends Node3D

@export var color : Color = Color(1.0, 1.0, 1.0, 1.0):
	set(value):
		color = value
		if is_inside_tree():
			_on_color_changed()

func _on_color_changed():
	var material : StandardMaterial3D = $Stem.material_override
	material.albedo_color = color

func _ready():
	_on_color_changed()
