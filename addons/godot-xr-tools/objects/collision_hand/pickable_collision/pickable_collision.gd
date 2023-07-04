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

# parent
@onready var _parent : XRToolsPickable = get_parent()
# collision
var c
# correction
var _c
#translate
var _tl
# transform
var _tf

# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPickableCollision"


func get_collider_dict():
	c = _parent.get_node("CollisionShape3D")
	_c = _parent.get_active_grab_point().transform.origin
	_tl = _parent.get_active_grab_point().transform * c.transform.origin - _c * 2
	_tf = Transform3D(_parent.get_active_grab_point().transform.basis, _tl)
	return {c : _tf}
