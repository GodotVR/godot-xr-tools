extends XRToolsPickable


## Snap-tray active state
@export var tray_active : bool = true: set = _set_tray_active

## Active material
@export var active_material : Material

## Inactive material
@export var inactive_material : Material


## Called when the node enters the scene tree for the first time.
func _ready():
	# Update the tray_active state
	_update_tray_active()


# Handle pointer events
func pointer_event(event : XRToolsPointerEvent) -> void:
	# When pressed, toggle the tray active
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		_set_tray_active(not tray_active)


# Handler for tray_active property change
func _set_tray_active(new_value : bool) -> void:
	tray_active = new_value
	if is_inside_tree():
		_update_tray_active()


## Update state based on tray_active property
func _update_tray_active() -> void:
	$Body.material_override = active_material if tray_active else inactive_material
	$SnapArea1/SnapZone1.enabled = tray_active
	$SnapArea2/SnapZone2.enabled = tray_active
	$SnapArea3/SnapZone3.enabled = tray_active
	$SnapArea4/SnapZone4.enabled = tray_active
