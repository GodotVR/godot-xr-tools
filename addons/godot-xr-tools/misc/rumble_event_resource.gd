class_name XRToolsRumbleEvent, "res://addons/godot-xr-tools/editor/icons/rumble.svg"
extends Resource

##
## XR Rumble Event Resource
##

export(float) var magnitude

export(int, "Both", "Left", "Right") var hand

export(bool) var pausable

export(int) var duration_ms

var remaining_ms: int

# Make sure that every parameter has a default value.
# Otherwise, there will be problems with creating and editing
# your resource via the inspector.
func _init(		p_magnitude = 0.1,
				p_hand := 0,
				p_duration_ms := 0,
				p_pausable := true):
	magnitude = p_magnitude
	hand = p_hand
	duration_ms = p_duration_ms
	reset_remaining()
	pausable = p_pausable

# re-arms event for re-use
func reset_remaining() -> void:
	remaining_ms = duration_ms

