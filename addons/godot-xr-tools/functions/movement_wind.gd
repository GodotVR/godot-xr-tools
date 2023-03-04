@tool
class_name XRToolsMovementWind
extends XRToolsMovementProvider


## XR Tools Movement Provider for Wind
##
## This script provides wind mechanics for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## When the player enters an [XRToolsWindArea], the wind pushes the player
## around, and can even lift the player into the air.


## Signal invoked when changing active wind areas
signal wind_area_changed(active_wind_area)


# Default wind area collision mask of 20:player-body
const DEFAULT_MASK := 0b0000_0000_0000_1000_0000_0000_0000_0000


## Movement provider order
@export var order : int = 25

## Drag multiplier for the player
@export var drag_multiplier : float = 1.0

# Set our collision mask
@export_flags_3d_physics var collision_mask : int = DEFAULT_MASK: set = set_collision_mask


# Wind detection area
var _sense_area : Area3D

# Array of wind areas the player is in
var _in_wind_areas := Array()

# Currently active wind area
var _active_wind_area : XRToolsWindArea


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsMovementWind" or super(name)


# Called when the node enters the scene tree for the first time.
func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Skip if running in the editor
	if Engine.is_editor_hint():
		return

	# Skip if we don't have a camera
	var camera := XRHelpers.get_xr_camera(self)
	if !camera:
		return

	# Construct the sphere shape
	var sphere_shape := SphereShape3D.new()
	sphere_shape.radius = 0.3

	# Construct the collision shape
	var collision_shape := CollisionShape3D.new()
	collision_shape.set_name("WindSensorShape")
	collision_shape.shape = sphere_shape

	# Construct the sense area
	_sense_area = Area3D.new()
	_sense_area.set_name("WindSensorArea")
	_sense_area.collision_mask = collision_mask
	_sense_area.add_child(collision_shape)

	# Add the sense area to the camera
	camera.add_child(_sense_area)

	# Subscribe to area notifications
	_sense_area.area_entered.connect(_on_area_entered)
	_sense_area.area_exited.connect(_on_area_exited)


func set_collision_mask(new_mask: int) -> void:
	collision_mask = new_mask
	if is_inside_tree() and _sense_area:
		_sense_area.collision_mask = collision_mask


func _on_area_entered(area: Area3D):
	# Skip if not wind area
	var wind_area = area as XRToolsWindArea
	if !wind_area:
		return

	# Save area and set active
	_in_wind_areas.push_front(wind_area)
	_active_wind_area = wind_area

	# Report the wind area change
	emit_signal("wind_area_changed", _active_wind_area)


func _on_area_exited(area: Area3D):
	# Erase from the wind area
	_in_wind_areas.erase(area)

	# If we didn't leave the active wind area then we're done
	if area != _active_wind_area:
		return

	# Select a new active wind area
	if _in_wind_areas.is_empty():
		_active_wind_area = null
	else:
		_active_wind_area = _in_wind_areas.front()

	# Report the wind area change
	emit_signal("wind_area_changed", _active_wind_area)


# Perform wind movement
func physics_movement(delta: float, player_body: XRToolsPlayerBody, _disabled: bool):
	# Skip if no active wind area
	if !_active_wind_area:
		return

	# Calculate the global wind velocity of the wind area
	var wind_velocity := _active_wind_area.global_transform.basis * _active_wind_area.wind_vector

	# Drag the player into the wind
	var drag_factor := _active_wind_area.drag * drag_multiplier * delta
	drag_factor = clamp(drag_factor, 0.0, 1.0)
	player_body.velocity = player_body.velocity.lerp(wind_velocity, drag_factor)
