extends StaticBody3D


var XROrigin :XROrigin3D
var PlayerBody : CharacterBody3D
var Exit_Node : Node3D
func _ready() -> void:
	#Store current chair possition
	last_chair_pos=XROrigin.global_transform.origin
	last_chair_rot=XROrigin.global_rotation
	
	#Assume XROrigin is named XROrigin3D and is accessible via unical name
	XROrigin = get_node("%XROrigin3D")
	#Get Playerbody
	PlayerBody = XROrigin.get_node("PlayerBody")
	
	#Check and Retrive exit node if it exists
	if has_node("Exit"):
		Exit_Node = get_node("Exit")

#Storage for player enter position
var last_plr_pos := Vector3.ZERO
var last_plr_rot := Vector3.ZERO


var is_sitting := false

#For multiplayer to set should chair update local plr pos
var is_local := false

@export var seating_rot_correction := Vector3.ZERO

func seat(local:=true):
	if !is_sitting:
		is_sitting=true
		is_local=local
		if local:
			last_plr_pos=XROrigin.global_transform.origin
			last_plr_rot=XROrigin.global_rotation
			
			PlayerBody.set_enabled(false)
			
			XROrigin.global_transform.origin=self.global_transform.origin
			XROrigin.global_rotation=self.global_rotation+seating_rot_correction
		

@export_range(-1,100) var max_last_pos_exit := 6
func unseat():
	if is_sitting:
		is_sitting=false
		if is_local:
			if is_instance_valid(Exit_Node) and Exit_Node!=null and global_transform.origin.distance_to(last_plr_pos)>max_last_pos_exit:
				XROrigin.global_transform.origin=Exit_Node.global_transform.origin
				XROrigin.global_rotation=Exit_Node.global_rotation
			else:
				XROrigin.global_transform.origin=last_plr_pos
				XROrigin.global_rotation=last_plr_rot
			PlayerBody.set_enabled(true)


var last_chair_pos := Vector3.ZERO
var last_chair_rot := Vector3.ZERO
func _process(delta: float) -> void:
	if is_sitting and is_local:
		#calc seat pos change
		var mov :Vector3= self.global_transform.origin-last_chair_pos
		var rot :Vector3= self.global_rotation-last_chair_rot
		
		#Update player position if seat global position changed
		if !mov.is_equal_approx(Vector3.ZERO):
			XROrigin.global_transform.origin+=mov
		#Update player rotation if seat global rotation changed
		if !rot.is_equal_approx(Vector3.ZERO):
			XROrigin.global_rotation+=rot
		
		#Store current position
		last_chair_pos=self.global_transform.origin
		last_chair_rot=self.global_rotation
