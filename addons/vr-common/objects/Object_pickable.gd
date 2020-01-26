extends RigidBody

# Set hold mode
export (bool) var press_to_hold = true
export (int, FLAGS, "layer_1", "layer_2", "layer_3", "layer_4", "layer_5") var picked_up_layer = 0

# Remember some state so we can return to it when the user drops the object
onready var original_parent = get_parent()
onready var original_collision_mask = collision_mask
onready var original_collision_layer = collision_layer

# Who picked us up?
var picked_up_by = null
var by_controller : ARVRController = null
var closest_count = 0

# have we been picked up?
func is_picked_up():
	if picked_up_by:
		return true
	
	return false

func _update_highlight():
	# should probably implement this in our subclass
	pass

func increase_is_closest():
	closest_count += 1
	_update_highlight()

func decrease_is_closest():
	closest_count -= 1
	_update_highlight()

func drop_and_free():
	if picked_up_by:
		picked_up_by.drop_object()
	
	queue_free()

# we are being picked up by...
func pick_up(by, with_controller):
	if picked_up_by == by:
		return
	
	if picked_up_by:
		let_go()
	
	# remember who picked us up
	picked_up_by = by
	by_controller = with_controller
	
	# turn off physics on our pickable object
	mode = RigidBody.MODE_STATIC
	collision_layer = picked_up_layer
	collision_mask = 0
	
	# now reparent it
	original_parent.remove_child(self)
	picked_up_by.add_child(self)
	
	# reset our transform
	transform = Transform()

# we are being let go
func let_go(starting_linear_velocity = Vector3(0.0, 0.0, 0.0)):
	if picked_up_by:
		# get our current global transform
		var t = global_transform
		
		# reparent it
		picked_up_by.remove_child(self)
		original_parent.add_child(self)
		
		# reposition it and apply impulse
		global_transform = t
		mode = RigidBody.MODE_RIGID
		collision_mask = original_collision_mask
		collision_layer = original_collision_layer
		
		# set our starting velocity
		linear_velocity = starting_linear_velocity
		
#		apply_impulse(Vector3(0.0, 0.0, 0.0), impulse)
		
		# we are no longer picked up
		picked_up_by = null
		by_controller = null
