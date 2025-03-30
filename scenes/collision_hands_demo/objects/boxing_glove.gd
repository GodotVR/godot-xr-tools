extends Node

@export var left_glove : Node3D
@export var right_glove : Node3D
@export var c : CollisionShape3D

@onready var _parent : XRToolsPickable = get_parent()

func _ready():
	_parent.picked_up.connect(_on_picked_up)
	if left_glove.visible:
		c.position = Vector3(0.045, 0, -0.092)
		c.rotation_degrees = Vector3(90,0,0)
	else:
		c.position = Vector3(-0.045, 0, -0.092)
		c.rotation_degrees = Vector3(-90,0,0)
	
# Called when this object is picked up
func _on_picked_up(_pickable) -> void:
	_parent.by_controller = _parent.get_picked_up_by_controller()
	if _parent.by_controller.name.matchn("*left*"):
		if left_glove.visible:
			return
			
		if !left_glove.visible:
			c.position = Vector3(0.045, 0, -0.092)
			c.rotation_degrees = Vector3(90,0,0)
			right_glove.visible = false
			left_glove.visible = true
	else:
		if right_glove.visible:
			return
			
		if !right_glove.visible:
			c.position = Vector3(-0.045, 0, -0.092)
			c.rotation_degrees = Vector3(-90,0,0)
			right_glove.visible = true
			left_glove.visible = false
