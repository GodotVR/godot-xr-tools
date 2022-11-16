class_name XRToolsHandPoseArea
extends Area


## XR Tools Hand Pose Area Script
##
## This script adds hand pose overrides when hands enter this area.


## Left open-hand animation pose
export var left_open_hand : Animation

## Left closed-hand animation pose
export var left_closed_hand : Animation

## Right open-hand animation pose
export var right_open_hand : Animation

## Left closed-hand animation pose
export var right_closed_hand : Animation


## Called when the node enters the scene tree for the first time.
func _ready():
	if connect("area_entered", self, "_on_area_entered"):
		push_error("Unable to connect area entered signal")
	if connect("area_exited", self, "_on_area_exited"):
		push_error("Unable to connect area entered signal")


## Called when an area enters this area - intended to detect hands
func _on_area_entered(area : Area) -> void:
	# Make sure area is a hand
	var hand := area as XRToolsHand
	if !hand:
		return

	# Get the hand controller
	var controller := hand.get_parent() as ARVRController
	if !controller:
		return

	# Add the overrides
	if controller.controller_id == 1:
		hand.add_hand_override(self, left_open_hand, left_closed_hand)
	elif controller.controller_id == 2:
		hand.add_hand_override(self, right_open_hand, right_closed_hand)


## Called when an area leaves this area - intended to detect hands
func _on_area_exited(area : Area) -> void:
	# Make sure area is a hand
	var hand := area as XRToolsHand
	if !hand:
		return

	# Remove any overrides
	hand.remove_hand_override(self)
