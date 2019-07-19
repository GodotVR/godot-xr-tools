extends Node

# We don't know the name of the camera node... 
export (NodePath) var camera = null

# size of our player
export var player_radius = 0.4 setget set_player_radius, get_player_radius

# to combat motion sickness we'll 'step' our left/right turning
export var turn_delay = 0.2
export var turn_angle = 20.0
export var max_speed = 5.0
export var drag_factor = 0.1

var turn_step = 0.0
var origin_node = null
var camera_node = null
var velocity = Vector3(0.0, 0.0, 0.0)
var gravity = -30.0
onready var collision_shape = get_node("KinematicBody/CollisionShape")
onready var tail = get_node("KinematicBody/Tail")

func get_player_radius():
	return player_radius

func set_player_radius(p_radius):
	player_radius = p_radius

func _ready():
	# origin node should always be the parent of our parent
	origin_node = get_node("../..")
	
	if camera:
		camera_node = get_node(camera)
	else:
		# see if we can find our default
		camera_node = origin_node.get_node('ARVRCamera')
	
	set_player_radius(player_radius)

func _physics_process(delta):
	if !origin_node:
		return
	
	if !camera_node:
		return
	
	# Adjust the height of our player according to our camera position
	var camera_height = camera_node.transform.origin.y
	if camera_height < player_radius:
		# not smaller than this
		camera_height = player_radius
	
	collision_shape.shape.radius = player_radius
	collision_shape.shape.height = camera_height - player_radius
	collision_shape.transform.origin.y = (camera_height / 2.0) + player_radius
	
	# We should be the child or the controller on which the teleport is implemented
	var controller = get_parent()
	if controller.get_is_active():
		var left_right = controller.get_joystick_axis(0)
		var forwards_backwards = controller.get_joystick_axis(1)
		
		################################################################
		# first process turning, no problems there :)
		if (abs(left_right) > 0.1):
			if left_right > 0.0:
				if turn_step < 0.0:
					# reset step
					turn_step = 0
			
				turn_step += left_right * delta
			else:
				if turn_step > 0.0:
					# reset step
					turn_step = 0
			
				turn_step += left_right * delta
		
			if abs(turn_step) > turn_delay:
				# we rotate around our Camera, but we adjust our origin, so we need a little bit of trickery
				var t1 = Transform()
				var t2 = Transform()
				var rot = Transform()
			
				t1.origin = -camera_node.transform.origin
				t2.origin = camera_node.transform.origin
			
				# Rotating
				while abs(turn_step) > turn_delay:
					if (turn_step > 0.0):
						rot = rot.rotated(Vector3(0.0,-1.0,0.0),turn_angle * PI / 180.0)
						turn_step -= turn_delay
					else:
						rot = rot.rotated(Vector3(0.0,1.0,0.0),turn_angle * PI / 180.0)
						turn_step += turn_delay
			
				origin_node.transform *= t2 * rot * t1
		else:
			turn_step = 0.0
		
		################################################################
		# now we do our movement
		# We start with placing our KinematicBody in the right place
		# by centering it on the camera but placing it on the ground
		var curr_transform = $KinematicBody.global_transform
		var camera_transform = camera_node.global_transform
		curr_transform.origin = camera_transform.origin
		curr_transform.origin.y = origin_node.global_transform.origin.y
		$KinematicBody.global_transform = curr_transform
		
		# we'll handle gravity separately
		var gravity_velocity = Vector3(0.0, velocity.y, 0.0)
		velocity.y = 0.0
		
		# Apply our drag
		velocity *= (1.0 - drag_factor)
		
		if (abs(forwards_backwards) > 0.1 and tail.is_colliding()):
			var dir = camera_transform.basis.z
			dir.y = 0.0
			
			velocity = dir.normalized() * -forwards_backwards * delta * max_speed * ARVRServer.world_scale
#			velocity = velocity.linear_interpolate(dir, delta * 100.0)
		
		# apply move and slide to our kinematic body
		velocity = $KinematicBody.move_and_slide(velocity, Vector3(0.0, 1.0, 0.0))
		
		# apply our gravity
		gravity_velocity.y += gravity * delta
		gravity_velocity = $KinematicBody.move_and_slide(gravity_velocity, Vector3(0.0, 1.0, 0.0))
		velocity.y = gravity_velocity.y
		
		# now use our new position to move our origin point
		var movement = ($KinematicBody.global_transform.origin - curr_transform.origin)
		origin_node.global_transform.origin += movement
		
		# Return this back to where it was so we can use its collision shape for other things too
		# $KinematicBody.global_transform.origin = curr_transform.origin

