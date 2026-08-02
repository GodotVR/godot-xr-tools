@tool
@icon("res://addons/godot-xr-tools/editor/icons/rumble.svg")
class_name XRToolsRumbler
extends Node

## XR Tools Rumbler
##
## Attaches to a node to contain, activate or cancel rumble events.

## Details of this rumbler
@export var event: XRToolsRumbleEvent: set = _set_event

## Controller to rumble
@export var target: XRNode3D


# Verifies the hand has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := PackedStringArray()

	# Check hand for animation player
	if not event:
		warnings.append("Rumbler must have a rumble event")

	# Return warnings
	return warnings


## Cancels the rumble event
func cancel() -> void:
	XRToolsRumbleManager.clear(self)


## Cancels rumble for the hand which owns the node
func cancel_hand(hand_child: Node3D) -> void:
	var hand: XRNode3D = XRHelpers.get_xr_controller(hand_child)
	if is_instance_valid(hand):
		XRToolsRumbleManager.clear(self, [hand.tracker])


## Cancels rumble for the event, if provided the [XRPlayerBody]
func cancel_if_player_body(body: Node3D) -> void:
	if is_instance_valid(body) and body is XRToolsPlayerBody:
		cancel()


## Activates the rumble event
func rumble() -> void:
	if is_instance_valid(target):
		XRToolsRumbleManager.add(self, event, [target.tracker])


## Rumbles on the hand which owns the node
func rumble_hand(hand_child: Node3D) -> void:
	var hand: XRNode3D = XRHelpers.get_xr_controller(hand_child)
	if is_instance_valid(hand):
		XRToolsRumbleManager.add(self, event, [hand.tracker])


## Activates the event, if provided the [XRPlayerBody]
func rumble_if_player_body(body: Node3D) -> void:
	if is_instance_valid(body) and body is XRToolsPlayerBody:
		rumble()


## Activates the event during an active pointer event
func rumble_pointer(event: XRToolsPointerEvent) -> void:
	if event.event_type == XRToolsPointerEvent.Type.PRESSED:
		rumble_hand(event.pointer)
	elif event.event_type == XRToolsPointerEvent.Type.RELEASED:
		cancel_hand(event.pointer)


func _set_event(p_event: XRToolsRumbleEvent) -> void:
	event = p_event
	update_configuration_warnings()
