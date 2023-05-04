extends StaticBody3D


var XROrigin :XROrigin3D
var PlayerBody : CharacterBody3D
var Exit_Node : Node3D
func _ready() -> void:
	XROrigin = get_node("%XROrigin3D")
	PlayerBody = XROrigin.get_node("PlayerBody")
	if has_node("Exit"):
		Exit_Node = get_node("Exit")

var last_pos := Vector3.ZERO
var last_rot := Vector3.ZERO

var is_sitting := false
@export var seating_rot_correction := Vector3.ZERO
func seat():
	if !is_sitting:
		is_sitting=true
		last_pos=XROrigin.global_transform.origin
		last_rot=XROrigin.global_rotation
		
		PlayerBody.set_enabled(false)
		
		XROrigin.global_transform.origin=self.global_transform.origin
		XROrigin.global_rotation=self.global_rotation+seating_rot_correction
		

@export_range(-1,100) var max_last_pos_exit := 6
func unseat():
	if is_sitting:
		is_sitting=false
		if is_instance_valid(Exit_Node) and Exit_Node!=null and global_transform.origin.distance_to(last_pos)>max_last_pos_exit:
			XROrigin.global_transform.origin=Exit_Node.global_transform.origin
			XROrigin.global_rotation=Exit_Node.global_rotation
		else:
			XROrigin.global_transform.origin=last_pos
			XROrigin.global_rotation=last_rot
		PlayerBody.set_enabled(true)
