@tool
class_name XRToolsPoke
extends Node3D


## XR Tools Poke Script
##
## This node a finger push mechanism that can be attached to a finger bone
## using a [BoneAttachment3D].
##
## The poke can interact with user interfaces, and can optionally push rigid
## bodies.


## Signal emitted when this object pokes another object
signal pointing_event(event)


# Default layer of 18:player-hands
const DEFAULT_LAYER := 0b0000_0000_0000_0010_0000_0000_0000_0000

# Default mask [1..16] and 23:ui-objects
const DEFAULT_MASK := 0b0000_0000_0100_0000_1111_1111_1111_1111


## Enables or disables the poke functionality
@export var enabled : bool = true: set = set_enabled

## Sets the radius of the poke mesh and collision
@export var radius : float = 0.005: set = set_radius

## Set the color of the poke mesh
@export var color : Color = Color(0.8, 0.8, 1.0, 0.5): set = set_color

## Set the poke teleport distance
@export var teleport_distance : float = 0.1: set = set_teleport_distance

@export_category("Poke Collison")

## Sets the collision layer
@export_flags_3d_physics var layer : int = DEFAULT_LAYER: set = set_layer

## Sets the collision mask
@export_flags_3d_physics var mask : int = DEFAULT_MASK: set = set_mask

## Enables or disables pushing bodies
@export var push_bodies : bool = true: set = set_push_bodies

## Control the stiffness of the finger
@export var stiffness : float = 10.0: set = set_stiffness

## Control the maximum force the finger can push with
@export var maximum_force : float = 1.0: set = set_maximum_force


var is_ready = false
var material : StandardMaterial3D
var target : Node ## Node we last started touching
var last_collided_at : Vector3


func set_enabled(new_enabled : bool) -> void:
	enabled = new_enabled
	if is_ready:
		_update_enabled()

func _update_enabled():
	$PokeBody/CollisionShape.disabled = !enabled

func set_radius(new_radius : float) -> void:
	radius = new_radius
	if is_ready:
		_update_radius()

func _update_radius() -> void:
	# Calculate the user-scaled radius
	var sr := radius * XRServer.world_scale

	# Update the collision shape
	var shape : SphereShape3D = $PokeBody/CollisionShape.shape
	if shape:
		shape.radius = sr

	# Update the mesh shape
	var mesh : SphereMesh = $PokeBody/MeshInstance.mesh
	if mesh:
		mesh.radius = sr
		mesh.height = sr * 2.0

func set_teleport_distance(new_distance : float) -> void:
	teleport_distance = new_distance
	if is_ready:
		_update_teleport_distance()

func _update_teleport_distance() -> void:
	$PokeBody.teleport_distance = teleport_distance

func set_push_bodies(new_push_bodies : bool) -> void:
	push_bodies = new_push_bodies
	if is_ready:
		_update_push_bodies()

func _update_push_bodies() -> void:
	$PokeBody.push_bodies = push_bodies

func set_layer(new_layer : int) -> void:
	layer = new_layer
	if is_ready:
		_update_layer()

func _update_layer() -> void:
	$PokeBody.collision_layer = layer

func set_mask(new_mask : int) -> void:
	mask = new_mask
	if is_ready:
		_update_mask()

func _update_mask() -> void:
	$PokeBody.collision_mask = mask

func set_stiffness(new_stiffness : float) -> void:
	stiffness = new_stiffness
	if is_ready:
		_update_stiffness()

func _update_stiffness() -> void:
	$PokeBody.stiffness = stiffness

func set_maximum_force(new_maximum_force : float) -> void:
	maximum_force = new_maximum_force
	if is_ready:
		_update_maximum_force()

func _update_maximum_force() -> void:
	$PokeBody.maximum_force = maximum_force

func set_color(new_color : Color) -> void:
	color = new_color
	if is_ready:
		_update_color()

func _update_color() -> void:
	if material:
		material.albedo_color = color


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsPoke"


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set as top level ensures we're placing this object in global space
	$PokeBody.set_as_top_level(true)

	is_ready = true

	# Construct the poke material
	material = StandardMaterial3D.new()
	material.flags_unshaded = true
	material.flags_transparent = true
	$PokeBody/MeshInstance.set_surface_override_material(0, material)

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


func _process(_delta):
	# If no target then disable processing
	if not is_instance_valid(target):
		set_process(false)
		return

	# Update moving on the target
	var new_at : Vector3 = $PokeBody.global_transform.origin
	XRToolsPointerEvent.moved(self, target, new_at, last_collided_at)
	last_collided_at = new_at


func _on_hand_scale_changed(_scale : float) -> void:
	# Update the radius to account for the new hand scale
	_update_radius()


func _on_PokeBody_body_contact_start(body):
	# We are going to poke this body at our current position.
	# This will be slightly above the object but since this
	# mostly targets Viewport2Din3D, this will work

	# Report body pressed
	target = body
	last_collided_at = $PokeBody.global_transform.origin
	XRToolsPointerEvent.entered(self, body, last_collided_at)
	XRToolsPointerEvent.pressed(self, body, last_collided_at)

	# Enable processing to track movement
	set_process(true)


func _on_PokeBody_body_contact_end(body):
	# Skip if not current target
	if body != target:
		return

	# Report release
	XRToolsPointerEvent.released(self, target, last_collided_at)
	XRToolsPointerEvent.exited(self, target, last_collided_at)
	target = null
