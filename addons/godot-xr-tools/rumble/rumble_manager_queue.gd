class_name XRToolsRumbleManagerQueue
extends Resource

# All currently-active events (Dictionary<Variant, XRToolsRumbleEvent>)
var events: Dictionary

# All currently-active events' time remaining (Dictionary<Variant, int>)
var time_remaining: Dictionary

func _init():
	events = {}
	time_remaining = {}
