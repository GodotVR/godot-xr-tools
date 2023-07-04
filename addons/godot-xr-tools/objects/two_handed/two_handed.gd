## adds collision to the Open_XR Hands
## ________________________________________________________
## a CharacterBody3D that follows the corresponding XRController3D.
## it is able to collide with the world and with static objects
## ________________________________________________________
## OPTIONAL FEATURES:
## ________________________________________________________
## collision on pickables/ weight on pickables/ zero_g movement
class_name XRToolsTwoHanded
extends Node

@export_group("Two Handed Setup")

## select controller
## if path is not set, this will be ignored
@export_subgroup("Select Path")
@export var interactable_handle : XRToolsInteractableHandle
@export var second_hand_position : Marker3D
@export var primary_hand_position : Marker3D
@export var pose_area : XRToolsHandPoseArea
## if path is not set, this will be ignored
@export_subgroup("Additional Settings")
# Check if is melee
@export var mod : bool = false
@export var axis : Vector3 = Vector3(0,1,1)
@export var radians : float = 180
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

# collision
var c
# correction
var _c
#translate
var _tl
# transform
var _tf

## Left hand XRController3D node
@onready var left_hand_node : XRController3D = XRHelpers.get_left_controller(self)

## Right hand XRController3D node
@onready var right_hand_node : XRController3D = XRHelpers.get_right_controller(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsTwoHanded"


# Called when the node enters the scene tree for the first time.
func _ready():
	# set to frozen state to keep position
	interactable_handle.freeze = true
	# Store default transform basis
	basis_before_two_handed = get_parent().transform.basis

	_parent.picked_up.connect(_on_picked_up)
	_parent.dropped.connect(_on_dropped)
	# Connect grabbed and dropped signal from interactable handle
	# for two handed if there is a handle
	interactable_handle.picked_up.connect(_on_second_hand_grabbed)
	interactable_handle.dropped.connect(_on_second_hand_dropped)


func _process(_delta):
	# If two handed activated, change transform
	# to be guided by both hand positions
	if using_two_handed:
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
		pose_area.monitorable = true


# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	_parent.by_controller = _parent.get_picked_up_by_controller()
	if _parent.by_controller:
		# Switch the grab point
		var active_grab_point := _parent.get_active_grab_point()


# Called when this object is dropped
func _on_dropped(_pickable) -> void:
	# If not using two handed, do nothing
	if !using_two_handed:
		return

	if using_two_handed:
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

func _on_second_hand_dropped(_handle):
	# If not using two handed, do nothing
	if !using_two_handed:
		return

	if using_two_handed:
		using_two_handed = false
		pose_area.monitorable = false
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
	## by_controller as in the controller that picked up the pickable first
	## is being set to looking_at the second hand controller
	## this way we get the twohanded working but without the
	## _parent.translate the twohanded will be displaced because
	## of the grabpoints
	_parent.global_transform = _parent.by_controller.global_transform.looking_at(second_hand_controller.global_transform.origin,Vector3.UP)

	## if it is a melee object, primary controller rotation is set to
	## second controller rotation with an axis and radians offset
	if mod:
		_parent.by_controller.rotation = second_hand_controller.rotation.rotated(axis, radians)


	## by setting translate self to the get_active_grab_point we get
	## the pickable positioned correctly when being held with twohands
	_parent.translate(Vector3(0,0,0)- _parent.get_active_grab_point().transform.origin) 


func get_collider_dict():
	c = _parent.get_node("CollisionShape3D")
	_c = _parent.get_active_grab_point().transform.origin
	_tl = _parent.get_active_grab_point().transform * c.transform.origin - _c * 2
	_tf = Transform3D(_parent.get_active_grab_point().transform.basis, _tl)
	return {c : _tf}
