extends Spatial

export var radius = 1.0 setget set_radius
export var steps = 16 setget set_steps

var material : ShaderMaterial = preload("res://addons/godot-xr-tools/effects/vignette.material")

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

# Called when the node enters the scene tree for the first time.
func _ready():
	_update_mesh()
	_update_radius()
