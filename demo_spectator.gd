extends Node2D

## XR Tools spectator scene
##
## This demo scene shows an example implemention of
## a 3rd person spectator system.
##
## By setting this as your run scene, output to the HMD is handled by
## a separete viewport leaving the main viewport free for alternate content.
## The example shows this used for an alternative view of the virtual world.
##
## Note that this is only suitable for PC, hence the project settings
## for our demo project are only configured to use this scene on PCs.

@export_range(10, 1000, 10, "suffix:ms") var smooth_delay = 200

@onready var follow_origin : Node3D = $FollowXROrigin
@onready var follow_camera : Node3D = $FollowXROrigin/FollowXRCamera
@onready var spectator_camera : Camera3D = $SpectatorCamera
@onready var over_shoulder_pos : Node3D = $FollowXROrigin/OverShoulderCameraPos
@onready var selfie_pos : Node3D = $FollowXROrigin/FrontCameraPos

@onready var ui_camera_pos : OptionButton = $VBoxContainer/CameraPosSelection

var _last_smoothed_transform : Transform3D

# Called when the node enters the scene tree for the first time.
func _ready():
	# We can splurge a bit on our spectator view. 
	var vp : Viewport = get_viewport()
	vp.msaa_3d = Viewport.MSAA_4X
	vp.use_debanding = true

	_last_smoothed_transform = follow_camera.transform

	# Make sure we set this correctly at the start
	_on_show_debug_axis_toggled($VBoxContainer/ShowDebugAxis.button_pressed)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	follow_origin.global_transform = XRServer.world_origin

	var head_tracker : XRPositionalTracker = XRServer.get_tracker("head")
	if head_tracker:
		var pose = head_tracker.get_pose("default")
		if pose and pose.has_tracking_data:
			follow_camera.transform = pose.get_adjusted_transform()

	match ui_camera_pos.selected:
		0:
			spectator_camera.global_transform = over_shoulder_pos.global_transform
		1:
			spectator_camera.global_transform = selfie_pos.global_transform
		2:
			# For first person view we do a little more
			var t : Transform3D = follow_camera.transform

			# Remove pitch
			t = t.looking_at(t.origin + t.basis.z, Vector3.UP, true)
			t.origin -= t.basis.z * 0.01

			# Now smooth the camera
			var strength : float = delta * 1000 / smooth_delay
			t.basis = _last_smoothed_transform.basis.slerp(t.basis, strength)
			t.origin = _last_smoothed_transform.origin.lerp(t.origin, strength)

			_last_smoothed_transform = t

			spectator_camera.global_transform = follow_origin.global_transform * t


func _on_show_debug_axis_toggled(toggled_on):
	for axis in get_tree().get_nodes_in_group("DebugAxis"):
		axis.visible = toggled_on
