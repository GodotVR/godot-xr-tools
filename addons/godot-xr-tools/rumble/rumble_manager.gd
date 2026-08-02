extends Node

## XR Tools Rumble (Controllers) Manager Script
##
## This script uses the controller's existing rumble intensity variable,
## and allows you to rumble the controller for a certain amount of time 'beats'.
##
## Example: something hits you while you're mowing the lawn,
## i.e. a short intense rumble happens during long low rumble.


## Name in the OpenXR Action Map for haptics
const HAPTIC_ACTION := &"haptic" # TODO: Migrate

## Shorthand for all trackers, in use to be substituted with _queues.keys()
const ALL_TRACKERS: Array[StringName] = [&"all"]


# A queue per haptic device
var _queues: Dictionary[StringName, XRToolsRumbleManagerQueue] = {}


# On Ready
func _ready() -> void:
	if Engine.is_editor_hint():
		return

	# Some rumble events are active during pause
	process_mode = PROCESS_MODE_ALWAYS

	# Create a queues for standard controllers
	_queues[&"left_hand"] = XRToolsRumbleManagerQueue.new()
	_queues[&"right_hand"] = XRToolsRumbleManagerQueue.new()


# Determines how much to - and perform the - rumbles each tick
func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	# We'll be subtracting this from the event remaining ms
	var delta_ms := int(delta * 1000)

	for tracker_name: StringName in _queues:
		var haptic_queue: XRToolsRumbleManagerQueue = _queues[tracker_name]

		# default to no XRToolsRumbleManagerQueue
		# (if unsure it's a float, or it rounds to all or nothing!)
		var magnitude := 0.0

		# Iterate over the events
		for key: Variant in haptic_queue.events.keys():
			var event: XRToolsRumbleEvent = haptic_queue.events[key]

			# if we're paused and it's not supposed to be active, skip
			if get_tree().paused and not event.active_during_pause:
				continue

			# If we've passed the threshold from positive to negative, the event is done
			if not event.indefinite and haptic_queue.time_remaining[key] < 0:
				clear(key, [tracker_name])
				continue

			# Reduce the time remaining
			haptic_queue.time_remaining[key] -= delta_ms

			# If it's of greater magnitude, update left magnitude to be set
			if event.magnitude > magnitude:
				magnitude = event.magnitude

		# scale the final magnitude
		magnitude *= XRToolsUserSettings.haptics_scale

		# Make that tracker rumble
		if magnitude > 0 and XRServer.primary_interface:
			XRServer.primary_interface.trigger_haptic_pulse(
					HAPTIC_ACTION,
					tracker_name, # if the tracker name isn't valid,
					# it will error but continue
					0,
					magnitude,
					0.1,
					0,
			)


## Adds support for [method is_xr_class]
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsRumbleManager"


## Get the default Haptics Scale value
func get_default_haptics_scale() -> float:
	var default := 1.0

	# Check if the project has overridden the addon's default
	if ProjectSettings.has_setting("godot_xr_tools/input/haptics_scale"):
		default = ProjectSettings.get_setting("godot_xr_tools/input/haptics_scale")

	if default < 0.0 or default > 1.0:
		# out of bounds? reset to default
		default = 1.0

	return default


## Converts gamepad magnitudes to equivalent XR haptic magnitudes
func combine_magnitudes(weak: float, strong: float) -> float:
	if strong >= 0.01:
		return 0.5 + clamp(strong / 2, 0.0, 0.5)
	return clamp(weak / 2, 0.0, 0.5)


## Adds an [XRToolsRumbleEvent]
func add(
		event_key: Variant,
		event: XRToolsRumbleEvent,
		trackers: Array = ALL_TRACKERS,
) -> void:
	if not event_key:
		push_error("Event key is invalid!")
		return

	if not event:
		clear(event_key, trackers)
		return

	# Substitube the shorthand for all trackers with the real thing
	if trackers == ALL_TRACKERS:
		trackers = _queues.keys()

	for tracker: Variant in trackers:
		if tracker is XRNode3D:
			tracker = tracker.tracker

		# Create queue first time a target is suggested
		if not _queues.has(tracker):
			_queues[tracker] = XRToolsRumbleManagerQueue.new()

		# Add the event and it's remaining time to the respective queues
		_queues[tracker].events[event_key] = event
		_queues[tracker].time_remaining[event_key] = event.duration_ms


## Removes an [XRToolsRumbleEvent]
func clear(event_key: Variant, trackers: Array = ALL_TRACKERS) -> void:
	if not event_key:
		push_error("Event key is invalid!")
		return

	# Substitube the shorthand for all trackers with the real thing
	if trackers == ALL_TRACKERS:
		trackers = _queues.keys()

	for tracker: Variant in trackers:
		if tracker is XRNode3D:
			tracker = tracker.tracker

		# Ignore if the queue doesn't exist
		if not _queues.has(tracker):
			continue

		# Remove the event and it's remaining time from the respective queues
		_queues[tracker].events.erase(event_key)
		_queues[tracker].time_remaining.erase(event_key)
