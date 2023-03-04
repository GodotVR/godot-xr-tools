@tool
class_name XRToolsGroundPhysicsSettings
extends Resource

## Enumeration flags for which ground physics properties are enabled
enum GroundPhysicsFlags {
	## If set, this move drag value overrides the default
	MOVE_DRAG = 		0b00000001,

	## If set, this move traction value overrides the default
	MOVE_TRACTION = 	0b00000010,

	## If set, this move maximum slope value overrides the default
	MOVE_MAX_SLOPE = 	0b00000100,

	## If set, this jump maximum slope value overrides the default
	JUMP_MAX_SLOP = 	0b00001000,

	## If set, this jump velocity value overrides the default
	JUMP_VELOCITY = 	0b00010000,

	## If set, this bounciness value overrides the default
	BOUNCINESS = 		0b00100000,

	## If set, this bounce threshold value overrides the default
	BOUNCE_THRESHOLD = 	0b01000000,
}

## Flags defining which ground velocities are enabled
@export_flags("Move Drag",
	"Move Traction",
	"Move Max Slope",
	"Jump Max Slope",
	"Jump Velocity",
	"Bounciness",
	"Bounce Threshold") var flags : int = 0

## Movement drag factor
@export var move_drag : float = 5.0

## Movement traction factor
@export var move_traction : float = 30.0

## Stop sliding on slope
@export var stop_on_slope : bool = true

## Movement maximum slope
@export_range(0.0, 85.0) var move_max_slope : float = 45.0

## Jump maximum slope
@export_range(0.0, 85.0) var jump_max_slope : float = 45.0

## Jump velocity
@export var jump_velocity : float = 3.0

## Ground bounciness (0 = no bounce, 1 = full bounciness)
@export var bounciness : float = 0.0

## Bounce threshold (skip bounce if velocity less than threshold)
@export var bounce_threshold : float = 1.0


# Handle class initialization with default parameters
func _init(
	p_flags = 0,
	p_move_drag = 5.0,
	p_move_traction = 30.0,
	p_move_max_slope = 45.0,
	p_jump_max_slope = 45.0,
	p_jump_velocity = 3.0,
	p_bounciness = 0.0,
	p_bounce_threshold = 1.0):
	# Save the parameters
	flags = p_flags
	move_drag = p_move_drag
	move_traction = p_move_traction
	move_max_slope = p_move_max_slope
	jump_max_slope = p_jump_max_slope
	jump_velocity = p_jump_velocity
	bounciness = p_bounciness
	bounce_threshold = p_bounce_threshold


## Get the effective move drag value
static func get_move_drag(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.MOVE_DRAG:
		return override.move_drag

	return default.move_drag


## Get the effective move traction value
static func get_move_traction(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.MOVE_TRACTION:
		return override.move_traction

	return default.move_traction


## Get the effective move maximum slope value
static func get_move_max_slope(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.MOVE_MAX_SLOPE:
		return override.move_max_slope

	return default.move_max_slope


## Get the effective jump maximum slope value
static func get_jump_max_slope(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.JUMP_MAX_SLOP:
		return override.jump_max_slope

	return default.jump_max_slope


## Get the effective jump velocity value
static func get_jump_velocity(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.JUMP_VELOCITY:
		return override.jump_velocity

	return default.jump_velocity


## Get the effective bounciness value
static func get_bounciness(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.BOUNCINESS:
		return override.bounciness

	return default.bounciness


## Get the effective bounce threshold value
static func get_bounce_threshold(
		override: XRToolsGroundPhysicsSettings,
		default: XRToolsGroundPhysicsSettings) -> float:
	if override and override.flags & GroundPhysicsFlags.BOUNCE_THRESHOLD:
		return override.bounce_threshold

	return default.bounce_threshold
