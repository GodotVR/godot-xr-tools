@tool
class_name XRToolsMovementGravityZones
extends XRToolsMovementProvider


# Default wall-walk mask of 4:wall-walk
const DEFAULT_MASK := 0b0000_0000_0000_0000_0000_0000_0000_1000


## Wall walking provider order
@export var order : int = 26

## Set our follow layer mask
@export_flags_3d_physics var follow_mask : int = DEFAULT_MASK

@onready var Fly_Desktop : XRToolsDesktopMovementFlight = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,"*","XROrigin3D"),
	"*",
	"XRToolsDesktopMovementFlight")

@onready var Fly_XR : XRToolsMovementFlight = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,"*","XROrigin3D"),
	"*",
	"XRToolsMovementFlight")


var gravity_dir := Vector3(0,-9.8,0)
func physics_pre_movement(_delta: float, player_body: XRToolsPlayerBody):
	# Test for collision with wall under feet
	var gravity_zones1 = get_tree().get_nodes_in_group("gravity_zone1")
	var gravity_zones2 = get_tree().get_nodes_in_group("gravity_zone2")
	var gravity_zones3 = get_tree().get_nodes_in_group("gravity_zone3")
	
	#gravity_dir = Vector3(0,-9.8,0)
	var grav_z := 0
	for zone in gravity_zones3:
		if zone.overlaps_body(player_body) and zone is Area3D:
			grav_z=3
			gravity_dir=zone.global_transform.basis.y*zone.gravity*-1
	
	if grav_z==0:
		for zone in gravity_zones2:
			if zone.overlaps_body(player_body) and zone is Area3D:
				grav_z=2
				gravity_dir=zone.global_transform.basis.y*zone.gravity*-1
	
	if grav_z==0:
		for zone in gravity_zones1:
			if zone.overlaps_body(player_body) and zone is Area3D:
				grav_z=1
				gravity_dir=zone.global_transform.basis.y*zone.gravity*-1
	
	if grav_z==0:
		Fly_Desktop.set_flying(true)
		Fly_XR.set_flying(true)
	else:
		Fly_Desktop.set_flying(false)
		Fly_XR.set_flying(false)
	
	# Modify the player gravity
	player_body.gravity = gravity_dir
