@tool
extends Node3D

@export var player_camera : Camera3D

@export_range(0.005, 1.000, 0.005) var radius : float = 0.025:
	set(value):
		radius = value
		if is_inside_tree():
			_update_radius()

func _update_radius():
	var mesh : QuadMesh = $DisplayMesh.mesh
	if mesh:
		# make our mesh fit
		mesh.size = Vector2(radius*2.0, radius*2.0)

	var material : ShaderMaterial = $DisplayMesh.material_override
	if material:
		material.set_shader_parameter("radius", radius)

@export_range(0.001, 0.500, 0.001) var offset : float = 0.35:
	set(value):
		offset = value
		if is_inside_tree():
			_update_offset()

func _update_offset():
	$ScopeAnchor.position.z = -offset
	if Engine.is_editor_hint():
		# In runtime this is positioned in global space through our RemoteTransform3D
		$SubViewport/Camera3D.global_transform = $ScopeAnchor.global_transform

	var material : ShaderMaterial = $DisplayMesh.material_override
	if material:
		material.set_shader_parameter("depth", offset)

@export_range(1.0, 10.0, 0.1) var fov : float = 10.0:
	set(value):
		fov = value
		if is_inside_tree():
			_update_fov()

func _update_fov():
	$SubViewport/Camera3D.fov = fov

func _ready():
	_update_radius()
	_update_offset()
	_update_fov()

func _process(_delta):
	if !player_camera:
		return

	# Check if our display is in view of our camera, only update scope if it is...
	var view_dir = -player_camera.global_transform.basis.z
	var scope_dir = -global_transform.basis.z
	var dot = view_dir.dot(scope_dir)

	if dot > 0.9:
		$SubViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	else:
		$SubViewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
