@tool
class_name XRToolsFunctionPointer
extends Node3D
@icon("res://addons/godot-xr-tools/editor/icons/function.svg")

@export var enabled = true:
	set(new_value):
		enabled = new_value
		
		# this gets called before our scene is ready, we'll call this again in _ready to enable this
		if is_inside_tree():
			_update_set_enabled()

func _update_set_enabled():
	$Laser.visible = enabled and show_laser
	$RayCast.enabled = enabled

@export var show_laser = true:
	set(new_value):
		show_laser = new_value
		if is_inside_tree():
			_update_show_laser();

func _update_show_laser():
	$Laser.visible = enabled and show_laser

@export var show_target = false
@export var active_button_action = "trigger_click"
@export var y_offset = -0.05:
	set(new_value):
		y_offset = new_value
		if is_inside_tree():
			_update_y_offset()

func _update_y_offset():
	$Laser.position.y = y_offset * ws
	$RayCast.position.y = y_offset * ws

@export var distance = 10:
	set(new_value):
		distance = new_value
		if is_inside_tree():
			_update_distance();

func _update_distance():
	$Laser.mesh.size.z = distance
	$Laser.position.z = distance * -0.5
	$RayCast.target_position.z = -distance

@export_flags_3d_physics  var collision_mask = 15:
	set(new_value):
		collision_mask = new_value
		if is_inside_tree():
			_update_collision_mask()

func _update_collision_mask():
	$RayCast.collision_mask = collision_mask

@export var collide_with_bodies = true:
	set(new_value):
		collide_with_bodies = new_value
		if is_inside_tree():
			_update_collide_with_bodies()

func _update_collide_with_bodies():
	$RayCast.collide_with_bodies = collide_with_bodies


@export var collide_with_areas = false:
	set(new_value):
		collide_with_areas = new_value
		if is_inside_tree():
			_update_collide_with_areas()

func _update_collide_with_areas():
	$RayCast.collide_with_areas = collide_with_areas

var target = null
var last_target = null
var last_collided_at = Vector3(0, 0, 0)

var ws = 1.0

func _button_pressed():
	if $RayCast.is_colliding():
		target = $RayCast.get_collider()
		last_collided_at = $RayCast.get_collision_point()
		
		if target.has_signal("pointer_pressed"):
			target.emit_signal("pointer_pressed", last_collided_at)
		elif target.has_method("pointer_pressed"):
			target.pointer_pressed(last_collided_at)

func _button_released():
	if target:
		if target.has_signal("pointer_released"):
			target.emit_signal("pointer_released", last_collided_at)
		elif target.has_method("pointer_released"):
			target.pointer_released(last_collided_at)
		
		# unset target
		target = null
		last_collided_at = Vector3(0, 0, 0)

func _on_button_pressed(p_button):
	if p_button == active_button_action and enabled:
		_button_pressed()

func _on_button_released(p_button):
	if p_button == active_button_action and target:
		_button_released()

func _ready():
	ws = XRServer.world_scale

	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	# Get button press feedback from our parent (should be an XRController3D)
	get_parent().connect("button_pressed", _on_button_pressed)
	get_parent().connect("button_released", _on_button_released)
	
	# init our state
	_update_y_offset()
	_update_distance()
	_update_collision_mask()
	_update_show_laser()
	_update_collide_with_bodies()
	_update_collide_with_areas()
	_update_set_enabled()

func _process(delta):
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	if !is_inside_tree():
		return
	
	var new_ws = XRServer.world_scale
	if (ws != new_ws):
		ws = new_ws
		_update_y_offset()
	
	if enabled and $RayCast.is_colliding():
		var new_at = $RayCast.get_collision_point()
		
		if is_instance_valid(target):
			# if target is set our mouse must be down, we keep "focus" on our target
			if new_at != last_collided_at:
				if target.has_signal("pointer_moved"):
					target.emit_signal("pointer_moved", last_collided_at, new_at)
				elif target.has_method("pointer_moved"):
					target.pointer_moved(last_collided_at, new_at)
		else:
			var new_target = $RayCast.get_collider()

			# are we pointing to a new target?
			if new_target != last_target:
				# exit the old
				if is_instance_valid(last_target):
					if last_target.has_signal("pointer_exited"):
						last_target.emit_signal("pointer_exited")
					elif last_target.has_method("pointer_exited"):
						last_target.pointer_exited()

				# enter the new
				if is_instance_valid(new_target):
					if new_target.has_signal("pointer_entered"):
						new_target.emit_signal("pointer_entered")
					elif new_target.has_method("pointer_entered"):
						new_target.pointer_entered()

				last_target = new_target

			if new_at != last_collided_at:
				if new_target.has_signal("pointer_moved"):
					new_target.emit_signal("pointer_moved", last_collided_at, new_at)
				elif new_target.has_method("pointer_moved"):
					new_target.pointer_moved(last_collided_at, new_at)

		if last_target and show_target:
			$Target.global_transform.origin = last_collided_at
			$Target.visible = true

		# remember our new position
		last_collided_at = new_at
	else:
		if is_instance_valid(last_target):
			if last_target.has_signal("pointer_exited"):
				last_target.emit_signal("pointer_exited")
			elif last_target.has_method("pointer_exited"):
				last_target.pointer_exited()
		
		last_target = null
		$Target.visible = false
