tool
extends Spatial

export var radius = 1.0 setget set_radius
export var fade = 0.05 setget set_fade
export var steps = 32 setget set_steps

export var auto_adjust = true setget set_auto_adjust
export var auto_inner_radius = 0.35
export var auto_fade_out_factor = 1.5
export var auto_fade_delay = 1.0
export var auto_rotation_limit = 20.0 setget set_auto_rotation_limit
export var auto_velocity_limit = 10.0

var material : ShaderMaterial = preload("res://addons/godot-xr-tools/effects/vignette.material")

var auto_first = true
var fade_delay = 0.0
var origin_node = null
var last_origin_basis : Basis
var last_location : Vector3
onready var auto_rotation_limit_rad = deg2rad(auto_rotation_limit)

func set_radius(new_radius):
	radius = new_radius
	if is_inside_tree():
		_update_radius()

func _update_radius():
	if radius < 1.0:
		if material:
			material.set_shader_param("radius", radius * sqrt(2))
		$Mesh.visible = true
	else:
		$Mesh.visible = false

func set_fade(new_fade):
	fade = new_fade
	if is_inside_tree():
		_update_fade()

func _update_fade():
	if material:
		material.set_shader_param("fade", fade)


func set_steps(new_steps):
	steps = new_steps
	if is_inside_tree():
		_update_mesh()

func _update_mesh():
	var vertices : PoolVector3Array
	var indices : PoolIntArray

	vertices.resize(2 * steps)
	indices.resize(6 * steps)
	for i in steps:
		var v : Vector3 = Vector3.RIGHT.rotated(Vector3.FORWARD, deg2rad((360.0 * i) / steps))
		vertices[i] = v
		vertices[steps+i] = v * 2.0

		var off = i * 6
		var i2 = ((i + 1) % steps)
		indices[off + 0] = steps + i
		indices[off + 1] = steps + i2
		indices[off + 2] = i2
		indices[off + 3] = steps + i
		indices[off + 4] = i2
		indices[off + 5] = i

	# update our mesh
	var arr_mesh = ArrayMesh.new()
	var arr : Array
	arr.resize(ArrayMesh.ARRAY_MAX)
	arr[ArrayMesh.ARRAY_VERTEX] = vertices
	arr[ArrayMesh.ARRAY_INDEX] = indices
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)

	$Mesh.mesh = arr_mesh
	$Mesh.set_surface_material(0, material)

func set_auto_adjust(new_auto_adjust):
	auto_adjust = new_auto_adjust
	if is_inside_tree() and !Engine.editor_hint:
		_update_auto_adjust()

func _update_auto_adjust():
	# Turn process on if auto adjust is true.
	# Note we don't turn it off here, we want to finish fading out the vignette if needed
	if auto_adjust:
		set_process(true)

func set_auto_rotation_limit(new_auto_rotation_limit):
	auto_rotation_limit = new_auto_rotation_limit
	auto_rotation_limit_rad = deg2rad(auto_rotation_limit)

func _get_origin_node() -> ARVROrigin:
	var parent = get_parent()
	while parent:
		if parent and parent is ARVROrigin:
			return parent
		parent = parent.get_parent()

	return null

# Called when the node enters the scene tree for the first time.
func _ready():
	if !Engine.editor_hint:
		origin_node = _get_origin_node()
		_update_mesh()
		_update_radius()
		_update_fade()
		_update_auto_adjust()
	else:
		set_process(false)

# Called on process
func _process(delta):
	if Engine.editor_hint:
		return

	if !origin_node:
		return

	if !auto_adjust:
		# set to true for next time this is enabled
		auto_first = true

		# We are done, turn off process
		set_process(false)

		return

	if auto_first:
		# first time we run process since starting, just record transform
		last_origin_basis = origin_node.global_transform.basis
		last_location = global_transform.origin
		auto_first = false
		return

	# Get our delta transform
	var delta_b = origin_node.global_transform.basis * last_origin_basis.inverse()
	var delta_v = global_transform.origin - last_location

	# Adjust radius based on rotation speed of our origin point (not of head movement).
	# We convert our delta rotation to a quaterion.
	# A quaternion represents a rotation around an angle. 
	var q = delta_b.get_rotation_quat()

	# We get our angle from our w component and then adjust to get a 
	# rotation speed per second by dividing by delta
	var angle = (2 * acos(q.w)) / delta

	# Calculate what our radius should be for our rotation speed
	var target_radius = 1.0
	if auto_rotation_limit > 0:
		target_radius = 1.0 - (clamp(angle / auto_rotation_limit_rad, 0.0, 1.0) * (1.0 - auto_inner_radius))

	# Now do the same for speed, this includes players physical speed but there isn't much we can do there.
	if auto_velocity_limit > 0:
		var velocity = delta_v.length() / delta
		target_radius = min(target_radius, 1.0 - (clamp(velocity / auto_velocity_limit, 0.0, 1.0) * (1.0 - auto_inner_radius)))

	# if our radius is small then our current we apply it
	if target_radius < radius:
		set_radius(target_radius)
		fade_delay = auto_fade_delay
	elif fade_delay > 0.0:
		fade_delay -= delta
	else: 
		set_radius(clamp(radius + delta / auto_fade_out_factor, 0.0, 1.0))

	last_origin_basis = origin_node.global_transform.basis
	last_location = global_transform.origin

# This method verifies the vignette has a valid configuration.
# Specifically it checks the following:
# - ARVROrigin is a parent
# - ARVRCamera is our parent
func _get_configuration_warning():
	# Check the origin node
	var node = _get_origin_node()
	if !node: 
		return "Parent node must be in a branch from ARVROrigin"
	
	# check camera node
	var parent = get_parent()
	if !parent or !parent is ARVRCamera:
		return "Parent node must be an ARVRCamera"

	return ""
