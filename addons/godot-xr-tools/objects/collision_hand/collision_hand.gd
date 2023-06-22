@tool
class_name XRToolsCollisionHand
extends CharacterBody3D

#
# adds collision capabilities to open_xr hands and held objects
#
# REQUIRES SETUP:
# 1) Parent must be ARVROrigin (NOT THE ARVRControllers!)
# 2) All export NodePaths must be set
# 3) PhysicsHand and PickupFunction are expected to be children of the controller
# 4) Held objects may have a get_collider_dict() function to inform
#    THIS of what colliders it has and their orientation. Dictionary format:
#    collision_dict = {CollisionShape : Transform, CollisionShape : Transform, ...}
# 5) Make note of collision layers, do not let the hands collide with whatever
#    body system you are using
#
# THIS addition acts a KinematicBody that "chases" the controller THIS is assigned
# to. THIS has a simple CollisionShape to simulate the empty hand and will copy
# the CollisionShapes of held objects and add them to THIS as children; then it
# will delete the copied CollisionShapes on drop.

@export var controller_path : NodePath
# On Godot-XR-Dojo Avatar, this will be the "PhysicsHand"
@export var visual_hand_path : NodePath #Should be child of ARVRController
@export var pickup_path : NodePath #Should be child of ARVRController

## if set to true, pickable objects will have collision
@export var pickable_collision : bool = false

@export var is_left_controller : bool = false

## Distance before dropping when stuck
@export var max_distance : float = 0.2

@export var slide_speed : float = 30.0
@onready var collision_offset_left : Vector3 = Vector3(-0.029,-0.051,0.129)
@onready var collision_offset_right : Vector3 = Vector3(0.029,-0.051,0.129)

@onready var controller : XRController3D = get_node(controller_path)
@onready var visual_hand = get_node(visual_hand_path)
@onready var pickup = get_node(pickup_path)
@onready var hand_shape : CollisionShape3D = $HandShape

@onready var hr_transform : RemoteTransform3D = $HandRemoteTransform3D
@onready var pr_transform : RemoteTransform3D = $PickupRemoteTransform3D

# check for collision when twohanded object is picked up
var twohanded_collision : bool = false
var collision

# List of colliders added by grabbed objects
var collider_list : Array = [] 
var held_body : PhysicsBody3D
var _what 
var _collider
var two_handed
var col_dict : Dictionary
var _mass


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsCollisionHand"


func _ready():
	if is_left_controller:
		hand_shape.transform.origin = collision_offset_left
	else:
		hand_shape.transform.origin = collision_offset_right

	# Connects Remote Transforms to targets
	hr_transform.set_transform(visual_hand.get_transform())
	hr_transform.remote_path = visual_hand.get_path()
	pr_transform.set_transform(pickup.get_transform())
	pr_transform.remote_path = pickup.get_path()
	
	# Connects signals for grabbing and dropping from pickup function
	if pickable_collision:
		pickup.has_picked_up.connect(add_colliders)
		pickup.has_dropped.connect(remove_colliders)


func _physics_process(delta):
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	if is_instance_valid(held_body):
		if twohanded_collision:
			two_handed = held_body.get_node("TwoHanded")
			if two_handed.using_two_handed:
				_collider.global_transform = controller.global_transform.looking_at(two_handed.second_hand_controller.global_transform.origin,Vector3.UP)

				## by setting translate self to the get_active_grab_point we get the pickable
				## positioned correctly when being held with twohands
				_collider.translate(Vector3(0,0,0)- held_body.get_active_grab_point().transform.origin)
			else:
				_collider.global_transform = controller.global_transform
				_collider.translate(Vector3(0,0,0)- held_body.get_active_grab_point().transform.origin)

	move_to(controller)
	check_for_drop()


# With collision, move self toward target
func move_to(target : Node) -> void:
	var t_pos : Vector3 = target.global_transform.origin #Target Position
	var s_pos : Vector3 = self.global_transform.origin #Self Position
	
	var dir : Vector3 = t_pos - s_pos #Move Direction
	if is_instance_valid(held_body):
		_mass = held_body.mass
	else:
		_mass = 1
	velocity = dir * slide_speed# _mass ## by removing slide_speed or substituting it, a zero g or weighted/velocity based hand could be achieved
	move_and_slide()
	self.set_rotation(controller.rotation)


# Checks if held object is too far to be held and drops it if true
func check_for_drop() -> void:
	if is_instance_valid(held_body):
		_check_extended()
	else:
		_check()


func _check_extended():
	if held_body.has_node("TwoHanded"):
		two_handed = held_body.get_node("TwoHanded")
		if two_handed.using_two_handed:
			var c_pos = controller.global_transform.origin #Controller Position
			var s_pos = self.global_transform.origin #Self Position
			
			var face_pos = two_handed.second_hand_controller.global_transform.origin #TwoHanded - Second Controller Position
			var s_dist = s_pos.distance_to(face_pos)
			var c_dist = c_pos.distance_to(face_pos)

			if s_dist > c_dist + max_distance: #If object too far from face
				pickup.drop_object()
				remove_colliders()
				self.transform = controller.transform
		else:
			_check()
	else:
		_check()


func _check():
	var c_pos = controller.global_transform.origin #Controller Position
	var s_pos = self.global_transform.origin #Self Position

	var face_pos = self.get_parent().global_transform.origin
	var s_dist = s_pos.distance_to(face_pos)
	var c_dist = c_pos.distance_to(face_pos)

	if s_dist > c_dist + max_distance: #If object too far from face
		pickup.drop_object()
		remove_colliders()
		self.transform = controller.transform


# Requests a dictionary of CollisionShapes with Transforms from Spatial object
# for holding; else finds all CollisionShape children
# Format: {CollisionShape : Transform, CollisionShape : Transform,...}
func add_colliders(_what : Node3D) -> void:
	if is_instance_valid(_what):
		if _what.has_node("TwoHanded"):
			twohanded_collision = true
			#two_handed = _what.get_node("TwoHanded")
			col_dict = _what.get_node("TwoHanded").get_collider_dict()
			for key in col_dict.keys():
				_collider = key.duplicate()
				_collider.transform = col_dict[key]
				collider_list.append(_collider)
				self.add_child(_collider)
			held_body = _what
			self.add_collision_exception_with(held_body)
		if  _what.has_node("PickableCollision"):
			twohanded_collision = false
			#two_handed = _what.get_node("TwoHanded")
			col_dict = _what.get_node("PickableCollision").get_collider_dict()
			for key in col_dict.keys():
				_collider = key.duplicate()
				_collider.transform = col_dict[key]
				collider_list.append(_collider)
				self.add_child(_collider)
			held_body = _what
			self.add_collision_exception_with(held_body)


# Delete colliders used for held object
func remove_colliders() -> void:
	if twohanded_collision:
		twohanded_collision = false
	for col in collider_list:
		col.queue_free()
	collider_list = []
	if is_instance_valid(held_body):
		self.remove_collision_exception_with(held_body)


## Find an [XRToolsPlayerBody] node.
##
## This function searches from the specified node for an [XRToolsPlayerBody]
## assuming the node is a sibling of the body under an [XROrigin3D].
static func find_instance(node: Node) -> XRToolsCollisionHand:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_origin(node),
		"*",
		"XRToolsCollisionHand") as XRToolsCollisionHand
