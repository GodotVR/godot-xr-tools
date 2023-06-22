class_name XRToolsPickableCollision
extends Node


@onready var _parent : XRToolsPickable = get_parent()
@export var collision_offset_left : Vector3 = Vector3(-0.029,-0.051,0.129)
@export var collision_offset_right : Vector3 = Vector3(0.029,-0.051,0.129)
var collision


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickableCollision"


func get_collider_dict():
	collision = _parent.get_node("CollisionShape3D")
	var _correction = _parent.get_active_grab_point().transform.origin
	var shape_translate = _parent.get_active_grab_point().transform * collision_offset_right - collision.transform.origin * 2
	var shape_transform = Transform3D(_parent.get_active_grab_point().transform.basis, shape_translate)
	return {collision : shape_transform}
