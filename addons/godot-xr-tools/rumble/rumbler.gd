@tool
@icon("res://addons/godot-xr-tools/editor/icons/rumble.svg")
class_name XRToolsRumbler
extends Node

## XR Tools Rumbler
##
## A node you attach to handle (contain and make easy to activate/cancel)
## a particular rumble event.

## The details of this rumbler
@export var event: XRToolsRumbleEvent : set = _set_event

@export var target: XRNode3D

## Activate the event
func rumble() -> void:
	XRToolsRumbleManager.add(self, event, [target.tracker])


## Cancel the event
func cancel() -> void:
	XRToolsRumbleManager.clear(self)


## Rumble on the hand which owns the node
func rumble_hand(hand_child: Node3D) -> void:
	var hand: XRNode3D = XRHelpers.get_xr_controller(hand_child)
	if is_instance_valid(hand):
		XRToolsRumbleManager.add(self, event, [hand.tracker])


## Rumble on the hand which owns the node
func cancel_hand(hand_child: Node3D) -> void:
	var hand: XRNode3D = XRHelpers.get_xr_controller(hand_child)
	if is_instance_valid(hand):
		XRToolsRumbleManager.clear(self, [hand.tracker])


## Activate the event if provided the XR player body
func rumble_if_player_body(body: Node) -> void:
	if body is XRToolsPlayerBody:
		rumble()


func _set_event(p_event: XRToolsRumbleEvent) -> void:
	event = p_event
	update_configuration_warnings()


# This method verifies the hand has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check hand for animation player
	if not event:
		warnings.append("Rumbler must have a rumble event")

	# Return warnings
	return warnings
