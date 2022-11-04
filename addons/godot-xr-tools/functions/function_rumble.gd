class_name XRToolsRumble, "res://addons/godot-xr-tools/editor/icons/rumble.svg"
extends Node

##
## XR Rumble Control Script
##
## This script uses the controller's existing rumble... TODO
##
## Example: something hits you while you're mowing the lawn,
## i.e. a short intense rumble happens during long low rumble.
##

enum Hand { BOTH = 0, LEFT = 1, RIGHT = 2 }

export(float, 0.0, 1.0, 0.05) var wakeup_rumble := 0.0

## Used to control rumble like volume
export(float, 0.0, 1.0, 0.05) var magnitude_scale := 1.0

export(Resource) var default_rumble_event = create_event()

# dictionary event_name to XRToolsRumbleEvent
var _events: Dictionary = {}

var _time_start := 0

onready var _controller_left_node: ARVRController = ARVRHelpers.get_left_controller(self)

onready var _controller_right_node: ARVRController = ARVRHelpers.get_right_controller(self)



static func combine_magnitudes(weak: float, strong: float) -> float:
	if strong >= 0.01:
		return 0.5 + clamp(strong / 2, 0.0, 0.5)
	return clamp(weak / 2, 0.0, 0.5)


static func normal_clamp(value: float) -> float:
	return clamp(value, 0.0, 1.0)


static func sec_to_ms(secs: float) -> int:
	return int(secs * 1000)


static func create_event(
	magnitude := 0.1, hand := 0, duration_ms := 100, pausable := true
) -> XRToolsRumbleEvent:
	var event = XRToolsRumbleEvent.new()
	event.magnitude = magnitude
	event.hand = hand
	event.duration_ms = duration_ms
	event.pausable = pausable
	return event


func _ready():
	set("wakeup", wakeup_rumble, 0, 150, false)


func _process(delta: float) -> void:
	# default to no rumble (ensure it's a float, or it rounds to all or nothing!)
	var left_magnitude: float = 0.0
	var right_magnitude: float = 0.0

	# We'll be subtracting this from the event remaining ms
	var delta_ms = sec_to_ms(delta)

	# Iterate over the events
	for key in _events.keys():
		var event = _events[key]

		# If it was defined negative time, then it's meant to go until manually stopped
		var indefinite = event.duration_ms < 0

		# Reduce the time remaining if we're not paused, or it's not a pausable event
		if not get_tree().paused or not event.pausable:
			event.remaining_ms -= delta_ms

			# If we've passed the threshold from positive to negative, the event is done
			if !indefinite and event.remaining_ms < 0:
				_events.erase(key)
				continue

		# If it's a left or both hand and greater magnitude, update left magnitude
		if event.hand != Hand.RIGHT and event.magnitude > left_magnitude:
			left_magnitude = event.magnitude

		# If it's a right or both hand and greater magnitude, update right magnitude
		if event.hand != Hand.LEFT and event.magnitude > right_magnitude:
			right_magnitude = event.magnitude

	# now that we're done looping through the events, set the rumbles, scaled
	if is_instance_valid(_controller_left_node):
		_controller_left_node.rumble = normal_clamp(left_magnitude * magnitude_scale)
	if is_instance_valid(_controller_right_node):
		_controller_right_node.rumble = normal_clamp(right_magnitude * magnitude_scale)


func set(
	event_name: String, magnitude: float, hand := 0, duration_ms := -1, pausable := true
) -> void:
	set_event(event_name, create_event(magnitude, hand, duration_ms, pausable))


func set_event(event_name: String, event: XRToolsRumbleEvent) -> void:
	event.reset_remaining()  # re-arms event for re-use
	_events[event_name] = event


func remove(event_name: String) -> void:
	_events.erase(event_name)
