tool
class_name Function_WindMovement
extends MovementProvider

## Signal invoked when changing active wind areas
signal wind_area_changed(active_wind_area)

## Movement provider order
export var order := 25

## Drag multiplier for the player
export var drag_multiplier := 1.0

# Wind area
onready var _sense_area: Area = $Area

# Array of wind areas the player is in
var _in_wind_areas := Array()

# Currently active wind area
var _active_wind_area: WindArea = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Subscribe to area notifications
	_sense_area.connect("area_entered", self, "_on_area_entered")
	_sense_area.connect("area_exited", self, "_on_area_exited")

func _on_area_entered(area: Area):
	# Skip if not wind area
	var wind_area = area as WindArea
	if !wind_area:
		return

	# Save area and set active
	_in_wind_areas.push_front(wind_area)
	_active_wind_area = wind_area

	# Report the wind area change
	emit_signal("wind_area_changed", _active_wind_area)

func _on_area_exited(area: Area):
	# Erase from the wind area
	_in_wind_areas.erase(area)
	
	# If we didn't leave the active wind area then we're done
	if area != _active_wind_area:
		return

	# Select a new active wind area
	if _in_wind_areas.empty():
		_active_wind_area = null
	else:
		_active_wind_area = _in_wind_areas.front()

	# Report the wind area change
	emit_signal("wind_area_changed", _active_wind_area)

# Perform jump movement
func physics_movement(delta: float, player_body: PlayerBody):
	# Make sure the sense area tracks the player body
	_sense_area.global_transform = player_body.kinematic_node.global_transform
	
	# Skip if no active wind area
	if !_active_wind_area:
		return

	# Calculate the global wind velocity of the wind area
	var wind_velocity := _active_wind_area.to_global(_active_wind_area.wind_vector) - _active_wind_area.global_transform.origin

	# Drag the player into the wind
	var drag_factor := _active_wind_area.drag * drag_multiplier * delta
	drag_factor = clamp(drag_factor, 0.0, 1.0)
	player_body.velocity = lerp(player_body.velocity, wind_velocity, drag_factor)

# This method verifies the MovementProvider has a valid configuration.
func _get_configuration_warning():
	# Call base class
	return ._get_configuration_warning()
