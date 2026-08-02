class_name XRToolsRumbleManagerQueue
extends Resource

## XR Tools Rumble Manager Queue
##
## Used to sort rumble events in order of arrival

## All currently-active events
var events: Dictionary[Variant, XRToolsRumbleEvent]

## All currently-active events' remaining time
var time_remaining: Dictionary[Variant, int]


func _init() -> void:
	events = {}
	time_remaining = {}
