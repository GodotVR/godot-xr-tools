tool
class_name XRToolsInteractableHandle
extends XRToolsPickable


##
## Interactable Handle script
##
## @desc:
##     The interactable handle is a (usually invisible) object that can be
##     grabbed by the player and is used to manipulate interactable objects.
##
##     The interactible handle has an origin position of its parent. In order
##     to position interactible handles on the interactible object, the handle
##     should be placed under a parent handle-origin Spatial node, and the
##     origin nodes position set as desired.
##
##     When the handle is released, it snaps back to its parent origin. If the
##     handle is pulled further than its snap distance, then the handle is
##     automatically released.
##


## Distance from the handle origin to auto-snap the grab
export var snap_distance : float = 0.3


# Handle origin spatial node
onready var handle_origin: Spatial = get_parent()


# Called when this handle is added to the scene
func _ready() -> void:
	# Ensure we start at our origin
	transform = Transform.IDENTITY

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
	.pick_up(by, with_controller)

	# Enable the process function while held
	set_process(true)


# Called when the handle is dropped
func let_go(_p_linear_velocity: Vector3, _p_angular_velocity: Vector3) -> void:
	# Call the base-class to perform the drop, but with no velocity
	.let_go(Vector3.ZERO, Vector3.ZERO)

	# Disable the process function as no-longer held
	set_process(false)

	# Snap the handle back to the origin
	transform = Transform.IDENTITY


# Check handle configuration
func _get_configuration_warning() -> String:
	if !transform.is_equal_approx(Transform.IDENTITY):
		return "Interactable handle must have no transform from its parent handle origin"

	return ""
