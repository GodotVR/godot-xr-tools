@tool
class_name XRToolsPoke
extends Node3D

## XR Tools Poke Script
##
## This node is a finger push mechanism that can be attached to a finger bone
## using a [BoneAttachment3D].
##
## The poke can interact with user interfaces, and can optionally push rigid
## bodies.


## Emitted when this object pokes another object
signal pointing_event(event: XRToolsPointerEvent)


## Default layer of 18:player-hands
const DEFAULT_LAYER := 0b0000_0000_0000_0010_0000_0000_0000_0000

## Default mask [1..16] and 23:ui-objects
const DEFAULT_MASK := 0b0000_0000_0100_0000_1111_1111_1111_1111


## Toggles poking
@export var enabled := true: set = set_enabled

## Radius of the poke mesh and collision
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var radius := 0.005:
	set = set_radius

## Color of the poke mesh
@export var color := Color(0.8, 0.8, 1.0, 0.5): set = set_color

## Poke teleport distance
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var teleport_distance := 0.1:
	set = set_teleport_distance

@export_group("Poke Collison")

## Collision layer
@export_flags_3d_physics var layer := DEFAULT_LAYER: set = set_layer

## Collision mask
@export_flags_3d_physics var mask := DEFAULT_MASK: set = set_mask

## Toggles pushing bodies
@export var push_bodies := true: set = set_push_bodies

## Stiffness of the finger
@export var stiffness := 10.0: set = set_stiffness

## Control the maximum force the finger can push with
@export var maximum_force := 1.0: set = set_maximum_force


## Ensures that the node operates at top level before running any code
var is_ready := false

## [Material] of the [MeshInstance3D] child of the [XRToolsPokeBody]
var material: StandardMaterial3D

## Node we last started touching
var target: Node

## Position of the last collision
var last_collided_at: Vector3

# [AnimatableBody3D] that is used to push objects
var _poke_body: XRToolsForceBody

# [CollisionShape3D] of the Poke Body
var _poke_collider: CollisionShape3D

# [MeshInstance3D] of the Poke Body
var _poke_mesh: MeshInstance3D


# When the node enters the scene tree for the first time.
func _ready() -> void:
	_poke_body = $PokeBody
	_poke_collider = $PokeBody/CollisionShape
	_poke_mesh = $PokeBody/MeshInstance

	# Set as top level ensures we're placing this object in global space
	_poke_body.set_as_top_level(true)

	is_ready = true

	# Construct the poke material
	material = StandardMaterial3D.new()
	material.flags_unshaded = true
	material.flags_transparent = true
	_poke_mesh.set_surface_override_material(0, material)

	_update_enabled()
	_update_radius()
	_update_teleport_distance()
	_update_layer()
	_update_mask()
	_update_push_bodies()
	_update_stiffness()
	_update_maximum_force()
	_update_color()

	# Detect hand scale changing
	var hand := XRToolsHand.find_instance(self)
	if hand:
		hand.hand_scale_changed.connect(_on_hand_scale_changed)


func _process(_delta: float) -> void:
	# If no target then disable processing
	if not is_instance_valid(target):
		set_process(false)
		return

	# Update moving on the target
	var new_at: Vector3 = _poke_body.global_transform.origin
	XRToolsPointerEvent.moved(self, target, new_at, last_collided_at)
	last_collided_at = new_at


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsPoke"


func set_color(new_color: Color) -> void:
	color = new_color
	if is_ready:
		_update_color()


func set_enabled(new_enabled: bool) -> void:
	enabled = new_enabled
	if is_ready:
		_update_enabled()


func set_layer(new_layer: int) -> void:
	layer = new_layer
	if is_ready:
		_update_layer()


func set_mask(new_mask: int) -> void:
	mask = new_mask
	if is_ready:
		_update_mask()


func set_maximum_force(new_maximum_force: float) -> void:
	maximum_force = new_maximum_force
	if is_ready:
		_update_maximum_force()


func set_push_bodies(new_push_bodies: bool) -> void:
	push_bodies = new_push_bodies
	if is_ready:
		_update_push_bodies()


func set_radius(new_radius : float) -> void:
	radius = new_radius
	if is_ready:
		_update_radius()


func set_stiffness(new_stiffness: float) -> void:
	stiffness = new_stiffness
	if is_ready:
		_update_stiffness()


func set_teleport_distance(new_distance: float) -> void:
	teleport_distance = new_distance
	if is_ready:
		_update_teleport_distance()


func _on_hand_scale_changed(_scale: float) -> void:
	# Update the radius to account for the new hand scale
	_update_radius()


func _on_PokeBody_body_contact_end(body: Node3D) -> void:
	# Skip if not current target
	if body != target:
		return

	# Report release
	XRToolsPointerEvent.released(self, target, last_collided_at)
	XRToolsPointerEvent.exited(self, target, last_collided_at)
	target = null


# Pokes a body at our current position.
# This will be slightly above the object, but since this
# mostly targets Viewport2Din3D, this will work
func _on_PokeBody_body_contact_start(body: Node3D) -> void:
	# Report body pressed
	target = body
	last_collided_at = _poke_body.global_transform.origin
	XRToolsPointerEvent.entered(self, body, last_collided_at)
	XRToolsPointerEvent.pressed(self, body, last_collided_at)

	# Enable processing to track movement
	set_process(true)


func _update_color() -> void:
	if material:
		material.albedo_color = color


func _update_enabled() -> void:
	_poke_collider.disabled = not enabled


func _update_layer() -> void:
	_poke_body.collision_layer = layer


func _update_mask() -> void:
	_poke_body.collision_mask = mask


func _update_maximum_force() -> void:
	_poke_body.maximum_force = maximum_force


func _update_push_bodies() -> void:
	_poke_body.push_bodies = push_bodies


func _update_radius() -> void:
	# Calculate the user-scaled radius
	var sr := radius * XRServer.world_scale

	# Update the collision shape
	var shape: SphereShape3D = _poke_collider.shape
	if shape:
		shape.radius = sr

	# Update the mesh shape
	var mesh: SphereMesh = _poke_mesh.mesh
	if mesh:
		mesh.radius = sr
		mesh.height = sr * 2.0


func _update_stiffness() -> void:
	_poke_body.stiffness = stiffness


func _update_teleport_distance() -> void:
	_poke_body.teleport_distance = teleport_distance
