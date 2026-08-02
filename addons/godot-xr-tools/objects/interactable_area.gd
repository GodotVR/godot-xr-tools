@tool
class_name XRToolsInteractableArea
extends Area3D
## Area3D that emits [XRToolsPointerEvent]s whenever pointed at by
## [XRToolsFunctionPointer]s


## Emitted when pointer event occurs on area
signal pointer_event(event: XRToolsPointerEvent)


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsInteractableArea"
