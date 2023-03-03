@tool
class_name XRToolsInteractableHandleDriven
extends Node3D


## XR Tools Interactable Handle Driven script
##
## This is the base class for interactables driven by handles. It subscribes
## to all child handle picked_up and dropped signals, and maintains a list
## of all grabbed handles.
##
## When one or more handles are grabbed, the _process function is enabled
## to process the handle-driven movement.


## Signal called when this interactable is grabbed
signal grabbed(interactable)

## Signal called when this interactable is released
signal released(interactable)


# Array of handles currently grabbed
var grabbed_handles := Array()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableHandleDriven"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Hook picked_up and dropped signals from all child handles
	_hook_child_handles(self)

	# Turn off processing until a handle is grabbed
	set_process(false)


# Called when a handle is picked up
func _on_handle_picked_up(handle: XRToolsInteractableHandle) -> void:
	# Append to the list of grabbed handles
	grabbed_handles.append(handle)

	# Enable processing
	if grabbed_handles.size() == 1:
		# Report grabbed
		emit_signal("grabbed", self)

		# Enable physics processing
		set_process(true)


# Called when a handle is dropped
func _on_handle_dropped(handle: XRToolsInteractableHandle) -> void:
	# Remove from the list of grabbed handles
	grabbed_handles.erase(handle)

	# Disable processing when we drop the last handle
	if grabbed_handles.is_empty():
		# Disable physics processing
		set_process(false)

		# Report released
		emit_signal("released", self)


# Recursive function to hook picked_up and dropped signals in all child handles
func _hook_child_handles(node: Node) -> void:
	# If this node is a handle then hook its handle signals
	var handle := node as XRToolsInteractableHandle
	if handle:
		if handle.picked_up.connect(_on_handle_picked_up):
			push_error("Unable to connect handle signal")
		if handle.dropped.connect(_on_handle_dropped):
			push_error("Unable to connect handle signal")

	# Recurse into all children
	for child in node.get_children():
		_hook_child_handles(child)
