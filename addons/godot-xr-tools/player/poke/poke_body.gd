@tool
extends XRToolsForceBody


## Emitted when we start to contact an object
signal body_contact_start(node: Node3D)

## Emitted when we end contact with an object
signal body_contact_end(node:Node3D)


## Distance at which we teleport our poke body
@export_custom(PROPERTY_HINT_NONE, "suffix:m") var teleport_distance := 0.1


# Node currently in contact with
var _contact: Node3D = null

# Target XRToolsPoke
@onready var _target: XRToolsPoke = get_parent()


func _ready() -> void:
	# Do not initialise if in the editor
	if Engine.is_editor_hint():
		# In editor, show it at its start location
		top_level = false
		transform = Transform3D()
		return

	# In runtime, we control the position
	top_level = true

	# Connect to player body signals (if applicable)
	var player_body := XRToolsPlayerBody.find_instance(self)
	if player_body:
		player_body.player_moved.connect(_on_player_moved)
		player_body.player_teleported.connect(_on_player_teleported)


# Tries moving to the parent Poke node
func _physics_process(_delta: float) -> void:
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


func _validate_property(property: Dictionary) -> void:
	if property.name == "top_level":
		property.usage = PROPERTY_USAGE_NONE


## Adds support for [method is_xr_class] on XRTools classes
func is_xr_class(xr_name: String) -> bool:
	return xr_name == "XRToolsPokeBody" or super(xr_name)


# Attempts to move our poke if our player moved
func _on_player_moved(delta_transform: Transform3D) -> void:
	var target: Transform3D = delta_transform * global_transform

	# Rotate
	global_basis = target.basis

	# And attempt to move (we'll detect contact change in physics process).
	move_and_slide(target.origin - global_position)

	force_update_transform()


# Moves the poke if the player teleports
func _on_player_teleported(delta_transform: Transform3D) -> void:
	global_transform = delta_transform * global_transform
	force_update_transform()
