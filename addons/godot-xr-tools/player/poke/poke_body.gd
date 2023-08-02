@tool
extends XRToolsForceBody


## Signal called when we start to contact an object
signal body_contact_start(node)

## Signal called when we end contact with an object
signal body_contact_end(node)


## Distance at which we teleport our poke body
@export var teleport_distance : float = 0.1


# Node currently in contact with
var _contact : Node3D = null

# Target XRToolsPoke
@onready var _target : XRToolsPoke = get_parent()


# Add support for is_xr_class on XRTools classes
func is_xr_class(name : String) -> bool:
	return name == "XRToolsPokeBody" or super(name)


# Try moving to the parent Poke node
func _physics_process(_delta):
	# Do not process if in the editor
	if Engine.is_editor_hint():
		return

	# Calculate the movement to perform
	var target := _target.global_position
	var to_target := target - global_position

	# Decide whether to teleport or slide
	var old_contact := _contact
	if to_target.length() > teleport_distance:
		# Teleport to the target
		global_position = target
	else:
		# Move and slide to the target
		var collision := move_and_slide(to_target)
		_contact = collision.collider if collision else null

	# Report when we stop being in contact with the current object
	if old_contact and old_contact != _contact:
		body_contact_end.emit(old_contact)

	# Report when we start touching a new object
	if _contact and _contact != old_contact:
		body_contact_start.emit(_contact)
