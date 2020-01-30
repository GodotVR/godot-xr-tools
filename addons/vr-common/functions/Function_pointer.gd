extends Spatial

signal pointer_pressed(on, at)
signal pointer_released(on, at)
signal pointer_moved(on, from, to)

signal pointer_entered(body)
signal pointer_exited(body)

export var enabled = true setget set_enabled, get_enabled
export var ducktyped_body = true
export var active_button = 15
export var distance = 10 setget set_distance, get_distance

# Need to replace this with proper solution once support for layer selection has been added 
export (int, FLAGS, "Layer 1", "Layer 2", "Layer 3", "Layer 4", "Layer 5", "Layer 6", "Layer 7", "Layer 8", "Layer 9", "Layer 10", "Layer 11", "Layer 12", "Layer 13", "Layer 14", "Layer 15", "Layer 16", "Layer 17", "Layer 18", "Layer 19", "Layer 20") var collision_mask = 15 setget set_collision_mask, get_collision_mask

var target = null
var last_target = null
var last_collided_at = Vector3(0, 0, 0)
var laser_y = -0.05

onready var ws = ARVRServer.world_scale

func set_enabled(p_enabled):
	enabled = p_enabled
	
	# this gets called before our scene is ready, we'll call this again in _ready to enable this
	if $Laser:
		$Laser.visible = p_enabled
		
		$Laser/RayCast.enabled = p_enabled

func get_enabled():
	return enabled

func set_collision_mask(p_new_mask):
	collision_mask = p_new_mask
	
	if $Laser:
		$Laser/RayCast.collision_mask = collision_mask

func get_collision_mask():
	return collision_mask

func set_distance(p_new_value):
	distance = p_new_value
	if $Laser:
		$Laser.mesh.size.z = distance
		$Laser.translation.z = distance * -0.5
		$Laser/RayCast.translation.z = distance * 0.5
		$Laser/RayCast.cast_to.z = -distance

func get_distance():
	return distance

func _on_button_pressed(p_button):
	if p_button == active_button and enabled:
		if $Laser/RayCast.is_colliding():
			target = $Laser/RayCast.get_collider()
			last_collided_at = $Laser/RayCast.get_collision_point()
			
			emit_signal("pointer_pressed", target, last_collided_at)
			
			if ducktyped_body and target.has_method("pointer_pressed"):
				target.pointer_pressed(last_collided_at)

func _on_button_release(p_button):
	if p_button == active_button and target:
		emit_signal("pointer_released", target, last_collided_at)
		
		if ducktyped_body and target.has_method("pointer_released"):
			target.pointer_released(last_collided_at)
		
		# unset target
		target = null
		last_collided_at = Vector3(0, 0, 0)

func _ready():
	# Get button press feedback from our parent (should be an ARVRController)
	get_parent().connect("button_pressed", self, "_on_button_pressed")
	get_parent().connect("button_release", self, "_on_button_release")
	
	# apply our world scale to our laser position
	$Laser.translation.y = laser_y * ws
	
	# init our state
	set_distance(distance)
	set_collision_mask(collision_mask)
	set_enabled(enabled)

func _process(delta):
	if !is_inside_tree():
		return
	
	var new_ws = ARVRServer.world_scale
	if (ws != new_ws):
		ws = new_ws
	$Laser.translation.y = laser_y * ws
	
	if enabled and $Laser/RayCast.is_colliding():
		var new_at = $Laser/RayCast.get_collision_point()
		
		if target:
			# if target is set our mouse must be down, we keep "focus" on our target
			if new_at != last_collided_at:
				emit_signal("pointer_moved", target, last_collided_at, new_at)
				
				if ducktyped_body and target.has_method("pointer_moved"):
					target.pointer_moved(last_collided_at, new_at)
		else:
			var new_target = $Laser/RayCast.get_collider()
			
			# are we pointing to a new target?
			if new_target != last_target:
				# exit the old
				if last_target:
					emit_signal("pointer_exited", last_target)
					
					if ducktyped_body and last_target.has_method("pointer_exited"):
						last_target.pointer_exited()
				
				# enter the new
				if new_target:
					emit_signal("pointer_entered", new_target)
					
					if ducktyped_body and new_target.has_method("pointer_entered"):
						new_target.pointer_entered()
				
				last_target = new_target
			
			if new_at != last_collided_at:
				emit_signal("pointer_moved", new_target, last_collided_at, new_at)
				
				if ducktyped_body and new_target.has_method("pointer_moved"):
					new_target.pointer_moved(last_collided_at, new_at)
		
		# remember our new position
		last_collided_at = new_at
	elif last_target:
		emit_signal("pointer_exited", last_target)
		
		if ducktyped_body and last_target.has_method("pointer_exited"):
			last_target.pointer_exited()
		
		last_target = null

