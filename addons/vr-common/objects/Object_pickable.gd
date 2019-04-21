extends RigidBody

# Remember some state so we can return to it when the user drops the object
onready var original_parent = get_parent()
onready var original_collision_mask = collision_mask
onready var original_collision_layer = collision_layer

# Who picked us up?
var picked_up_by = null

# we are being picked up by...
func pick_up(by):
	if picked_up_by == by:
		return
	
	if picked_up_by:
		let_go()
	
	# remember who picked us up
	picked_up_by = by
	
	# turn off physics on our pickable object
	mode = RigidBody.MODE_STATIC
	collision_layer = 0
	collision_mask = 0
	
	# now reparent it
	original_parent.remove_child(self)
	picked_up_by.add_child(self)
	
	# reset our transform
	transform = Transform()

# we are being let go
func let_go(impulse = Vector3(0.0, 0.0, 0.0)):
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
		apply_impulse(Vector3(0.0, 0.0, 0.0), impulse)
		
		# we are no longer picked up
		picked_up_by = null
