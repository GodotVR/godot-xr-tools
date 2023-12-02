@tool
class_name XRToolsHandPhysicsBone
extends BoneAttachment3D


## XR Tools Physics Hand Bone
##
## This script adds a physics-bone to a godot-xr-tools physics hand.
##
## It extends from [BoneAttachment3D] to track the position of the bone in
## the hand skeleton, and uses this position to move a [CharacterBody3D]
## physics-bone with a [CapsuleShape3D] collider.
##
## The physics-bone is manually driven with to the position and rotation of the
## skeletal-bone. The physics-bone is set as top-level to prevent the
## physics-bone from inheriting any hand scaling as this would scale the
## collider which the physics engine cannot tolerate.
##
## To handle scaling, this script subscribes to the hand_scale_changed signal
## emitted by the [XRToolsHand] script and manually adjusts the [CapsuleShape3D]
## collider of the physics-bone to keep it sized appropriately.
##
## There are additional collision and group settings for this specific
## bone, which allows per-bone collision detection.


## Length of the physics-bone
@export var length : float = 0.03

## Ratio of bone length to width
@export var width_ratio : float = 0.3

## Additional collision layer for this one bone
@export_flags_3d_physics var collision_layer : int = 0

## Additional bone group for this one bone
@export var bone_group : String = ""


# Physics-bone collider shape
var _bone_shape : CapsuleShape3D

# Physics-bone body node
var _physics_bone : CharacterBody3D

# Node attached to the skeletal-bone, and the target of the physics-bone
var _skeletal_bone : Node3D


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsHandPhysicsBone"


# Called when the node enters the scene tree. This constructs the physics-bone
# nodes and performs initial positioning.
func _ready():
	# Skip if in the editor
	if Engine.is_editor_hint():
		return

	# Connect the 'hand_scale_changed' signal
	var physics_hand := XRToolsHand.find_instance(self) as XRToolsPhysicsHand
	if physics_hand:
		physics_hand.hand_scale_changed.connect(_on_hand_scale_changed)

	# Construct the physics-bone shape
	_bone_shape = CapsuleShape3D.new()
	_bone_shape.margin = physics_hand.margin
	_on_hand_scale_changed(XRServer.world_scale)

	# Construct the physics-bone collision shape
	var bone_collision := CollisionShape3D.new()
	bone_collision.set_name("BoneCollision")
	bone_collision.shape = _bone_shape
	#bone_collision.transform.basis = Basis(Vector3.RIGHT, PI/2)

	# Construct the physics-bone body
	_physics_bone = CharacterBody3D.new()
	_physics_bone.set_name("BoneBody")
	_physics_bone.set_as_top_level(true)
	_physics_bone.collision_layer = physics_hand.collision_layer | collision_layer
	_physics_bone.collision_mask = 0
	_physics_bone.add_child(bone_collision)

	# Set the optional bone group for all bones in the hand
	if not physics_hand.bone_group.is_empty():
		_physics_bone.add_to_group(physics_hand.bone_group)

	# Set the optional bone group for this one bone
	if not bone_group.is_empty():
		_physics_bone.add_to_group(bone_group)

	# Construct the bone middle spatial
	_skeletal_bone = Node3D.new()
	_skeletal_bone.transform.origin = Vector3.UP * length / 2

	# Add the physics-bone body to this hand bone
	add_child(_physics_bone)
	add_child(_skeletal_bone)

	# Perform initial teleport of the phsysics-bone to the skeletal-bone
	_teleport_bone()


# Called during the physics process and moves the physics-bone to follow the
# skeletal-bone.
func _physics_process(delta: float) -> void:
	# Skip if in the editor
	if Engine.is_editor_hint():
		return

	_move_bone(delta)


# This method moves the physics-bone to the skeletal-bone by first doing a
# move_and_slide as this works well for collision-interactions. It then
# rotates the physics-bone to match the skeletal-bone.
func _move_bone(delta: float) -> void:
	# Get the skeletal-bone transform
	var bone_xform := _skeletal_bone.global_transform

	# Get the required velocity to move the physics-bone to the skeletal-bone
	var bone_vel := (bone_xform.origin - _physics_bone.global_transform.origin) / delta

	# Move the physics-bone into position
	_physics_bone.velocity = bone_vel
	_physics_bone.move_and_slide()

	# Rotate the physics-bone into the correct rotation
	_physics_bone.global_transform.basis = bone_xform.basis


# This method teleports the physics-bone to the skeletal-bone.
func _teleport_bone() -> void:
	# Get the bone transform
	var bone_xform := _skeletal_bone.global_transform

	# Set the bone position
	_physics_bone.global_transform = Transform3D(
		Basis(bone_xform.basis.get_rotation_quaternion()),
		bone_xform.origin)


# This method handles changes to the hand scale by adjusting the
# physics-bone collider shape to match.
func _on_hand_scale_changed(scale: float) -> void:
	# Get the scaled length and width
	var length_scaled := length * scale
	var width_scaled := length_scaled * width_ratio

	# Adjust the shape
	_bone_shape.radius = width_scaled
	_bone_shape.height = length_scaled
