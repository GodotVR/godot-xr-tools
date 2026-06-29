@tool
class_name XRToolsHighlightMaterial
extends Node

## Mesh to highlight
@export var highlight_mesh_instance: NodePath

## Material to set
@export var highlight_material: Resource


var _original_materials: Array[Material]
var _highlight_mesh: MeshInstance3D
var _parent: Node


# When the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the parent
	_parent = get_parent()

	# Get the mesh to highlight
	_highlight_mesh = get_node(highlight_mesh_instance)

	# Save the materials
	if _highlight_mesh:
		# if we can find a node,
		# remember which materials are currently set on each surface
		for i: int in _highlight_mesh.get_surface_override_material_count():
			_original_materials.push_back(
					_highlight_mesh.get_surface_override_material(i)
			)

	# Hook the highlight update
	if _parent.has_signal("highlight_updated"):
		_parent.highlight_updated.connect(_on_highlight_updated)


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsHighlightMaterial"


# Called when the pickable highlight changes
func _on_highlight_updated(_pickable, enable: bool) -> void:
	# Set the materials
	if _highlight_mesh:
		for i: int in _highlight_mesh.get_surface_override_material_count():
			if enable:
				_highlight_mesh.set_surface_override_material(i, highlight_material)
			else:
				_highlight_mesh.set_surface_override_material(i, _original_materials[i])


# Verifies the node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify parent supports highlighting
	if not _parent or not _parent.has_signal("highlight_updated"):
		warnings.append("Parent does not support highlighting")

	return warnings
