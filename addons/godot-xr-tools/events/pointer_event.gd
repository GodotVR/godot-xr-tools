class_name XRToolsPointerEvent

## Types of pointer events
enum Type {
	## Pointer entered target
	ENTERED,

	## Pointer exited target
	EXITED,

	## Pointer pressed target
	PRESSED,

	## Pointer released target
	RELEASED,

	## Pointer moved on target
	MOVED
}

## Type of pointer event
var event_type : Type

## Pointer generating event
var pointer : Node3D

## Target of pointer
var target : Node3D

## Point position
var position : Vector3

## Last point position
var last_position : Vector3


## Initialize a new instance of the XRToolsPointerEvent class
func _init(
		p_event_type : Type,
		p_pointer : Node3D,
		p_target : Node3D,
		p_position : Vector3,
		p_last_position : Vector3) -> void:
	event_type = p_event_type
	pointer = p_pointer
	target = p_target
	position = p_position
	last_position = p_last_position


## Report a pointer entered event
static func entered(
		pointer : Node3D,
		target : Node3D,
		at : Vector3) -> void:
	report(
		XRToolsPointerEvent.new(
			Type.ENTERED,
			pointer,
			target,
			at,
			at))


## Report pointer moved event
static func moved(
		pointer : Node3D,
		target : Node3D,
		to : Vector3,
		from : Vector3) -> void:
	report(
		XRToolsPointerEvent.new(
			Type.MOVED,
			pointer,
			target,
			to,
			from))


## Report pointer pressed event
static func pressed(
		pointer : Node3D,
		target : Node3D,
		at : Vector3) -> void:
	report(
		XRToolsPointerEvent.new(
			Type.PRESSED,
			pointer,
			target,
			at,
			at))


## Report pointer released event
static func released(
		pointer : Node3D,
		target : Node3D,
		at : Vector3) -> void:
	report(
		XRToolsPointerEvent.new(
			Type.RELEASED,
			pointer,
			target,
			at,
			at))


## Report a pointer exited event
static func exited(
		pointer : Node3D,
		target : Node3D,
		last : Vector3) -> void:
	report(
		XRToolsPointerEvent.new(
			Type.EXITED,
			pointer,
			target,
			last,
			last))


## Report a pointer event
static func report(event : XRToolsPointerEvent) -> void:
	# Fire event on pointer
	if is_instance_valid(event.pointer):
		if event.pointer.has_signal("pointing_event"):
			event.pointer.emit_signal("pointing_event", event)

	# Fire event/method on the target if it's valid
	if is_instance_valid(event.target):
		if event.target.has_signal("pointer_event"):
			event.target.emit_signal("pointer_event", event)
		elif event.target.has_method("pointer_event"):
			event.target.pointer_event(event)
