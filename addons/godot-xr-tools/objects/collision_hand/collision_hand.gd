@tool
## adds collision to the Open_XR Hands
## ________________________________________________________
## a CharacterBody3D that follows the corresponding XRController3D.
## it is able to collide with the world and with static objects
## ________________________________________________________
## OPTIONAL FEATURES:
## ________________________________________________________
## collision on pickables/ weight on pickables/ zero_g movement

class_name XRToolsCollisionHand
extends CharacterBody3D

#
# THIS addition adds a KinematicBody that "chases" the controller THIS is assigned
# to. THIS has a simple CollisionShape to simulate the empty hand and will copy
# the CollisionShapes of held objects and add them to THIS as children; then it
# will delete the copied CollisionShapes on drop.

@export_group("Collision Hand Setup")

## select controller
@export var controller_path : NodePath

## select visual hand
@export var _hand_path : NodePath

## select function_pickup
@export var _pickup_path : NodePath #Should be child of ARVRController

@export_subgroup("Optional Collision")
## if set to true, pickable objects will have collision.
## ________________________________________________________
## best practice: use simple collision shapes for collision
## such as spheres, cubes, less is more
## ________________________________________________________
## Requirement Note:
## ________________________________________________________
## for pickables to have collision, they require the
## pickable_collision node to be instantiated
## as a child of the pickable object
## ________________________________________________________
## for twohanded_collision, the two_handed does not need the above
## since it contains the code for collision in the two_handed node
@export var pickable_collision : bool = false
@export_subgroup("Optional Weight")
## if set to true, pickable objects will have weight
## ________________________________________________________
## Additional Note:
## ________________________________________________________
## Zero-G Movement is set enabled on add colliders
## removed on remove colliders
@export var pickable_weight : bool = false
## lift up mass is used to produce a heavy lift up effect
## if the pickable touches any surface
@export var min_mass : float = 3
@export_subgroup("Optional Zero-G Movement")
## if set to true
## hands will have zero gravity movement
@export var zero_g : bool = false
## use 5 for zero gravity like movement
## ________________________________________________________
## best practice: set g_speed to 10 or 15 if using it with weight
@export var g_speed : float = 5


## Distance before dropping when stuck
@onready var max_distance : float = 0.2
@onready var _speed : float = 30.0

@onready var controller : XRController3D = get_node(controller_path)
@onready var _hand = get_node(_hand_path)
@onready var _pickup = get_node(_pickup_path)
@onready var palm_shape : CollisionShape3D = $PalmShape
@onready var hand_remote : RemoteTransform3D = $HandRemoteTransform3D
@onready var pickup_remote : RemoteTransform3D = $PickupRemoteTransform3D
# Get the gravity from the project settings to be synced
# with RigidDynamicBody nodes.
@onready var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
@onready var col_dict : Dictionary
# List of colliders added by grabbed objects
@onready var collider_list : Array = [] 
@onready var held_body : PhysicsBody3D
# check for collision when twohanded object is picked up
@onready var twohanded_collision : bool = false
@onready var start_speed : float
# _weight is set to true if pickable_weight is true, otherwise false
# this ensures that the current hand, once it drops
# the pickable gets its velocity reset
@onready var _weight : bool = false

var _what 
var _collider
var two_handed


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsCollisionHand"

func _ready():
	start_speed = _speed

	hand_remote.set_transform(_hand.get_transform())
	hand_remote.remote_path = _hand.get_path()
	pickup_remote.set_transform(_pickup.get_transform())
	pickup_remote.remote_path = _pickup.get_path()

	if pickable_collision:
		_pickup.has_picked_up.connect(add_colliders)
		_pickup.has_dropped.connect(remove_colliders)


func _physics_process(_delta):
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	if zero_g:
		_speed = g_speed
	else:
		_speed = start_speed

	if is_instance_valid(held_body):
		if _weight:
			if held_body.is_picked_up():
				# here we use divide by two like this = /2
				# to ensure that there is no twitching
				velocity.y -= move_toward(held_body.linear_velocity.y, gravity, held_body.mass) / 2
				# if the pickables mass is higher,
				# we use apply_floor_snap to produce some kind
				# of heavy lift up effect
				if held_body.mass >= min_mass:
					apply_floor_snap()
				move_and_slide()

		if twohanded_collision:
			two_handed = held_body.get_node("TwoHanded")
			if two_handed.using_two_handed:
				if two_handed.mod:
					_collider.global_transform = controller.global_transform.looking_at(two_handed.second_hand_controller.global_transform.origin,Vector3.UP)
					controller.rotation = two_handed.second_hand_controller.rotation.rotated(two_handed.axis, two_handed.radians)
				_collider.global_transform = controller.global_transform.looking_at(two_handed.second_hand_controller.global_transform.origin,Vector3.UP)
				_collider.translate(Vector3(0,0,0)- held_body.get_active_grab_point().transform.origin)
			else:
				_collider.global_transform = held_body.get_active_grab_point().global_transform
				_collider.translate(Vector3(0,0,0)- held_body.get_active_grab_point().transform.origin)

	move_to(controller)
	_check_for_drop()


# With collision, move self toward target
func move_to(target : Node) -> void:
	var t_pos : Vector3 = target.global_transform.origin #Target Position
	var s_pos : Vector3 = self.global_transform.origin #Self Position

	var dir : Vector3 = t_pos - s_pos #Move Direction
	velocity = dir * _speed
	move_and_slide()
	self.set_rotation(controller.rotation)


func _check_for_drop():
	var c_pos = controller.global_transform.origin #Controller Position
	var s_pos = self.global_transform.origin #Self Position

	var face_pos = self.get_parent().global_transform.origin
	var s_dist = s_pos.distance_to(face_pos)
	var c_dist = c_pos.distance_to(face_pos)

	if s_dist > c_dist + max_distance: #If object too far from face
		_pickup.drop_object()
		remove_colliders()
		self.transform = controller.transform


# Requests a dictionary of CollisionShapes with Transforms from Spatial object
# for holding; else finds all CollisionShape children
# Format: {CollisionShape : Transform, CollisionShape : Transform,...}
func add_colliders(_what : Node3D) -> void:
	if is_instance_valid(_what):
		if pickable_weight:
			zero_g = true
			_weight = true
		if _what.has_node("TwoHanded"):
			twohanded_collision = true
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
	if pickable_weight:
		_weight = false
		zero_g = false
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
