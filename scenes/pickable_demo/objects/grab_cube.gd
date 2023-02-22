extends XRToolsPickable


## Material to show when active
export var active_material : Material


# Default material shown when inactive
var _default_material : Material


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_default_material = $MeshInstance.get_active_material(0)

	# Listen for events
	connect("action_pressed", self, "_on_action_pressed")
	connect("action_released", self, "_on_action_released")
	connect("dropped", self, "_on_dropped")


# Called when the user presses the action button while holding this object
func _on_action_pressed(_pickable : XRToolsPickable) -> void:
	if active_material:
		$MeshInstance.set_surface_material(0, active_material)


# Called when the user releases the action button while holding this object
func _on_action_released(_pickable : XRToolsPickable) -> void:
	$MeshInstance.set_surface_material(0, _default_material)


# Called when this object is dropped
func _on_dropped(_pickable : XRToolsPickable) -> void:
	$MeshInstance.set_surface_material(0, _default_material)
