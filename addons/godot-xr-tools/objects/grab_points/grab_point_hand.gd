tool
class_name XRToolsGrabPointHand
extends XRToolsGrabPoint


## XR Tools Grab Point Hand Script
##
## This script allows specifying a grab point for a specific hand. Additionally
## the grab point can be used to control the pose of the hand, and to allow the
## grab point position to be fine-tuned in the editor.


## Hand for this grab point
enum Hand {
	LEFT,	## Left hand
	RIGHT,	## Right hand
}

## Hand preview option
enum PreviewMode {
	CLOSED,	## Preview hand closed
	OPEN,	## Preview hand open
}


## Left hand scene path (for editor preview)
const LEFT_HAND_PATH := "res://addons/godot-xr-tools/hands/scenes/lowpoly/left_hand_low.tscn"

## Right hand scene path (for editor preview)
const RIGHT_HAND_PATH := "res://addons/godot-xr-tools/hands/scenes/lowpoly/right_hand_low.tscn"


## Which hand this grab point is for
export (Hand) var hand : int setget _set_hand

## Hand pose
export var hand_pose : Resource setget _set_hand_pose

## If true, the hand is shown in the editor
export (PreviewMode) \
		var editor_preview_mode : int = PreviewMode.CLOSED setget _set_editor_preview_mode


## Hand to use for editor preview
var _editor_preview_hand : XRToolsHand


## Called when the node enters the scene tree for the first time.
func _ready():
	# If in the editor then update the preview
	if Engine.editor_hint:
		_update_editor_preview()


## Test if a grabber can grab by this grab-point
func can_grab(_grabber : Node) -> bool:
	# Skip if not enabled
	if not enabled:
		return false

	# Get the grabber controller
	var controller := _get_grabber_controller(_grabber)
	if not controller:
		return false

	# Only allow left controller to grab left-hand grab points
	if hand == Hand.LEFT and controller.controller_id != 1:
		return false

	# Only allow right controller to grab right-hand grab points
	if hand == Hand.RIGHT and controller.controller_id != 2:
		return false

	# Allow grab
	return true


func _set_hand(new_value : int) -> void:
	hand = new_value
	if Engine.editor_hint:
		_update_editor_preview()


func _set_hand_pose(new_value : Resource) -> void:
	hand_pose = new_value
	if Engine.editor_hint:
		_update_editor_preview()


func _set_editor_preview_mode(new_value : int) -> void:
	editor_preview_mode = new_value
	if Engine.editor_hint:
		_update_editor_preview()


func _update_editor_preview() -> void:
	# Discard any existing hand model
	if _editor_preview_hand:
		remove_child(_editor_preview_hand)
		_editor_preview_hand.queue_free()
		_editor_preview_hand = null

	# Pick the hand scene
	var hand_path := LEFT_HAND_PATH if hand == Hand.LEFT else RIGHT_HAND_PATH
	var hand_scene : PackedScene = load(hand_path)
	if !hand_scene:
		return

	# Construct the model
	_editor_preview_hand = hand_scene.instance()

	# Set the pose
	if hand_pose:
		_editor_preview_hand.add_pose_override(self, 0.0, hand_pose)

	# Set the grip override
	if editor_preview_mode == PreviewMode.CLOSED:
		_editor_preview_hand.force_grip_trigger(1.0, 1.0)
	else:
		_editor_preview_hand.force_grip_trigger(0.0, 0.0)

	# Add the editor-preview hand as a child
	add_child(_editor_preview_hand)


# Get the controller associated with a grabber
static func _get_grabber_controller(_grabber : Node) -> ARVRController:
	# Ensure the grabber is valid
	if not is_instance_valid(_grabber):
		return null

	# Ensure the pickup is a function pickup for a controller
	var pickup := _grabber as XRToolsFunctionPickup
	if not pickup:
		return null

	# Get the controller associated with the pickup
	return pickup.get_controller()
