@tool
class_name XRToolsHighlightRing
extends MeshInstance3D


# Called when the node enters the scene tree for the first time.
func _ready():
	# Turn unchecked until requested
	if not Engine.is_editor_hint():
		visible = false

	# Hook the highlight update
	get_parent().connect("highlight_updated", _on_highlight_updated)


# Called when the pickable highlight changes
func _on_highlight_updated(_pickable, enable: bool) -> void:
	visible = enable


# This method verifies the node
func _get_configuration_warning():
	# Verify parent supports highlighting
	var parent := get_parent()
	if not parent or not parent.has_signal("highlight_updated"):
		return "Parent does not support highlighting"

	# No issues
	return ""
