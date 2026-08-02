@tool
class_name XRToolsGroundPhysicsSettings
extends Resource

## Enumeration flags for which ground physics properties are overriden
enum GroundPhysicsFlags {
	## Whether this move drag value overrides the default
	MOVE_DRAG = 		0b00000001,

	## Whether this move traction value overrides the default
	MOVE_TRACTION = 	0b00000010,

	## Whether this move maximum slope value overrides the default
	MOVE_MAX_SLOPE = 	0b00000100,

	## Whether this jump maximum slope value overrides the default
	JUMP_MAX_SLOP = 	0b00001000,

	## Whether this jump velocity value overrides the default
	JUMP_VELOCITY = 	0b00010000,

	## Whether this bounciness value overrides the default
	BOUNCINESS = 		0b00100000,

	## Whether this bounce threshold value overrides the default
	BOUNCE_THRESHOLD = 	0b01000000,
}


## Which ground physics factors are overriden
@export_flags(
		"Move Drag",
		"Move Traction",
		"Move Max Slope",
		"Jump Max Slope",
		"Jump Velocity",
		"Bounciness",
		"Bounce Threshold",
) var flags := 0:
	set(new_flags):
		flags = new_flags
		notify_property_list_changed()

## Override for movement drag factor
@export var move_drag := 5.0

## Override for movement traction factor
@export var move_traction := 30.0

## Override for whether to stop sliding on slopes
@export var stop_on_slope := true

## Override for maximum angle of a slope that can be climbed
@export_range(0.0, 85.0, 1.0, "degrees") var move_max_slope := 45.0

## Override for maximum angle of a slope that can be jumped on
@export_range(0.0, 85.0, 1.0, "degrees") var jump_max_slope : = 45.0

## Override for jump velocity
@export_custom(PROPERTY_HINT_NONE, "suffix:m/s") var jump_velocity := 3.0

## Override for ground bounciness (0 = no bounce, 1 = full bounciness)
@export_range(0.0, 1.0) var bounciness := 0.0

## Override for minimum velocity required to bounce
@export var bounce_threshold := 1.0


# Handles class initialisation with default parameters
func _init(
		p_flags = 0,
		p_move_drag = 5.0,
		p_move_traction = 30.0,
		p_move_max_slope = 45.0,
		p_jump_max_slope = 45.0,
		p_jump_velocity = 3.0,
		p_bounciness = 0.0,
		p_bounce_threshold = 1.0,
) -> void:
	# Save the parameters
	flags = p_flags
	move_drag = p_move_drag
	move_traction = p_move_traction
	move_max_slope = p_move_max_slope
	jump_max_slope = p_jump_max_slope
	jump_velocity = p_jump_velocity
	bounciness = p_bounciness
	bounce_threshold = p_bounce_threshold


## Gets the effective minimum velocity required to bounce
static func get_bounce_threshold(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.BOUNCE_THRESHOLD:
		return override.bounce_threshold

	return default.bounce_threshold


## Gets the effective bounciness
static func get_bounciness(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.BOUNCINESS:
		return override.bounciness

	return default.bounciness


## Gets the effective maximum angle of a slope angle that can be jumped on
static func get_jump_max_slope(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.JUMP_MAX_SLOP:
		return override.jump_max_slope

	return default.jump_max_slope


## Gets the effective jump velocity
static func get_jump_velocity(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.JUMP_VELOCITY:
		return override.jump_velocity

	return default.jump_velocity


## Gets the effective move drag
static func get_move_drag(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.MOVE_DRAG:
		return override.move_drag

	return default.move_drag


## Gets the effective maximum angle of a slope that can be moved on
static func get_move_max_slope(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.MOVE_MAX_SLOPE:
		return override.move_max_slope

	return default.move_max_slope


## Gets the effective move traction
static func get_move_traction(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings,
) -> float:
	if override and override.flags & GroundPhysicsFlags.MOVE_TRACTION:
		return override.move_traction

	return default.move_traction


func _validate_property(property: Dictionary) -> void:
	match property.name:
		"move_drag":
			if not flags & GroundPhysicsFlags.MOVE_DRAG:
				property.usage |= PROPERTY_USAGE_READ_ONLY
		"move_traction":
			if not flags & GroundPhysicsFlags.MOVE_TRACTION:
				property.usage |= PROPERTY_USAGE_READ_ONLY
		"move_max_slope":
			if not flags & GroundPhysicsFlags.MOVE_MAX_SLOPE:
				property.usage |= PROPERTY_USAGE_READ_ONLY
		"jump_max_slope":
			if not flags & GroundPhysicsFlags.JUMP_MAX_SLOP:
				property.usage |= PROPERTY_USAGE_READ_ONLY
		"jump_velocity":
			if not flags & GroundPhysicsFlags.JUMP_VELOCITY:
				property.usage |= PROPERTY_USAGE_READ_ONLY
		"bounciness":
			if not flags & GroundPhysicsFlags.BOUNCINESS:
				property.usage |= PROPERTY_USAGE_READ_ONLY
		"bounce_threshold":
			if not flags & GroundPhysicsFlags.BOUNCE_THRESHOLD:
				property.usage |= PROPERTY_USAGE_READ_ONLY
