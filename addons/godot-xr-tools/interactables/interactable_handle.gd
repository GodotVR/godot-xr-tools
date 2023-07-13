@tool
class_name XRToolsInteractableHandle
extends XRToolsPickable


## XR Tools Interactable Handle script
##
## The interactable handle is a (usually invisible) object extending from
## [XRToolsPickable] that can be grabbed by the player and is used to
## manipulate interactable objects.
##
## The interactible handle has an origin position of its parent. In order
## to position interactible handles on the interactible object, the handle
## should be placed under a parent handle-origin node, and the origin nodes
## position set as desired.
##
## When the handle is released, it snaps back to its parent origin. If the
## handle is pulled further than its snap distance, then the handle is
## automatically released.


## Distance from the handle origin to auto-snap the grab
@export var snap_distance : float = 0.3

@export_group("Optional attach Hand")
## this latches the grabbing Hand onto the Interactable
## ________________________________________________________
## Requirement: Collision Hands
## ________________________________________________________
## Additional Note:
## ________________________________________________________
## if export paths are not set, this will be ignored
## so make sure to setup the paths corresponding to hand
## Example: left_hand_position = LeftHandMarker3D
@export var left_hand_position : Marker3D
## Requirement: Collision Hands
@export var right_hand_position : Marker3D


# Handle origin spatial node
@onready var handle_origin: Node3D = get_parent()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsInteractableHandle" or super(name)


# Called when this handle is added to the scene
func _ready() -> void:
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Ensure we start at our origin
	transform = Transform3D.IDENTITY

	# Turn off processing - it will be turned on only when held
	set_process(false)


# Called on every frame when the handle is held to check for snapping
func _process(_delta: float) -> void:
	# Skip if not picked up
	if !picked_up_by:
		return

	# If too far from the origin then drop the handle
	var origin_pos = handle_origin.global_transform.origin
	var handle_pos = global_transform.origin
	if handle_pos.distance_to(origin_pos) > snap_distance:
		picked_up_by.drop_object()


# Called when the handle is picked up
func pick_up(by, with_controller) -> void:
	# Call the base-class to perform the pickup
	super(by, with_controller)
	if left_hand_position:
		if with_controller.name.matchn("*left*"):
			left_hand_position.get_node("RemoteTransform3D").remote_path = self.by_hand.get_path()
		else:
			right_hand_position.get_node("RemoteTransform3D").remote_path = self.by_hand.get_path()
	# Enable the process function while held
	set_process(true)


# Called when the handle is dropped
func let_go(_p_linear_velocity: Vector3, _p_angular_velocity: Vector3) -> void:
	# Call the base-class to perform the drop, but with no velocity
	super(Vector3.ZERO, Vector3.ZERO)
	if left_hand_position:
		left_hand_position.get_node("RemoteTransform3D").remote_path = ""
		right_hand_position.get_node("RemoteTransform3D").remote_path = ""

	# Disable the process function as no-longer held
	set_process(false)

	# Snap the handle back to the origin
	transform = Transform3D.IDENTITY


# Check handle configurationv
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if !transform.is_equal_approx(Transform3D.IDENTITY):
		warnings.append("Interactable handle must have no transform from its parent handle origin")

	return warnings
