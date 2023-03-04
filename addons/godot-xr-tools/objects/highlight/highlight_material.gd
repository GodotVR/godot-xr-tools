@tool
class_name XRToolsHighlightMaterial
extends Node


## Mesh to highlight
@export var highlight_mesh_instance : NodePath

## Material to set
@export var highlight_material : Resource


var _original_materials = Array()
var _highlight_mesh_instance: MeshInstance3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsHighlightMaterial"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the mesh to highlight
	_highlight_mesh_instance = get_node(highlight_mesh_instance)

	# Save the materials
	if _highlight_mesh_instance:
		# if we can find a node remember which materials are currently set on each surface
		for i in range(0, _highlight_mesh_instance.get_surface_override_material_count()):
			_original_materials.push_back(_highlight_mesh_instance.get_surface_override_material(i))

	# Hook the highlight update
	get_parent().connect("highlight_updated", _on_highlight_updated)


# Called when the pickable highlight changes
func _on_highlight_updated(_pickable, enable: bool) -> void:
	# Set the materials
	if _highlight_mesh_instance:
		for i in range(0, _highlight_mesh_instance.get_surface_override_material_count()):
			if enable:
				_highlight_mesh_instance.set_surface_override_material(i, highlight_material)
			else:
				_highlight_mesh_instance.set_surface_override_material(i, _original_materials[i])


# This method verifies the node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify parent supports highlighting
	var parent := get_parent()
	if not parent or not parent.has_signal("highlight_updated"):
		warnings.append("Parent does not support highlighting")

	return warnings
