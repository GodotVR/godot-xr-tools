class_name XRToolsInteractableBody
extends Node3D
## [PhysicsBody3D] that emits [XRToolsPointerEvent]s when pointed at by
## [XRToolsFunctionPointer]s.
##
## Note: This should extend from [PhysicsBody3D],
## but [url]https://github.com/godotengine/godot/issues/46073[/url]


## Emitted when pointer event occurs on body
signal pointer_event(event: XRToolsPointerEvent)
