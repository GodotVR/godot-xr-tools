extends EditorNode3DGizmoPlugin


## Editor Gizmo for [XRToolsInteractableSliderOrigin]
##
## This editor gizmo helps align interactable slider joints.


var undo_redo : EditorUndoRedoManager


func _init() -> void:
	create_material("extent", Color(1, 1, 0, 0.3), false, true)
	create_handle_material("handles")


func _get_gizmo_name() -> String:
	return "InteractableSliderOrigin"


func _get_handle_name(
	_gizmo : EditorNode3DGizmo,
	p_handle_id : int,
	_secondary : bool) -> String:
	# Return minimum or maximum handle name
	return "Minimum" if p_handle_id == 0 else "Maximum"


func _get_handle_value(
	p_gizmo : EditorNode3DGizmo,
	p_handle_id : int,
	_secondary : bool) -> Variant:
	# Return limit
	return _get_limit(p_gizmo.get_node_3d(), p_handle_id)


func _set_handle(
	p_gizmo : EditorNode3DGizmo,
	p_handle_id : int,
	_secondary : bool,
	p_camera : Camera3D,
	p_screen_pos : Vector2) -> void:
	# Get the slider origin node
	var origin : XRToolsInteractableSliderOrigin = p_gizmo.get_node_3d()
	var origin_pos := origin.global_position
	var origin_dir := origin.global_transform.basis.x

	# Build the normal vector pointing to the camera but orthoginal to the slide
	var to_camera := p_camera.global_position - origin_pos
	to_camera = to_camera.slide(origin_dir).normalized()

	# Construct the plane
	var plane := Plane(to_camera, origin_pos)

	# Find the intersection between the ray and the plane
	var v_intersect = plane.intersects_ray(
		p_camera.global_position,
		p_camera.project_ray_normal(p_screen_pos))
	if not v_intersect:
		return

	# Set the limit
	var local := origin.to_local(v_intersect)
	var limit := snappedf(local.x, 0.01)
	_set_limit(origin, p_handle_id, limit)


func _commit_handle(
	p_gizmo : EditorNode3DGizmo,
	p_handle_id : int,
	_secondary : bool,
	p_restore : Variant,
	p_cancel : bool) -> void:
	# Get the slider origin node
	var origin : XRToolsInteractableSliderOrigin = p_gizmo.get_node_3d()

	# If canceling then restore limit
	if p_cancel:
		_set_limit(origin, p_handle_id, p_restore)
		return

	# Commit the handle change
	match p_handle_id:
		0:
			undo_redo.create_action("Set interactable slider limit_minimum")
			undo_redo.add_do_method(origin, "set_limit_minimum", origin.limit_minimum)
			undo_redo.add_undo_method(origin, "set_limit_minimum", p_restore)
			undo_redo.commit_action()
		1:
			undo_redo.create_action("Set interactable slider limit_maximum")
			undo_redo.add_do_method(origin, "set_limit_maximum", origin.limit_maximum)
			undo_redo.add_undo_method(origin, "set_limit_maximum", p_restore)
			undo_redo.commit_action()


func _has_gizmo(p_node : Node3D) -> bool:
	return p_node is XRToolsInteractableSliderOrigin


func _redraw(p_gizmo : EditorNode3DGizmo) -> void:
	# Clear the current gizmo contents
	p_gizmo.clear()

	# Get the slider origin and its extents
	var origin : XRToolsInteractableSliderOrigin = p_gizmo.get_node_3d()
	var min_x := origin.limit_minimum
	var max_x := origin.limit_maximum
	var mid_x := (min_x + max_x) * 0.5
	var width := (max_x - min_x) * 0.1

	# Construct an immediate mesh for the extent
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	mesh.surface_add_vertex(Vector3(mid_x, -width, 0.0))
	mesh.surface_add_vertex(Vector3(min_x, 0.0, 0.0))
	mesh.surface_add_vertex(Vector3(mid_x, width, 0.0))
	mesh.surface_add_vertex(Vector3(mid_x, -width, 0.0))
	mesh.surface_add_vertex(Vector3(max_x, 0.0, 0.0))
	mesh.surface_add_vertex(Vector3(mid_x, width, 0.0))
	mesh.surface_add_vertex(Vector3(mid_x, 0.0, -width))
	mesh.surface_add_vertex(Vector3(min_x, 0.0, 0.0))
	mesh.surface_add_vertex(Vector3(mid_x, 0.0, width))
	mesh.surface_add_vertex(Vector3(mid_x, 0.0, -width))
	mesh.surface_add_vertex(Vector3(max_x, 0.0, 0.0))
	mesh.surface_add_vertex(Vector3(mid_x, 0.0, width))
	mesh.surface_end()

	# Draw the extent mesh
	p_gizmo.add_mesh(mesh, get_material("extent", p_gizmo))

	# Add the handles
	var handles := PackedVector3Array()
	handles.push_back(_get_limit_pos(origin, 0))
	handles.push_back(_get_limit_pos(origin, 1))
	p_gizmo.add_handles(handles, get_material("handles", p_gizmo), [])


# Get the limit of a slider by handle
func _get_limit(
	p_origin : XRToolsInteractableSliderOrigin,
	p_handle_id : int) -> float:
	# Read the limit
	match p_handle_id:
		0:
			return p_origin.limit_minimum
		1:
			return p_origin.limit_maximum
		_:
			return 0.0


# Get the limit position of a slider by handle
func _get_limit_pos(
	p_origin : XRToolsInteractableSliderOrigin,
	p_handle_id : int) -> Vector3:
	# Return the limit position
	return Vector3(_get_limit(p_origin, p_handle_id), 0, 0)


# Set the limit of a slider by handle
func _set_limit(
	p_origin : XRToolsInteractableSliderOrigin,
	p_handle_id : int,
	p_limit : float) -> void:
	# Apply the limit
	match p_handle_id:
		0:
			p_origin.limit_minimum = p_limit
		1:
			p_origin.limit_maximum = p_limit
