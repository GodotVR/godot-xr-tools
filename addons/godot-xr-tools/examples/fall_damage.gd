@tool
class_name XRToolsFallDamage
extends XRToolsMovementProvider


## XR Tools Example Fall Damage Detector
##
## This example script detects the player falling to the ground and
## optionally hitting walls.
##
## It works by tracking the player body velocity to detect velocity
## changes (acceleration) exceeding a threshold.
##
## This doesn't use the usual Acceleration = dV / dT as it doesn't appear
## to work too well considering the "instantaneous" nature of the
## collision. Additionally all it would end up doing is multiplying the
## change in velocity by the physics-frame-rate making it sensitive to
## varying physics timing.
##
## Instead the threshold in terms of delta-velocity makes it easy to work
## out natural values. For example if the player falls under regular gravity
## (9.81 meters per second^2 for 1 second) then hits the ground, they will have fallen around
## 4.9 meters, and will then encounter an instantaneous velocity-change of
## 9.81 meters per second.
##
## This file can handle simple demonstrations, but games will most likely
## want to modify it, for example to ignore damage on certain surfaces.


## Signal invoked when the player takes fall damage
signal player_fall_damage(damage)


## Movement provider order
@export var order : int = 1000

## Ignore damage if player is launched up
@export var ignore_launch : bool = true

## Only take damage on ground
@export var ground_only : bool = false

## Acceleration limit
@export var damage_threshold : float = 8.0


## Previous velocity
var _previous_velocity : Vector3 = Vector3.ZERO


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsFallDamage"


func _ready():
	# In Godot 4 we must now manually call our super class ready function
	super()

	# Set as always active
	is_active = true


func physics_movement(_delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Skip if not enabled
	if disabled or !enabled:
		_previous_velocity = player_body.velocity
		return

	# Calculate the instantaneous acceleration
	var accel_vec := player_body.velocity - _previous_velocity
	_previous_velocity = player_body.velocity

	# Ignore launching the player
	if ignore_launch:
		# Forgive "up" acceleration equal to our "up" speed
		var forgive : float = max(0, min(accel_vec.y, player_body.velocity.y))
		accel_vec.y -= forgive

	# Handle ground-only collisions
	if ground_only:
		# Ignore if not on ground
		if not player_body.on_ground:
			return

		# Only consider vertical acceleration
		accel_vec *= Vector3.UP

	# Detect fall damage
	var accel := accel_vec.length()
	if accel > damage_threshold:
		emit_signal("player_fall_damage", accel)
