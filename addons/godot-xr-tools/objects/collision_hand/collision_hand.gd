@tool
class_name XRToolsCollisionHand
extends CharacterBody3D


## THIS addition adds a KinematicBody that "chases" the controller THIS is a child
## off.
##
## THIS has a simple CollisionShape to simulate the empty hand and will copy
## the CollisionShapes of held objects and add them to THIS as children; then it
## will delete the copied CollisionShapes on drop.
##
## Optional Features: collision on pickables/ weight on pickables/ zero_g movement

@export_subgroup("Optional Collision")
# if set to true, pickable objects will have collision.
# best practice: use simple collision shapes for collision
# such as spheres, cubes, less is more
# Requirement Note:
# for pickables to have collision, they require the
# pickable_collision node to be instantiated
# as a child of the pickable object
# for twohanded_collision, the two_handed does not need the above
# since it contains the code for collision in the two_handed node
@export var pickable_collision : bool = false
@export_subgroup("Optional Weight")
# if set to true, pickable objects will have weight
# Additional Note:
# Zero-G Movement is set enabled on add colliders
# removed on remove colliders
@export var pickable_weight : bool = false
# lift up mass is used to produce a heavy lift up effect
# if the pickable touches any surface
@export var min_mass : float = 3
@export_subgroup("Optional Zero-G Movement")
# if set to true
# hands will have zero gravity movement
@export var zero_g : bool = false
# use 5 for zero gravity like movement
# best practice: set g_speed to 10 or 15 if using it with weight
@export var g_speed : float = 5

# Scene information
var _controller : XRController3D
var _pickup_function : XRToolsFunctionPickup
var palm_shape : CollisionShape3D = $PalmShape
# Get the gravity from the project settings to be synced
# with RigidDynamicBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var col_dict : Dictionary
# List of colliders added by grabbed objects
var collider_list : Array = []
var held_body : PhysicsBody3D
# check for collision when twohanded object is picked up
var twohanded_collision : bool = false
var start_speed : float
## Distance before dropping when stuck
@onready var max_distance : float = 0.2
@onready var _speed : float = 30.0
# _weight is set to true if pickable_weight is true, otherwise false
# this ensures that the current hand, once it drops
# the pickable gets its velocity reset
@onready var _weight : bool = false



# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsCollisionHand"

func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	start_speed = _speed

	# find the nodes we need
	_controller = XRTools.find_xr_ancestor(self, "*", "XRController3D")
	_pickup_function = XRTools.find_xr_child(self, "*", "XRToolsFunctionPickup")

	if pickable_collision:
		_pickup_function.has_picked_up.connect(add_colliders)
		_pickup_function.has_dropped.connect(remove_colliders)

	# Now for the magic settings,
	# this disjoins our node from our parents position.
	# Once set, global_transform = transform on this node.
	top_level = true

func _physics_process(_delta):
	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	if !_controller:
		# We're not a child of a controller node!
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
			# !BAS! Still experimental
			# This was using whatever _collider was last created on pickup,
			# not sure if that was intentional, I'm not entirely sure what
			# we're doing here.
			# Assigning the controller rotation definately is wrong.
			# I haven't had time to look into this further but will.
			var two_handed = XRTools.find_xr_child(held_body, "*", "XRToolsTwoHanded")
			if two_handed and two_handed.using_two_handed:
				for collider in collider_list:
					if two_handed.mod:
						collider.global_transform = _controller.global_transform.looking_at\
						(two_handed.second_hand_controller.global_transform.origin,Vector3.UP)
						_controller.rotation = two_handed.second_hand_controller.rotation.rotated\
						(two_handed.axis, two_handed.radians)
					collider.global_transform = _controller.global_transform.looking_at\
					(two_handed.second_hand_controller.global_transform.origin,Vector3.UP)
					collider.translate(Vector3(0,0,0)- held_body.get_active_grab_point().transform.origin)
			else:
				for collider in collider_list:
					collider.global_transform = held_body.get_active_grab_point().global_transform
					collider.translate(Vector3(0,0,0)- held_body.get_active_grab_point().transform.origin)

	move_to(_controller)
	_check_for_drop()


# With collision, move self toward target
func move_to(target : Node) -> void:
	var t_pos : Vector3 = target.global_transform.origin #Target Position
	var s_pos : Vector3 = self.global_transform.origin #Self Position

	var dir : Vector3 = t_pos - s_pos #Move Direction
	velocity = dir * _speed
	move_and_slide()

	# orientation is just copied
	self.global_transform.basis = target.global_transform.basis


func _check_for_drop():
	var c_pos = _controller.global_transform.origin #Controller Position
	var s_pos = self.global_transform.origin #Self Position

	# If we want to do it this way, we'll need to obtain the camera,
	# but I think my alternative works just fine
	# var face_pos = self.get_parent().global_transform.origin
	# var s_dist = s_pos.distance_to(face_pos)
	# var c_dist = c_pos.distance_to(face_pos)

	# if s_dist > c_dist + max_distance: #If object too far from face
	if c_pos.distance_to(s_pos) > max_distance: # Did we move to far away?
		# We're either stuck behind something,
		# or the weight of what we're holding is slowing us down too much.

		# Drop any held object
		if _pickup_function:
			_pickup_function.drop_object()
			remove_colliders()

		# Snap back into place
		self.transform = _controller.global_transform


# Requests a dictionary of CollisionShapes with Transforms from Spatial object
# for holding; else finds all CollisionShape children
# Format: {CollisionShape : Transform, CollisionShape : Transform,...}
func add_colliders(_what : Node3D) -> void:
	if is_instance_valid(_what):
		if pickable_weight:
			zero_g = true
			_weight = true
		var two_handed := XRTools.find_xr_child(_what, "*", "XRToolsTwoHanded")
		if two_handed :
			twohanded_collision = true
			col_dict = two_handed.get_collider_dict()
			for key in col_dict.keys():
				var collider = key.duplicate()
				collider.transform = col_dict[key]
				collider_list.append(collider)
				self.add_child(collider)
			held_body = _what
			self.add_collision_exception_with(held_body)

		var whats_pickable_collision := XRTools.find_xr_child(_what, "*", "XRToolsPickableCollision")
		if whats_pickable_collision :
			twohanded_collision = false
			col_dict = whats_pickable_collision.get_collider_dict()
			for key in col_dict.keys():
				var collider = key.duplicate()
				collider.transform = col_dict[key]
				collider_list.append(collider)
				self.add_child(collider)
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

	# No longer holding this...
	held_body = null

# This method verifies the hand has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	if not XRTools.find_xr_ancestor(self, "*", "XRController3D"):
		warnings.append("This node must be a child of an XRController3D node")

	if pickable_collision and not XRTools.find_xr_child(self, "*", "XRToolsFunctionPickup"):
		warnings.append("This node needs a pickup function to apply pickable collisions")

	return warnings

## Find an [XRToolsCollisionHand] node.
##
## This function searches from the specified node for an [XRToolsCollisionHand]
## assuming the node is a sibling of the body under an [XROrigin3D].
static func find_instance(node: Node) -> XRToolsCollisionHand:
	return XRTools.find_xr_child(
		XRHelpers.get_xr_origin(node),
		"*",
		"XRToolsCollisionHand") as XRToolsCollisionHand
