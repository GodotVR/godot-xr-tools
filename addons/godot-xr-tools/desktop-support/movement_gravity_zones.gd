@tool
class_name XRToolsMovementGravityZones
extends XRToolsMovementProvider


# Default wall-walk mask of 4:wall-walk
const DEFAULT_MASK := 0b0000_0000_0000_0000_0000_0000_0000_1000


## Wall walking provider order
@export var order : int = 26

## Set our follow layer mask
@export_flags_3d_physics var follow_mask : int = DEFAULT_MASK

var _gravity_dir := Vector3(0,-9.8,0)

@onready var fly_desktop : XRToolsDesktopMovementFlight = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,"*","XROrigin3D"),
	"*",
	"XRToolsDesktopMovementFlight")

@onready var fly_xr : XRToolsMovementFlight = XRTools.find_xr_child(
	XRTools.find_xr_ancestor(self,"*","XROrigin3D"),
	"*",
	"XRToolsMovementFlight")


func physics_pre_movement(_delta: float, player_body: XRToolsPlayerBody):
	# Test for collision with wall under feet
	var gravity_zones1 = get_tree().get_nodes_in_group("gravity_zone1")
	var gravity_zones2 = get_tree().get_nodes_in_group("gravity_zone2")
	var gravity_zones3 = get_tree().get_nodes_in_group("gravity_zone3")

	#_gravity_dir = Vector3(0,-9.8,0)
	var grav_z := 0
	for zone in gravity_zones3:
		if zone.overlaps_body(player_body) and zone is Area3D:
			grav_z=3
			_gravity_dir=zone.global_transform.basis.y*zone.gravity*-1

	if grav_z==0:
		for zone in gravity_zones2:
			if zone.overlaps_body(player_body) and zone is Area3D:
				grav_z=2
				_gravity_dir=zone.global_transform.basis.y*zone.gravity*-1

	if grav_z==0:
		for zone in gravity_zones1:
			if zone.overlaps_body(player_body) and zone is Area3D:
				grav_z=1
				_gravity_dir=zone.global_transform.basis.y*zone.gravity*-1

	if grav_z==0:
		fly_desktop.set_flying(true)
		fly_xr.set_flying(true)
	else:
		fly_desktop.set_flying(false)
		fly_xr.set_flying(false)

	# Modify the player gravity
	player_body.gravity = _gravity_dir
