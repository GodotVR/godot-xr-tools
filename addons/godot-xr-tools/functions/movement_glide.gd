@tool
class_name XRToolsMovementGlide
extends XRToolsMovementProvider


## XR Tools Movement Provider for Gliding
##
## This script provides glide mechanics for the player. This script works
## with the [XRToolsPlayerBody] attached to the players [XROrigin3D].
##
## The player enables flying by moving the controllers apart further than
## 'glide_detect_distance'.
##
## When gliding, the players fall speed will slew to 'glide_fall_speed' and
## the velocity will slew to 'glide_forward_speed' in the direction the
## player is facing.
##
## Gliding is an exclusive motion operation, and so gliding should be ordered
## after any Direct movement providers responsible for turning.


## Signal invoked when the player starts gliding
signal player_glide_start

## Signal invoked when the player ends gliding
signal player_glide_end

## Signal invoked when the player flaps
signal player_flapped

## Movement provider order
@export var order : int = 35

## Controller separation distance to register as glide
@export var glide_detect_distance : float = 1.0

## Minimum falling speed to be considered gliding
@export var glide_min_fall_speed : float = -1.5

## Glide falling speed
@export var glide_fall_speed : float = -2.0

## Glide forward speed
@export var glide_forward_speed : float = 12.0

## Slew rate to transition to gliding
@export var horizontal_slew_rate : float = 1.0

## Slew rate to transition to gliding
@export var vertical_slew_rate : float = 2.0

## glide rotate with roll angle
@export var turn_with_roll : bool = false

## Smooth turn speed in radians per second
@export var roll_turn_speed : float = 1

## Add vertical impulse by flapping controllers
@export var wings_impulse : bool = false

## Minimum velocity for flapping
@export var flap_min_speed : float = 0.3

## Flapping force multiplier
@export var wings_force : float = 1.0

## Minimum distance from controllers to ARVRCamera to rearm flaps.
## if set to 0, you need to reach head level with hands to rearm flaps
@export var rearm_distance_offset : float = 0.2


## Flap activated (when both controllers are near the ARVRCamera height)
var flap_armed : bool = false

## Last controllers position to calculate flapping velocity
var last_local_left_position : Vector3
var last_local_right_position : Vector3

# True if the controller positions are valid
var _has_controller_positions : bool = false


# Left controller
@onready var _left_controller := XRHelpers.get_left_controller(self)

# Right controller
@onready var _right_controller := XRHelpers.get_right_controller(self)

# ARVRCamera
@onready var _camera_node := XRHelpers.get_xr_camera(self)


# Add support for is_xr_class on XRTools classes
func is_xr_class(xr_name:  String) -> bool:
	return xr_name == "XRToolsMovementGlide" or super(xr_name)


func physics_movement(delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Skip if disabled or either controller is off
	if disabled or !enabled or \
		!_left_controller.get_is_active() or \
		!_right_controller.get_is_active():
		_set_gliding(false)
		return

	# If on the ground, then not gliding
	if player_body.on_ground:
		_set_gliding(false)
		return

	# Get the controller left and right global horizontal positions
	var left_position := _left_controller.global_transform.origin
	var right_position := _right_controller.global_transform.origin

	# Set default wings impulse to zero
	var wings_impulse_velocity := 0.0

	# If wings impulse is active, calculate flapping impulse
	if wings_impulse:
		# Check controllers position relative to head
		var cam_local_y := _camera_node.position.y
		var left_hand_over_head = cam_local_y < _left_controller.position.y + rearm_distance_offset
		var right_hand_over_head = cam_local_y < _right_controller.position.y + rearm_distance_offset
		if left_hand_over_head && right_hand_over_head:
			flap_armed = true

		if flap_armed:
			# Get controller local positions
			var local_left_position := _left_controller.position
			var local_right_position := _right_controller.position

			# Store last frame controller positions for the first step
			if not _has_controller_positions:
				_has_controller_positions = true
				last_local_left_position = local_left_position
				last_local_right_position = local_right_position

			# Calculate controllers velocity only when flapping downwards
			var left_wing_velocity = 0.0
			var right_wing_velocity = 0.0
			if local_left_position.y < last_local_left_position.y:
				left_wing_velocity = local_left_position.distance_to(last_local_left_position) / delta
			if local_right_position.y < last_local_right_position.y:
				right_wing_velocity = local_right_position.distance_to(last_local_right_position) / delta

			# Calculate wings impulse
			if left_wing_velocity > flap_min_speed && right_wing_velocity > flap_min_speed:
				wings_impulse_velocity = (left_wing_velocity + right_wing_velocity) / 2
				wings_impulse_velocity = wings_impulse_velocity * wings_force * delta * 50
				emit_signal("player_flapped")
				flap_armed = false

			# Store controller position for next frame
			last_local_left_position = local_left_position
			last_local_right_position = local_right_position

	# Calculate global left to right controller vector
	var left_to_right := right_position - left_position

	if turn_with_roll:
		var angle = -left_to_right.dot(player_body.up_player)
		player_body.rotate_player(roll_turn_speed * delta * angle)

	# If not falling, then not gliding
	var vertical_velocity := player_body.velocity.dot(player_body.up_gravity)
	vertical_velocity += wings_impulse_velocity
	if vertical_velocity >= glide_min_fall_speed && wings_impulse_velocity == 0.0:
		_set_gliding(false)
		return

	# Set gliding based on hand separation
	var separation := left_to_right.length() / XRServer.world_scale
	_set_gliding(separation >= glide_detect_distance)

	# Skip if not gliding
	if !is_active:
		return

	# Lerp the vertical velocity to glide_fall_speed
	vertical_velocity = lerp(vertical_velocity, glide_fall_speed, vertical_slew_rate * delta)

	# Lerp the horizontal velocity towards forward_speed
	var horizontal_velocity := player_body.velocity.slide(player_body.up_gravity)
	var dir_forward := left_to_right \
			.rotated(player_body.up_gravity, PI/2) \
			.slide(player_body.up_gravity) \
			.normalized()
	var forward_velocity := dir_forward * glide_forward_speed
	horizontal_velocity = horizontal_velocity.lerp(forward_velocity, horizontal_slew_rate * delta)

	# Perform the glide
	var glide_velocity := horizontal_velocity + vertical_velocity * player_body.up_gravity
	player_body.velocity = player_body.move_player(glide_velocity)

	# Report exclusive motion performed (to bypass gravity)
	return true


# Set the gliding state and fire any signals
func _set_gliding(active: bool) -> void:
	# Skip if no change
	if active == is_active:
		return

	# Update the is_gliding flag
	is_active = active

	# Report transition
	if is_active:
		emit_signal("player_glide_start")
	else:
		emit_signal("player_glide_end")


# This method verifies the movement provider has a valid configuration.
func _get_configuration_warnings() -> PackedStringArray:
	var warnings := super()

	# Verify the left controller
	if !XRHelpers.get_left_controller(self):
		warnings.append("Unable to find left XRController3D node")

	# Verify the right controller
	if !XRHelpers.get_right_controller(self):
		warnings.append("Unable to find right XRController3D node")

	# Check glide parameters
	if glide_min_fall_speed > 0:
		warnings.append("Glide minimum fall speed must be zero or less")
	if glide_fall_speed > 0:
		warnings.append("Glide fall speed must be zero or less")
	if glide_min_fall_speed < glide_fall_speed:
		warnings.append("Glide fall speed must be faster than minimum fall speed")

	# Return warnings
	return warnings
