tool
class_name XRToolsPoke
extends Spatial


export var enabled : bool = true setget set_enabled
export var radius : float = 0.005 setget set_radius
export var teleport_distance : float = 0.1 setget set_teleport_distance
export var color : Color = Color(0.8, 0.8, 1.0, 0.5) setget set_color


var is_ready = false
var material : SpatialMaterial
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
	var shape : SphereShape = $PokeBody/CollisionShape.shape
	if shape:
		shape.radius = radius

	var mesh : SphereMesh = $PokeBody/MeshInstance.mesh
	if mesh:
		mesh.radius = radius
		mesh.height = radius * 2.0

	if material:
		$PokeBody/MeshInstance.set_surface_material(0, material)

func set_teleport_distance(new_distance : float) -> void:
	teleport_distance = new_distance
	if is_ready:
		_update_set_teleport_distance()

func _update_set_teleport_distance() -> void:
	$PokeBody.teleport_distance = teleport_distance

func set_color(new_color : Color) -> void:
	color = new_color
	if is_ready:
		_update_color()

func _update_color() -> void:
	if material:
		material.albedo_color = color


# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsPoke" or .is_class(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# Set as top level ensures we're placing this object in global space
	$PokeBody.set_as_toplevel(true)

	is_ready = true
	material = SpatialMaterial.new()
	material.flags_unshaded = true
	material.flags_transparent = true

	_update_enabled()
	_update_radius()
	_update_set_teleport_distance()
	_update_color()

func _process(_delta):
	if is_instance_valid(target):
		var new_at = $PokeBody.global_transform.origin

		if target.has_signal("pointer_moved"):
			target.emit_signal("pointer_moved", last_collided_at, new_at)
		elif target.has_method("pointer_moved"):
			target.pointer_moved(last_collided_at, new_at)

		last_collided_at = new_at
	else:
		set_process(false)


func _on_PokeBody_body_entered(body):
	# We are going to poke this body at our current position.
	# This will be slightly above the object but since this
	# mostly targets Viewport2Din3D, this will work

	if body.has_signal("pointer_pressed"):
		target = body
		last_collided_at = $PokeBody.global_transform.origin
		target.emit_signal("pointer_pressed", last_collided_at)
	elif body.has_method("pointer_pressed"):
		target = body
		last_collided_at = $PokeBody.global_transform.origin
		target.pointer_pressed(last_collided_at)

	if target:
		set_process(true)

func _on_PokeBody_body_exited(body):
	if body.has_signal("pointer_released"):
		body.emit_signal("pointer_released", last_collided_at)
	elif body.has_method("pointer_released"):
		body.pointer_released(last_collided_at)

	# if we were tracking this target, clear it
	if target == body:
		target = null
