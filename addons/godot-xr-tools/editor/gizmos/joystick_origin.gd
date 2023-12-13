extends EditorNode3DGizmoPlugin


## Editor Gizmo for [XRToolsInteractableJoystickOrigin]
##
## This editor gizmo helps align interactable joystick joints.


var undo_redo : EditorUndoRedoManager


func _init() -> void:
	create_material("extent", Color(1, 1, 0, 0.3), false, true)
	create_handle_material("handles")


func _get_gizmo_name() -> String:
	return "InteractableJoystickOrigin"


func _get_handle_name(
	_gizmo : EditorNode3DGizmo,
	p_handle_id : int,
	_secondary : bool) -> String:
	# Return handle name
	if p_handle_id == 0: return "Minimum X"
	if p_handle_id == 1: return "Maximum X"
	if p_handle_id == 2: return "Minimum Y"
	return "Maximum Y"


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
	# Get the hinge origin node
	var origin : XRToolsInteractableJoystickOrigin = p_gizmo.get_node_3d()
	var origin_pos := origin.global_position
	var origin_dir_x := origin.global_transform.basis.y
	var origin_dir_y := -origin.global_transform.basis.x

	# Construct the plane
	var plane : Plane
	if p_handle_id < 2:
		plane = Plane(origin_dir_x, origin_pos)
	else:
		plane = Plane(origin_dir_y, origin_pos)

	# Find the intersection between the ray and the plane
	var v_intersect = plane.intersects_ray(
		p_camera.global_position,
		p_camera.project_ray_normal(p_screen_pos))
	if not v_intersect:
		return

	# Find the local position
	var local := origin.to_local(v_intersect)
	var old_local := _get_limit_pos(origin, p_handle_id)
	var delta : float
	if p_handle_id < 2:
		delta = rad_to_deg(old_local.signed_angle_to(local, Vector3.UP))
	else:
		delta = rad_to_deg(old_local.signed_angle_to(local, Vector3.LEFT))

	# Adjust the current limit
	var limit := _get_limit(origin, p_handle_id)
	limit = snappedf(limit + delta, 5)
	_set_limit(origin, p_handle_id, limit)


func _commit_handle(
	p_gizmo : EditorNode3DGizmo,
	p_handle_id : int,
	_secondary : bool,
	p_restore : Variant,
	p_cancel : bool) -> void:
	# Get the slider origin node
	var origin : XRToolsInteractableJoystickOrigin = p_gizmo.get_node_3d()

	# If canceling then restore limit
	if p_cancel:
		_set_limit(origin, p_handle_id, p_restore)
		return

	# Commit the handle change
	match p_handle_id:
		0:
			undo_redo.create_action("Set interactable joystick limit_x_minimum")
			undo_redo.add_do_method(origin, "set_limit_x_minimum", origin.limit_x_minimum)
			undo_redo.add_undo_method(origin, "set_limit_x_minimum", p_restore)
			undo_redo.commit_action()
		1:
			undo_redo.create_action("Set interactable joystick limit_x_maximum")
			undo_redo.add_do_method(origin, "set_limit_x_maximum", origin.limit_x_maximum)
			undo_redo.add_undo_method(origin, "set_limit_x_maximum", p_restore)
			undo_redo.commit_action()
		2:
			undo_redo.create_action("Set interactable joystick limit_y_minimum")
			undo_redo.add_do_method(origin, "set_limit_y_minimum", origin.limit_y_minimum)
			undo_redo.add_undo_method(origin, "set_limit_y_minimum", p_restore)
			undo_redo.commit_action()
		3:
			undo_redo.create_action("Set interactable joystick limit_y_maximum")
			undo_redo.add_do_method(origin, "set_limit_y_maximum", origin.limit_y_maximum)
			undo_redo.add_undo_method(origin, "set_limit_y_maximum", p_restore)
			undo_redo.commit_action()


func _has_gizmo(p_node : Node3D) -> bool:
	return p_node is XRToolsInteractableJoystickOrigin


func _redraw(p_gizmo : EditorNode3DGizmo) -> void:
	# Clear the current gizmo contents
	p_gizmo.clear()

	# Get the joystick origin and its extents
	var origin : XRToolsInteractableJoystickOrigin = p_gizmo.get_node_3d()
	var min_x_angle := deg_to_rad(origin.limit_x_minimum)
	var max_x_angle := deg_to_rad(origin.limit_x_maximum)
	var min_y_angle := deg_to_rad(origin.limit_y_minimum)
	var max_y_angle := deg_to_rad(origin.limit_y_maximum)

	# Construct an immediate mesh for the extent
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in 33:
		if i != 0:
			mesh.surface_add_vertex(Vector3.ZERO)
		var angle := lerpf(min_x_angle, max_x_angle, i / 32.0)
		mesh.surface_add_vertex(
			Vector3(sin(angle) * 0.2, 0, cos(angle) * 0.2))
	mesh.surface_end()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in 33:
		if i != 0:
			mesh.surface_add_vertex(Vector3.ZERO)
		var angle := lerpf(min_y_angle, max_y_angle, i / 32.0)
		mesh.surface_add_vertex(
			Vector3(0, sin(angle) * 0.2, cos(angle) * 0.2))
	mesh.surface_end()

	# Draw the extent mesh
	p_gizmo.add_mesh(mesh, get_material("extent", p_gizmo))

	# Add the handles
	var handles := PackedVector3Array()
	handles.push_back(_get_limit_pos(origin, 0))
	handles.push_back(_get_limit_pos(origin, 1))
	handles.push_back(_get_limit_pos(origin, 2))
	handles.push_back(_get_limit_pos(origin, 3))
	p_gizmo.add_handles(handles, get_material("handles", p_gizmo), [])


# Get the limit of a joystick by handle
func _get_limit(
	p_origin : XRToolsInteractableJoystickOrigin,
	p_handle_id : int) -> float:
	# Read the limit
	match p_handle_id:
		0:
			return p_origin.limit_x_minimum
		1:
			return p_origin.limit_x_maximum
		2:
			return p_origin.limit_y_minimum
		3:
			return p_origin.limit_y_maximum
		_:
			return 0.0


# Get the limit position of a slider by handle
func _get_limit_pos(
	p_origin : XRToolsInteractableJoystickOrigin,
	p_handle_id : int) -> Vector3:
	# Return the limit position
	var angle := deg_to_rad(_get_limit(p_origin, p_handle_id))
	match p_handle_id:
		0, 1:
			return Vector3(sin(angle) * 0.2, 0, cos(angle) * 0.2)
		2, 3:
			return Vector3(0, sin(angle) * 0.2, cos(angle) * 0.2)
		_:
			return Vector3.ZERO


# Set the limit of a joystick by handle
func _set_limit(
	p_origin : XRToolsInteractableJoystickOrigin,
	p_handle_id : int,
	p_limit : float) -> void:
	# Apply the limit
	match p_handle_id:
		0:
			p_origin.limit_x_minimum = p_limit
		1:
			p_origin.limit_x_maximum = p_limit
		2:
			p_origin.limit_y_minimum = p_limit
		3:
			p_origin.limit_y_maximum = p_limit
