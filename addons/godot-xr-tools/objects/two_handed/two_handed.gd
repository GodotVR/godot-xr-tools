class_name XRToolsTwoHanded
extends Node


@export var interactable_handle : XRToolsInteractableHandle
@export var second_hand_position : Marker3D
@export var primary_hand_position : Marker3D
# Check if is melee
@export var melee : bool = false

@onready var _parent : XRToolsPickable = get_parent()
# Check if using two-handed
var using_two_handed : bool = false

# Store second hand controller
var second_hand_controller : XRController3D
# Store second hand node
var second_hand
# Store weapon basis just before two-handing
var basis_before_two_handed : Basis
# Store primary hand node's transform as it was before two handing
var primary_hand_original_transform : Transform3D
# Store second hand node's transform as it was before two handing
var second_hand_original_transform :Transform3D
var collision
## Left hand XRController3D node
@onready var left_hand_node : XRController3D = XRHelpers.get_left_controller(self)

## Right hand XRController3D node
@onready var right_hand_node : XRController3D = XRHelpers.get_right_controller(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsTwoHanded"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Store default transform basis
	basis_before_two_handed = get_parent().transform.basis
	interactable_handle.transform.origin = Vector3(0,0,0)
	_parent.picked_up.connect(_on_picked_up)
	_parent.dropped.connect(_on_dropped)
	# Connect grabbed and dropped signal from interactable handle for two handed if there is a handle
	interactable_handle.picked_up.connect(_on_second_hand_grabbed)
	interactable_handle.dropped.connect(_on_second_hand_dropped)


func _process(delta):
	# If two handed activated, change transform to be guided by both hand positions
	if using_two_handed and !melee:
		_correct_alignment()
	else:
		pass

func _on_second_hand_grabbed(_handle):
	# Don't activate two handed mode if not already picked up
	if !_parent.is_picked_up():
		return
	# If item is already picked up, then we're in two-handed mode
	if _parent.is_picked_up() and _parent.by_controller != null:
		second_hand_controller = _handle.by_controller
		second_hand = _handle.by_hand
		second_hand_original_transform = _handle.by_hand.transform
		primary_hand_original_transform = _parent.by_hand.transform
		if second_hand.name.matchn("*left*"):
			primary_hand_position.transform = _parent.get_node("GrabPointHandRight").transform
		else:
			primary_hand_position.transform = _parent.get_node("GrabPointHandLeft").transform
		if second_hand_position != null:
			second_hand_position.get_node("RemoteTransform3D").remote_path = _handle.by_hand.get_path()
		if primary_hand_position != null:	
			primary_hand_position.get_node("RemoteTransform3D").remote_path = _parent.by_hand.get_path()
		using_two_handed = true
		#collision.global_transform = second_hand_controller.global_transform
		#collision.translate(Vector3(0,0,0)- _parent.get_active_grab_point().transform.origin) 
# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	_parent.by_controller = _parent.get_picked_up_by_controller()
	if _parent.by_controller:
		interactable_handle.transform.origin = Vector3(0,0,0)
		# Switch the grab point
		var active_grab_point := _parent.get_active_grab_point()
		if active_grab_point == $GrabPointHandLeft:
			_parent.switch_active_grab_point($GrabPointGripLeft)
		elif active_grab_point == $GrabPointHandRight:
			_parent.switch_active_grab_point($GrabPointGripRight)
		elif active_grab_point == $GrabPointGripLeft:
			_parent.switch_active_grab_point($GrabPointHandLeft)
		elif active_grab_point == $GrabPointGripRight:
			_parent.switch_active_grab_point($GrabPointHandRight)		
		#by_hand.transform.origin = active_grab_point.transform.origin

# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# If not using two handed, do nothing
	if !using_two_handed:
		return
	else:
		using_two_handed = false
	# Return to single handed mode
	primary_hand_position.get_node("RemoteTransform3D").remote_path = ""
	second_hand_position.get_node("RemoteTransform3D").remote_path = ""
	second_hand.transform = second_hand_original_transform
	second_hand_controller = null
	second_hand = null
	if _parent.by_controller:
		_parent.by_controller = null
		_parent.transform.basis = basis_before_two_handed
		interactable_handle.transform.origin = Vector3(0,0,0)

func _on_second_hand_dropped(_handle):
	# If not using two handed, do nothing
	if !using_two_handed:
		return
	else:
		using_two_handed = false
	# Return to single handed mode
	primary_hand_position.get_node("RemoteTransform3D").remote_path = ""
	second_hand_position.get_node("RemoteTransform3D").remote_path = ""
	_parent.by_hand.transform = primary_hand_original_transform
	second_hand.transform = second_hand_original_transform
	second_hand_controller = null
	second_hand = null
	if _parent.is_picked_up() and _parent.by_controller != null:
		_parent.transform.basis = basis_before_two_handed


func _correct_alignment():
	## by_controller as in the controller that picked up the pickable first is being set to looking_at the second hand controller
	## this way we get the twohanded working but without the self.translate the twohanded will be displaced because of the
	## grabpoints
	_parent.global_transform = _parent.by_controller.global_transform.looking_at(second_hand_controller.global_transform.origin,Vector3.UP)

	## by setting translate self to the get_active_grab_point we get the pickable
	## positioned correctly when being held with twohands
	_parent.translate(Vector3(0,0,0)- _parent.get_active_grab_point().transform.origin) 


func get_collider_dict():
	collision = _parent.get_node("CollisionShape3D")
	var _correction = _parent.get_active_grab_point().transform.origin
	var shape_translate = _parent.get_active_grab_point().transform * collision.transform.origin - _correction * 2
	var shape_transform = Transform3D(_parent.get_active_grab_point().transform.basis, shape_translate)
	return {collision : shape_transform}
