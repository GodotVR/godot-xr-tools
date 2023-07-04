@tool
## adds collision to the pickable parent object
## ________________________________________________________
## Instructions:
## ________________________________________________________
## instantiate as child of a pickable
## ________________________________________________________
## Requirements:
## ________________________________________________________
## requires the use of the CollisionHand
class_name XRToolsPickableCollision
extends Node


@onready var _parent : XRToolsPickable = get_parent()
var collision


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickableCollision"


func get_collider_dict():
	collision = _parent.get_node("CollisionShape3D")
	var _correction = _parent.get_active_grab_point().transform.origin
	var shape_translate = _parent.get_active_grab_point().transform * collision.transform.origin - _correction * 2
	var shape_transform = Transform3D(_parent.get_active_grab_point().transform.basis, shape_translate)
	return {collision : shape_transform}
