class_name XRToolsTeleporterEvent

## Types of pointer events
enum Type {
	## Teleporter activated
	ACTIVATED, 				# 0

	## Teleporter beam hit a suitable target
	ENTERED, 				# 1

	## Teleporter beam moved inside a suitable target
	MOVED, 					# 2

	## Teleporter beam left a suitable target
	EXITED, 				# 3

	## Teleporter's ability to perform teleportation changed
	CAN_TELEPORT_CHANGED, 	# 4

	## Player got teleportet to the teleporter's target location
	TELEPORTED, 			# 5

	## Teleporter deactivated
	DEACTIVATED 			# 6
}

## Type of teleporter event
var event_type : Type

## Teleporter generating event
var teleporter : Node3D

## Teleporter activated
var is_teleporting : bool

## Teleporter's ability to perform teleportation
var can_teleport : bool

## Current teleporter target
var target : Node3D

## Teleporter target position
var position : Vector3

## Last target position
var last_position : Vector3


## Initialize a new instance of the XRToolsPointerEvent class
func _init(
		p_event_type : Type,
		p_teleporter : Node3D,
		p_is_teleporting : bool,
		p_can_teleport : bool,
		p_target : Node3D,
		p_position : Vector3,
		p_last_position : Vector3) -> void:
	event_type = p_event_type
	teleporter = p_teleporter
	is_teleporting = p_is_teleporting
	can_teleport = p_can_teleport
	target = p_target
	position = p_position
	last_position = p_last_position


## Report teleporter activated event
static func activated(
		teleporter : Node3D,
		can_teleport : bool,
		target : Node3D,
		at : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.ACTIVATED,
			teleporter,
			true,
			can_teleport,
			target,
			at,
			at
		)
	)

## Report teleporter beam entered target event
static func entered(
		teleporter : Node3D,
		is_teleporting : bool,
		can_teleport : bool,
		target : Node3D,
		at : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.ENTERED,
			teleporter,
			is_teleporting,
			can_teleport,
			target,
			at,
			at
		)
	)


## Report teleporter beam moved inside target event
static func moved(
		teleporter : Node3D,
		is_teleporting : bool,
		can_teleport : bool,
		target : Node3D,
		to : Vector3,
		from : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.MOVED,
			teleporter,
			is_teleporting,
			can_teleport,
			target,
			to,
			from
		)
	)


## Report teleporter beam entered target event
static func exited(
		teleporter : Node3D,
		is_teleporting : bool,
		can_teleport : bool,
		target : Node3D,
		last : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.EXITED,
			teleporter,
			is_teleporting,
			can_teleport,
			target,
			last,
			last
		)
	)


## Report teleportation event
static func can_teleport_changed(
		teleporter : Node3D,
		is_teleporting : bool,
		can_teleport : bool,
		target : Node3D,
		position : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.CAN_TELEPORT_CHANGED,
			teleporter,
			is_teleporting,
			can_teleport,
			target,
			position,
			position
		)
	)


## Report teleportation event
static func teleported(
		teleporter : Node3D,
		is_teleporting : bool,
		can_teleport : bool,
		target : Node3D,
		position : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.TELEPORTED,
			teleporter,
			is_teleporting,
			can_teleport,
			target,
			position,
			position
		)
	)


## Report teleporter deactivated event
static func deactivated(
		teleporter : Node3D,
		can_teleport : bool,
		target : Node3D,
		at : Vector3) -> void:
	report(
		XRToolsTeleporterEvent.new(
			Type.DEACTIVATED,
			teleporter,
			false,
			can_teleport,
			target,
			at,
			at
		)
	)


## Report a pointer event
static func report(event : XRToolsTeleporterEvent) -> void:
	# Fire event on pointer
	if is_instance_valid(event.teleporter):
		if event.teleporter.has_signal("teleporter_event"):
			event.teleporter.emit_signal("teleporter_event", event)

	# Fire event/method on the target if it's valid
	if is_instance_valid(event.target):
		if event.target.has_signal("teleporter_event"):
			event.target.emit_signal("teleporter_event", event)
		elif event.target.has_method("teleporter_event"):
			event.target.pointer_event(event)
