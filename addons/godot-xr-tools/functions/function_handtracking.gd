extends Spatial
class_name XRToolsFunctionHandtracking, "res://addons/godot-xr-tools/editor/icons/hand.svg"

var specialist_openxr_gdns_script_loaded = false

var palm_joint_confidence_L = TRACKING_CONFIDENCE_NOT_APPLICABLE
var palm_joint_confidence_R = TRACKING_CONFIDENCE_NOT_APPLICABLE
var joint_transforms_L = [ ]
var joint_transforms_R = [ ]

var LeftHand : XRToolsHand
var RightHand : XRToolsHand

var gxtlefthandrestdata = null
var gxtrighthandrestdata = null

onready var _controller_left_node := ARVRHelpers.get_left_controller(self)
onready var _controller_right_node := ARVRHelpers.get_right_controller(self)

# controls used to implement crude MovementDirect in hand-tracking mode
onready var _handpointer_left_node := ARVRHelpers._get_controller(self, 
					"ARVRController3", 3, NodePath(""))
onready var _handpointer_right_node := ARVRHelpers._get_controller(self, 
					"ARVRController4", 4, NodePath(""))
onready var player_body = XRToolsPlayerBody.find_instance(self)
const AXIS_HT_THUMB_INDEX_PINCH = 7

const XR_HAND_JOINT_COUNT_EXT = 26
const XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT = 0

enum {
	TRACKING_CONFIDENCE_NOT_APPLICABLE = -1,
	TRACKING_CONFIDENCE_NONE = 0,
	TRACKING_CONFIDENCE_LOW = 1,
	TRACKING_CONFIDENCE_HIGH = 2
}

# names from https://registry.khronos.org/OpenXR/specs/1.0/html/xrspec.html#_conventions_of_hand_joints
const XRbone_names = [ "Palm", "Wrist",
	"Thumb_Metacarpal", "Thumb_Proximal", "Thumb_Distal", "Thumb_Tip",
	"Index_Metacarpal", "Index_Proximal", "Index_Intermediate", "Index_Distal", "Index_Tip",
	"Middle_Metacarpal", "Middle_Proximal", "Middle_Intermediate", "Middle_Distal", "Middle_Tip",
	"Ring_Metacarpal", "Ring_Proximal", "Ring_Intermediate", "Ring_Distal", "Ring_Tip",
	"Little_Metacarpal", "Little_Proximal", "Little_Intermediate", "Little_Distal", "Little_Tip" ]
const boneparentsToWrist = [-1, -1, 1, 2, 3, 4, 1, 6, 7, 8, 9, 1, 11, 12, 13, 14,
							1, 16, 17, 18, 19, 1, 21, 22, 23, 24]
enum {
	XR_HAND_JOINT_PALM_EXT = 0,
	XR_HAND_JOINT_WRIST_EXT = 1,
	XR_HAND_JOINT_THUMB_METACARPAL_EXT = 2,
	XR_HAND_JOINT_THUMB_PROXIMAL_EXT = 3,
	XR_HAND_JOINT_THUMB_DISTAL_EXT = 4,
	XR_HAND_JOINT_THUMB_TIP_EXT = 5,
	XR_HAND_JOINT_INDEX_METACARPAL_EXT = 6,
	XR_HAND_JOINT_INDEX_PROXIMAL_EXT = 7,
	XR_HAND_JOINT_INDEX_INTERMEDIATE_EXT = 8,
	XR_HAND_JOINT_INDEX_DISTAL_EXT = 9,
	XR_HAND_JOINT_INDEX_TIP_EXT = 10,
	XR_HAND_JOINT_MIDDLE_METACARPAL_EXT = 11,
	XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT = 12,
	XR_HAND_JOINT_MIDDLE_INTERMEDIATE_EXT = 13,
	XR_HAND_JOINT_MIDDLE_DISTAL_EXT = 14,
	XR_HAND_JOINT_MIDDLE_TIP_EXT = 15,
	XR_HAND_JOINT_RING_METACARPAL_EXT = 16,
	XR_HAND_JOINT_RING_PROXIMAL_EXT = 17,
	XR_HAND_JOINT_RING_INTERMEDIATE_EXT = 18,
	XR_HAND_JOINT_RING_DISTAL_EXT = 19,
	XR_HAND_JOINT_RING_TIP_EXT = 20,
	XR_HAND_JOINT_LITTLE_METACARPAL_EXT = 21,
	XR_HAND_JOINT_LITTLE_PROXIMAL_EXT = 22,
	XR_HAND_JOINT_LITTLE_INTERMEDIATE_EXT = 23,
	XR_HAND_JOINT_LITTLE_DISTAL_EXT = 24,
	XR_HAND_JOINT_LITTLE_TIP_EXT = 25
}

const xrfingers = [
	XR_HAND_JOINT_THUMB_PROXIMAL_EXT, XR_HAND_JOINT_THUMB_DISTAL_EXT, XR_HAND_JOINT_THUMB_TIP_EXT, 
	XR_HAND_JOINT_INDEX_PROXIMAL_EXT, XR_HAND_JOINT_INDEX_INTERMEDIATE_EXT, XR_HAND_JOINT_INDEX_DISTAL_EXT, XR_HAND_JOINT_INDEX_TIP_EXT, 
	XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT, XR_HAND_JOINT_MIDDLE_INTERMEDIATE_EXT, XR_HAND_JOINT_MIDDLE_DISTAL_EXT, XR_HAND_JOINT_MIDDLE_TIP_EXT, 
	XR_HAND_JOINT_RING_PROXIMAL_EXT, XR_HAND_JOINT_RING_INTERMEDIATE_EXT, XR_HAND_JOINT_RING_DISTAL_EXT, XR_HAND_JOINT_RING_TIP_EXT, 
	XR_HAND_JOINT_LITTLE_PROXIMAL_EXT, XR_HAND_JOINT_LITTLE_INTERMEDIATE_EXT, XR_HAND_JOINT_LITTLE_DISTAL_EXT, XR_HAND_JOINT_LITTLE_TIP_EXT 
]

func setupopenxrpluginhandskeleton(handskelpose, _LR):
	# see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRPose.cpp
	handskelpose.action = "SkeletonBase"
	handskelpose.path = "/user/hand/right" if _LR == "_R" else "/user/hand/left"

	# see https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRSkeleton.cpp
	assert (len(XRbone_names) == XR_HAND_JOINT_COUNT_EXT)
	assert (len(boneparentsToWrist) == XR_HAND_JOINT_COUNT_EXT)
	var handskel = handskelpose.get_child(0)
	handskel.hand = 1 if _LR == "_R" else 0
	handskel.motion_range = XR_HAND_JOINTS_MOTION_RANGE_UNOBSTRUCTED_EXT
	for i in range(len(XRbone_names)):
		handskel.add_bone(XRbone_names[i] + _LR)
		if i >= 2:
			handskel.set_bone_parent(i, boneparentsToWrist[i])

func _enter_tree():
	specialist_openxr_gdns_script_loaded = ("path" in $LeftHandSkelPose)
	print("Handtrack enabled ", specialist_openxr_gdns_script_loaded, " ", $LeftHandSkelPose.get_script())
	if specialist_openxr_gdns_script_loaded:
		setupopenxrpluginhandskeleton($LeftHandSkelPose, "_L")
		for i in range(XR_HAND_JOINT_COUNT_EXT):
			joint_transforms_L.push_back(Transform())
		setupopenxrpluginhandskeleton($RightHandSkelPose, "_R")
		for i in range(XR_HAND_JOINT_COUNT_EXT):
			joint_transforms_R.push_back(Transform())
	else:
		print("HAND TRACKING SYSTEM DISABLED")
	
func skel_backtoOXRjointtransforms(joint_transforms, skel):
	joint_transforms[0] = skel.get_parent().transform
	joint_transforms[1] = joint_transforms[0] * skel.get_bone_pose(1)
	for i in range(2, XR_HAND_JOINT_COUNT_EXT):
		var ip = boneparentsToWrist[i]
		joint_transforms[i] = joint_transforms[ip] * skel.get_bone_pose(i)
	if joint_transforms[XR_HAND_JOINT_THUMB_PROXIMAL_EXT].origin == Vector3.ZERO:
		return TRACKING_CONFIDENCE_NONE
	return skel.get_parent().get_tracking_confidence()



static func transform_set_look_at_with_y(pfrom, pto, p_up):
	var v_z = pto - pfrom
	v_z = v_z.normalized()
	var v_y = -p_up
	var v_x = v_y.cross(v_z)
	v_y = v_z.cross(v_x)
	v_x = v_x.normalized()
	v_y = v_y.normalized()	
	return Transform(Basis(-v_y, v_z, -v_x), pfrom)

static func setfingerbonesGXT(ib1, tproximal, tintermediate, tdistal, ttip, bonerest, bonepose, t0boneposeG, bright):
	var ib2 = ib1+1
	var ib3 = ib2+1
	var ib4 = ib3+1
	var Ds = 1 if bright else -1
	var t1bonerestG = t0boneposeG*bonerest[ib1]
	var t1boneposeGT = transform_set_look_at_with_y(t1bonerestG.origin, tproximal.origin, t1bonerestG.basis.y*Ds)
	bonepose[ib1] = t1bonerestG.inverse()*t1boneposeGT
	var t1boneposeG = t1bonerestG*bonepose[ib1]
	var t2bonerestG = t1boneposeG*bonerest[ib2]
	var t2boneposeGT = transform_set_look_at_with_y(tproximal.origin, tintermediate.origin, tproximal.basis.y*Ds)
	bonepose[ib2] = t2bonerestG.inverse()*t2boneposeGT	
	var t2boneposeG = t2bonerestG*bonepose[ib2]
	var t3bonerestG = t2boneposeG*bonerest[ib3]
	var t3boneposeGT = transform_set_look_at_with_y(tintermediate.origin, tdistal.origin, tintermediate.basis.y*Ds)
	bonepose[ib3] = t3bonerestG.inverse()*t3boneposeGT
	var t3boneposeG = t3bonerestG*bonepose[ib3]
	var t4bonerestG = t3boneposeG*bonerest[ib4]
	var tipadjusted = ttip.origin
	var t4boneposeGT = transform_set_look_at_with_y(tdistal.origin, tipadjusted, tdistal.basis.y*Ds)
	bonepose[ib4] = t4bonerestG.inverse()*t4boneposeGT


static func setshapetobonesLowPoly(joint_transforms, bonerest, bright=true):
	var rotz90 = Transform(Basis(Vector3(0,0,1), deg2rad(90 if bright else -90)))

	var wristtransform = joint_transforms[XR_HAND_JOINT_WRIST_EXT]*rotz90
	var bonepose = { "handtransform":wristtransform }
	for i in range(25):
		bonepose[i] = Transform()
	bonepose[0] = Transform(Basis(), -bonerest[0].basis.xform_inv(bonerest[0].origin))
	
	var tRboneposeGR = bonepose["handtransform"]*bonerest["skeltrans"]
	var thmetacarpal = joint_transforms[XR_HAND_JOINT_THUMB_METACARPAL_EXT]
	var thproximal = joint_transforms[XR_HAND_JOINT_THUMB_PROXIMAL_EXT]
	var thdistal = joint_transforms[XR_HAND_JOINT_THUMB_DISTAL_EXT]
	var thtip = joint_transforms[XR_HAND_JOINT_THUMB_TIP_EXT]

	var t0boneposeG = tRboneposeGR*bonerest[0]*bonepose[0]
	var t1bonerestG = t0boneposeG*bonerest[1]
	var t1boneposeGT = transform_set_look_at_with_y(thmetacarpal.origin, thproximal.origin, thmetacarpal.basis.x)
	bonepose[1] = t1bonerestG.inverse()*t1boneposeGT
	var t1boneposeG = t1bonerestG*bonepose[1]
	var t2bonerestG = t1boneposeG*bonerest[2]
	var t2boneposeGT = transform_set_look_at_with_y(thproximal.origin, thdistal.origin, thproximal.basis.x)
	bonepose[2] = t2bonerestG.inverse()*t2boneposeGT
	var t2boneposeG = t2bonerestG*bonepose[2]
	var t3bonerestG = t2boneposeG*bonerest[3]
	var t3boneposeGT = transform_set_look_at_with_y(thdistal.origin, thtip.origin, thdistal.basis.x)
	bonepose[3] = t3bonerestG.inverse()*t3boneposeGT
	var t3boneposeG = t3bonerestG*bonepose[3]

	setfingerbonesGXT(5, joint_transforms[XR_HAND_JOINT_INDEX_PROXIMAL_EXT], joint_transforms[XR_HAND_JOINT_INDEX_INTERMEDIATE_EXT], joint_transforms[XR_HAND_JOINT_INDEX_DISTAL_EXT], joint_transforms[XR_HAND_JOINT_INDEX_TIP_EXT], bonerest, bonepose, t0boneposeG, bright)
	setfingerbonesGXT(10, joint_transforms[XR_HAND_JOINT_MIDDLE_PROXIMAL_EXT], joint_transforms[XR_HAND_JOINT_MIDDLE_INTERMEDIATE_EXT], joint_transforms[XR_HAND_JOINT_MIDDLE_DISTAL_EXT], joint_transforms[XR_HAND_JOINT_MIDDLE_TIP_EXT], bonerest, bonepose, t0boneposeG, bright)
	setfingerbonesGXT(15, joint_transforms[XR_HAND_JOINT_RING_PROXIMAL_EXT], joint_transforms[XR_HAND_JOINT_RING_INTERMEDIATE_EXT], joint_transforms[XR_HAND_JOINT_RING_DISTAL_EXT], joint_transforms[XR_HAND_JOINT_RING_TIP_EXT], bonerest, bonepose, t0boneposeG, bright)
	setfingerbonesGXT(20, joint_transforms[XR_HAND_JOINT_LITTLE_PROXIMAL_EXT], joint_transforms[XR_HAND_JOINT_LITTLE_INTERMEDIATE_EXT], joint_transforms[XR_HAND_JOINT_LITTLE_DISTAL_EXT], joint_transforms[XR_HAND_JOINT_LITTLE_TIP_EXT], bonerest, bonepose, t0boneposeG, bright)

	if false and not bright:
		for i in range(1, 25):
			bonepose[i].origin = Vector3(0,0,0)

	return bonepose


func handtrackingvisibility(LRHand, palm_joint_confidence, joint_transforms, controllerLR, gxthandrestdata, bright):
	if controllerLR:
		controllerLR.visible = (palm_joint_confidence == TRACKING_CONFIDENCE_NOT_APPLICABLE)
	if LRHand:
		if palm_joint_confidence == TRACKING_CONFIDENCE_NOT_APPLICABLE:
			LRHand.visible = false
		elif palm_joint_confidence == TRACKING_CONFIDENCE_HIGH:
			var lowpolyhandpose = setshapetobonesLowPoly(joint_transforms, gxthandrestdata, bright)
			var rotz90 = Transform(Basis(Vector3(0,0,1), deg2rad(90 if bright else -90)))
			LRHand.transform = joint_transforms[0]*rotz90
			lowpolyhandpose[0].origin.y -= 0.05  # fudgefactos also shared with controller position
			var skel = gxthandrestdata["skel"]
			for i in range(25):
				skel.set_bone_pose(i, lowpolyhandpose[i])
			LRHand.visible = true
		else:
			LRHand.visible = false  # or fade out


# The skeleton is only updated by the system in _physics_process
# https://github.com/GodotVR/godot_openxr/blob/master/src/gdclasses/OpenXRSkeleton.cpp#L94
func _physics_process(delta):
	palm_joint_confidence_L = skel_backtoOXRjointtransforms(joint_transforms_L, $LeftHandSkelPose/LeftHandBlankSkeleton) \
		if $LeftHandSkelPose.is_active() else TRACKING_CONFIDENCE_NOT_APPLICABLE
	handtrackingvisibility(LeftHand, palm_joint_confidence_L, joint_transforms_L, _controller_left_node, gxtlefthandrestdata, false)
	palm_joint_confidence_R = skel_backtoOXRjointtransforms(joint_transforms_R, $RightHandSkelPose/RightHandBlankSkeleton) \
		if $RightHandSkelPose.is_active() else TRACKING_CONFIDENCE_NOT_APPLICABLE
	handtrackingvisibility(RightHand, palm_joint_confidence_R, joint_transforms_R, _controller_right_node, gxtrighthandrestdata, true)

	# crude implementation of thumb pinch MovementDirect
	# point more upwards to go backards
	if player_body and _handpointer_left_node.get_is_active():
		var pinchval = (_handpointer_left_node.get_joystick_axis(AXIS_HT_THUMB_INDEX_PINCH)+1.0)/2
		if pinchval > 0.7:
			var max_speed = 6.0
			var dir = -1 if _handpointer_left_node.transform.basis.z.y < -0.7 else 1
			player_body.ground_control_velocity.y += dir * (pinchval - 0.7) * max_speed
			var length = player_body.ground_control_velocity.length()
			if length > max_speed:
				player_body.ground_control_velocity *= max_speed / length
			player_body._apply_velocity_and_control(delta)


static func getGXThandrestdata(lrhand):
	var gxthanddata = { "lrhand":lrhand }
	var skel = lrhand.get_child(0).get_node("Armature/Skeleton")
	gxthanddata["skel"] = skel
	for i in range(25):
		gxthanddata[i] = skel.get_bone_rest(i)
		if i != 0 and skel.get_bone_parent(i) != 0:
			assert (is_zero_approx(gxthanddata[i].origin.x) and is_zero_approx(gxthanddata[i].origin.z) and gxthanddata[i].origin.y >= 0)
	gxthanddata["skeltrans"] = lrhand.global_transform.affine_inverse()*skel.global_transform
	return gxthanddata

func _ready():
	for child in get_children():
		if child.is_class("XRToolsHand"):
			if child.get_child(0).transform != Transform():
				print("Setting ", child, ".first_child to identity transform")
				child.get_child(0).transform = Transform()
			if child.get_name().begins_with("Left"):
				LeftHand = child as XRToolsHand
			else:
				RightHand = child as XRToolsHand
	if LeftHand:
		LeftHand._animation_tree.active = false
		LeftHand.set_process(false)
		gxtlefthandrestdata = getGXThandrestdata(LeftHand)
		
		# make a node hand from the openxr library so we can 
		# see how well the hand tracking aligns with it
		add_child(load("res://addons/godot-openxr/scenes/left_hand_nodes.tscn").instance())
		
	if RightHand:
		RightHand._animation_tree.active = false
		RightHand.set_process(false)
		gxtrighthandrestdata = getGXThandrestdata(RightHand)

	set_physics_process(specialist_openxr_gdns_script_loaded)
