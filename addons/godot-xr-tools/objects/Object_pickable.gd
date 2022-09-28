@tool
extends RigidBody3D
class_name XRToolsPickable

# Set hold mode
@export var press_to_hold : bool = true
@export var reset_transform_on_pickup : bool = true
@export_node_path(MeshInstance3D) var highlight_mesh_instance
@export_flags_3d_physics var picked_up_layer = 0

# Remember some state so we can return to it when the user drops the object
@onready var original_parent = get_parent()
@onready var original_collision_mask = collision_mask
@onready var original_collision_layer = collision_layer
var was_frozen : bool = false

@onready var highlight_material = preload("res://addons/godot-xr-tools/materials/highlight.tres")
var original_materials = Array()
var highlight_mesh_instance_node : MeshInstance3D = null

# Who picked us up?
var picked_up_by = null
var center_pickup_on_node = null
var by_controller : XRController3D = null
var closest_count = 0

# Signal emitted when the user picks up this object
signal picked_up(pickable)

# Signal emitted when the user drops this object 
signal dropped(pickable)

# Signal emitted when the user presses the action button while holding this object
signal action_pressed(pickable)

# have we been picked up?
func is_picked_up():
	if picked_up_by:
		return true

	return false

# action is called when user presses the action button while holding this object
func action():
	# let interested parties know
	emit_signal("action_pressed", self)

func _update_highlight():
	if highlight_mesh_instance_node:
		# if we can find a node remember which materials are currently set on each surface
		for i in range(0, highlight_mesh_instance_node.get_surface_override_material_count()):
			if closest_count > 0:
				highlight_mesh_instance_node.set_surface_override_material(i, highlight_material)
			else:
				highlight_mesh_instance_node.set_surface_override_material(i, original_materials[i])
	else:
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

	# Remember if our object was already frozen
	was_frozen = freeze

	# turn off physics on our pickable object and freeze it, we need to look into the freeze modes
	freeze = true
	collision_layer = picked_up_layer
	collision_mask = 0

	# now reparent it
	var original_transform = global_transform
	original_parent.remove_child(self)
	picked_up_by.add_child(self)

	if reset_transform_on_pickup:
		if center_pickup_on_node:
			transform = center_pickup_on_node.global_transform.inverse() * global_transform
		else:
			# reset our transform
			transform = Transform3D()
	else:
		# make sure we keep its original position
		global_transform = original_transform

	# let interested parties know
	emit_signal("picked_up", self)

# we are being let go
func let_go(p_linear_velocity = Vector3(), p_angular_velocity = Vector3()):
	if picked_up_by:
		# get our current global transform
		var t = global_transform

		# reparent it
		picked_up_by.remove_child(self)
		original_parent.add_child(self)

		# reposition it and apply impulse
		global_transform = t
		freeze = was_frozen
		collision_mask = original_collision_mask
		collision_layer = original_collision_layer

		# set our starting velocity
		linear_velocity = p_linear_velocity
		angular_velocity = p_angular_velocity

		# we are no longer picked up
		picked_up_by = null
		by_controller = null
		
		# let interested parties know
		emit_signal("dropped", self)

func _ready():
	if highlight_mesh_instance:
		# if we have a highlight mesh instance selected obtain our node
		highlight_mesh_instance_node = get_node(highlight_mesh_instance)
		if highlight_mesh_instance_node:
			# if we can find a node remember which materials are currently set on each surface
			for i in range(0, highlight_mesh_instance_node.get_surface_override_material_count()):
				original_materials.push_back(highlight_mesh_instance_node.get_surface_override_material(i))

	# if we have center pickup on set obtain our node
	if reset_transform_on_pickup:
		center_pickup_on_node = get_node("PickupCenter")

func _get_configuration_warning():
	if reset_transform_on_pickup and !get_node_or_null("PickupCenter"):
		return "Missing PickupCenter child node for 'reset transform on pickup'"
	return ""
