@tool
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

## Grab mode for this grab point
enum Mode {
	GENERAL,	## General grab point
	PRIMARY,	## Primary-hand grab point
	SECONDARY	## Secondary-hand grab point
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


## Grab-point handle
@export var handle : String

## Which hand this grab point is for
@export var hand : Hand: set = _set_hand

## Hand grab mode
@export var mode : Mode = Mode.GENERAL

## Snap the hand mesh to the grab-point
@export var snap_hand : bool = true

## Hand pose
@export var hand_pose : XRToolsHandPoseSettings: set = _set_hand_pose

## If true, the hand is shown in the editor
@export var editor_preview_mode : PreviewMode = PreviewMode.CLOSED: set = _set_editor_preview_mode

## How much this grab-point drives the position
@export var drive_position : float = 1.0

## How much this grab-point drives the angle
@export var drive_angle : float = 1.0

## How much this grab-point drives the aim
@export var drive_aim : float = 0.0


## Hand to use for editor preview
var _editor_preview_hand : XRToolsHand


## Called when the node enters the scene tree for the first time.
func _ready():
	# If in the editor then update the preview
	if Engine.is_editor_hint():
		_update_editor_preview()


## Test if a grabber can grab by this grab-point
func can_grab(grabber : Node3D, current : XRToolsGrabPoint) -> float:
	# Skip if not enabled
	if not enabled:
		return 0.0

	# Verify the hand matches
	if not _is_correct_hand(grabber):
		return 0.0

	# Fail if the hand grab is not permitted
	if not _is_valid_hand_grab(current):
		return 0.0

	# Get the distance-weighted fitness in the range (0.0 - 0.5], but boost
	# to [0.5 - 1.0] for valid "specific" grabs.
	var fitness := _weight(grabber, 0.5)
	if mode != Mode.GENERAL:
		fitness += 0.5

	# Return the grab fitness
	return fitness


func _set_hand(new_value : Hand) -> void:
	hand = new_value
	if Engine.is_editor_hint():
		_update_editor_preview()


func _set_hand_pose(new_value : XRToolsHandPoseSettings) -> void:
	# Unsubscribe from the old hand-pose changed signal
	if Engine.is_editor_hint() and hand_pose:
		hand_pose.changed.disconnect(_update_editor_preview)

	# Save the hand pose
	hand_pose = new_value

	# Update the editor preview
	if Engine.is_editor_hint() and hand_pose:
		hand_pose.changed.connect(_update_editor_preview)
		_update_editor_preview()


func _set_editor_preview_mode(new_value : PreviewMode) -> void:
	editor_preview_mode = new_value
	if Engine.is_editor_hint():
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
	_editor_preview_hand = hand_scene.instantiate()

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


# Is the grabber for the correct hand
func _is_correct_hand(grabber : Node3D) -> bool:
	# Find the controller
	var controller := _get_grabber_controller(grabber)
	if not controller:
		return false

	# If left hand then verify left controller
	if hand == Hand.LEFT and controller.tracker != "left_hand":
		return false

	# If right hand then verify right controller
	if hand == Hand.RIGHT and controller.tracker != "right_hand":
		return false

	# Controller matches hand
	return true


# Test if hand grab is permitted
func _is_valid_hand_grab(current : XRToolsGrabPoint) -> bool:
	# Not a valid hand grab if currently held by something other than a hand
	var current_hand := current as XRToolsGrabPointHand
	if current and not current_hand:
		return false

	# Not valid if grabbing the same named handle
	if handle and current_hand and handle == current_hand.handle:
		return false

	# Not valid if attempting PRIMARY grab while current is PRIMARY
	if mode == Mode.PRIMARY and current_hand and current_hand.mode == Mode.PRIMARY:
		return false

	# Not valid if attempting SECONDARY grab while no current
	if mode == Mode.SECONDARY and not current_hand:
		return false

	# Hand is allowed to grab
	return true


# Get the controller associated with a grabber
static func _get_grabber_controller(grabber : Node3D) -> XRController3D:
	# Ensure the grabber is valid
	if not is_instance_valid(grabber):
		return null

	# Ensure the pickup is a function pickup for a controller
	var pickup := grabber as XRToolsFunctionPickup
	if not pickup:
		return null

	# Get the controller associated with the pickup
	return pickup.get_controller()
