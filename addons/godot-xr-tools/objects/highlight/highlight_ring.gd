@tool
class_name XRToolsHighlightRing
extends MeshInstance3D

var _parent: Node


# When the node enters the scene tree for the first time.
func _ready() -> void:
	# Get the parent node
	_parent = get_parent()

	# Turn off until requested
	if not Engine.is_editor_hint():
		visible = false

	# Hook the highlight update
	if _parent.has_signal("highlight_updated"):
		_parent.highlight_updated.connect(_on_highlight_updated)


# Verifies the node
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Verify parent supports highlighting
	if not _parent or not _parent.has_signal("highlight_updated"):
		warnings.append("Parent does not support highlighting")

	return warnings


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsHighlightRing"


# When the pickable highlight changes
func _on_highlight_updated(_pickable: XRToolsPickable, enable: bool) -> void:
	visible = enable
