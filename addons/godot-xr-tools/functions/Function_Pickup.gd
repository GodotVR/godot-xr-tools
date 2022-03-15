class_name Function_Pickup
extends Area3D

signal has_picked_up(what)
signal has_dropped

@export var pickup_range = 0.5:
	set(new_value):
		pickup_range = new_value
		if $CollisionShape3D:
			_update_pickup_range()

func _update_pickup_range():
	$CollisionShape3D.shape.radius = pickup_range

@export var impulse_factor = 1.0
@export var pickup_button_action = "grip_click"
@export var action_button_action = "trigger_click"
@export var max_samples = 5

var object_in_area = Array()
var closest_object = null
var picked_up_object: Node = null

var _velocity_averager = VelocityAverager.new(max_samples)

func _on_Function_Pickup_entered(object):
	# add our object to our array if required
	if object.has_method('pick_up') and object_in_area.find(object) == -1:
		object_in_area.push_back(object)
		_update_closest_object()

func _on_Function_Pickup_exited(object):
	# remove our object from our array
	if object_in_area.find(object) != -1:
		object_in_area.erase(object)
		_update_closest_object()

func _update_closest_object():
	var new_closest_obj = null
	if !picked_up_object:
		var new_closest_distance = 1000
		for o in object_in_area:
			# only check objects that aren't already picked up
			if o.is_picked_up() == false:
				var distance_squared = global_transform.origin.distance_squared_to(o.global_transform.origin)
				if distance_squared < new_closest_distance:
					new_closest_obj = o

					new_closest_distance = distance_squared
	if closest_object != new_closest_obj:
		# remove highlight on old object
		if closest_object:
			closest_object.decrease_is_closest()

		# add highlight to new object
		closest_object = new_closest_obj
		if closest_object:
			closest_object.increase_is_closest()

func drop_object():
	if is_instance_valid(picked_up_object):
		# let go of this object
		picked_up_object.let_go(
			_velocity_averager.linear_velocity() * impulse_factor,
			_velocity_averager.angular_velocity())
		picked_up_object = null
		_velocity_averager.clear()
		emit_signal("has_dropped")

func _pick_up_object(p_object):
	# already holding this object, nothing to do
	if is_instance_valid(picked_up_object) && picked_up_object == p_object:
		return

	# holding something else? drop it
	if is_instance_valid(picked_up_object):
		drop_object()

	# and pick up our new object
	if p_object:
		picked_up_object = p_object
		picked_up_object.pick_up(self, get_parent())
		emit_signal("has_picked_up", picked_up_object)

func _on_button_pressed(p_button):
	if p_button == pickup_button_action:
		if is_instance_valid(picked_up_object) and !picked_up_object.press_to_hold:
			drop_object()
		elif is_instance_valid(closest_object):
			_pick_up_object(closest_object)
	elif p_button == action_button_action:
		if is_instance_valid(picked_up_object) and picked_up_object.has_method("action"):
			picked_up_object.action()

func _on_button_released(p_button):
	if p_button == pickup_button_action:
		if is_instance_valid(picked_up_object) and picked_up_object.press_to_hold:
			drop_object()

func _ready():
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		return

	get_parent().connect("button_pressed", _on_button_pressed)
	get_parent().connect("button_released", _on_button_released)

	_update_pickup_range()

func _process(delta):
	# Do not run physics if in the editor
	if Engine.is_editor_hint():
		return

	# Calculate velocity averaging on any picked up object
	if picked_up_object:
		_velocity_averager.add_transform(delta, picked_up_object.global_transform)

	_update_closest_object()
