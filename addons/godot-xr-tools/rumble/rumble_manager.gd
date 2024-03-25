@icon("res://addons/godot-xr-tools/editor/icons/rumble.svg")
class_name XRToolsRumbleManager
extends Node


## XR Tools Rumble (Controllers) Manager Script
##
## This script uses the controller's existing rumble intensity variable,
## and allows you to rumble the controller for a certain amount
## of time 'beats'.
##
## Example: something hits you while you're mowing the lawn,
## i.e. a short intense rumble happens during long low rumble.


## Name in the OpenXR Action Map for haptics
const HAPTIC_ACTION = "haptic"


## Initial "Wake-Up" Rumble Magnitude
@export var wakeup_rumble : XRToolsRumbleEvent

# A Queue Per Haptic device (Dictionary<StringName, XRToolsRumbleManagerQueue>)
var _queues: Dictionary = {}


# Keep track of singular instance
static var _instance: XRToolsRumbleManager


## Add support for is_xr_class
func is_xr_class(name: String) -> bool:
	return name == "XRToolsRumbleManager"


## Get the default Haptics Scale value
static func get_default_haptics_scale() -> float:
	var default = 1.0

	# Check if the project has overridden the addon's default
	if ProjectSettings.has_setting("godot_xr_tools/input/haptics_scale"):
		default = ProjectSettings.get_setting("godot_xr_tools/input/haptics_scale")

	if default < 0.0 or default > 1.0:
		# out of bounds? reset to default
		default = 1.0

	return default


## Used to convert gamepad magnitudes to equivalent XR haptic magnitude
static func combine_magnitudes(weak: float, strong: float) -> float:
	if strong >= 0.01:
		return 0.5 + clamp(strong / 2, 0.0, 0.5)
	return clamp(weak / 2, 0.0, 0.5)


# Enforce singleton
func _enter_tree():
	if not is_instance_valid(_instance):
		_instance = self
	else:
		self.queue_free()


# Clear instance if this is the singleton
func _exit_tree():
	if is_instance_valid(_instance) and _instance == self:
		_instance = null


# On Ready
func _ready():
	if Engine.is_editor_hint():
		return

	# Some rumble events are active during pause
	process_mode = PROCESS_MODE_ALWAYS

	# Create a queues for standard controllers
	_queues[&"left_hand"] = XRToolsRumbleManagerQueue.new()
	_queues[&"right_hand"] = XRToolsRumbleManagerQueue.new()

	if wakeup_rumble:
		_add("wakeup", wakeup_rumble, _queues.keys())


# Determine how much to - and perform the - rumbles each tick
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# We'll be subtracting this from the event remaining ms
	var delta_ms = int(delta * 1000)

	for tracker_name in _queues:
		var haptic_queue : XRToolsRumbleManagerQueue = _queues[tracker_name]

		# default to noXRToolsRumbleManagerQueuensure it's a float, or it rounds to all or nothing!)
		var magnitude: float = 0.0

		# Iterate over the events
		for key in haptic_queue.events.keys():
			var event : XRToolsRumbleEvent = haptic_queue.events[key]

			# if we're paused and it's not supposed to be active, skip
			if get_tree().paused and not event.active_during_pause:
				continue

			# If we've passed the threshold from positive to negative, the event is done
			if !event.indefinite and haptic_queue.time_remaining[key] < 0:
				_remove(key)
				continue

			# Reduce the time remaining
			haptic_queue.time_remaining[key] -= delta_ms

			# If it's of greater magnitude, update left magnitude to be set
			if event.magnitude > magnitude:
				magnitude = event.magnitude

		# scale the final magnitude
		magnitude *= XRToolsUserSettings.haptics_scale

		# Make that tracker rumble
		if magnitude > 0:
			XRServer.primary_interface.trigger_haptic_pulse(
				HAPTIC_ACTION,
				tracker_name, # if the tracker name isn't valid, it will error but continue
				0,
				magnitude * XRToolsUserSettings.haptics_scale,
				0.1,
				0)


# actually set an event
func _add(event_key: Variant, event: XRToolsRumbleEvent,
					targets: Array = [&"left_hand", &"right_hand"]) -> void:
	if not event_key:
		push_error("Event key is invalid! ")
		return

	if not event:
		_remove(event_key)
		return

	for target in targets:
		if target is XRNode3D:
			target = target.tracker

		# Create queue first time a target is suggested
		if not _queues.has(target):
			_queues[target] = XRToolsRumbleManagerQueue.new()

		_queues[target].events[event_key] = event
		_queues[target].time_remaining[event_key] = event.duration_ms


## Adds the event to the list of currently-active rumbles
static func add(event_key: Variant, event: XRToolsRumbleEvent,
								targets: Array = [&"left_hand", &"right_hand"]):
	if is_instance_valid(_instance):
		#gdlint:ignore = private-method-call
		_instance._add(event_key, event, targets)


# Actually remove an event
func _remove(event_key: Variant,
			targets: Array = [&"left_hand", &"right_hand"]) -> void:
	if event_key == null:
		return

	for target in targets:
		if target is XRNode3D:
			target = target.tracker
		_queues[target].events.erase(event_key)
		_queues[target].time_remaining.erase(event_key)


# Actually remove an event from all queues
func _remove_all(event_key: Variant) -> void:
	_remove(event_key, _instance._queues.keys())


## Removes the event from the list of currently-active rumbles
static func clear(event_key: Variant, targets: Array = [&"left_hand", &"right_hand"]):
	if is_instance_valid(_instance):
		#gdlint:ignore = private-method-call
		_instance._remove(event_key, targets)


## Removes the event from the list of currently-active rumbles
static func clear_all(event_key: Variant):
	if is_instance_valid(_instance):
		#gdlint:ignore = private-method-call
		_instance._remove_all(event_key)
