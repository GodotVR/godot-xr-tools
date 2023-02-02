tool
class_name XRToolsMovementFootstep
extends XRToolsMovementProvider

## Movement provider order
export var order : int = 1001

# on ground
var ground_only : bool = false
# audio holder path
var audio : XRToolsSurfaceAudio
# last surface: the last surface the player was standing on
var on_default : bool = false
var on_fabric : bool = false
var on_glass : bool = false
var on_grass : bool = false
var on_leafes : bool = false
var on_metal : bool = false
var on_mud : bool = false
var on_plastic : bool = false
var on_puddle : bool = false
var on_rubber : bool = false
var on_sand : bool = false
var on_silk : bool = false
var on_snow : bool = false
var on_stone : bool = false
var on_tile : bool = false
var on_water : bool = false
var on_wood : bool = false
# step time and rate
var step_rate = 0.5
var step_time = 0.0

# Last on_ground state of the player
var _old_on_ground := true

# Previous velocity
var _previous_velocity : Vector3 = Vector3.ZERO
var control_velocity := Vector3.ZERO
## FootstepHolder - contains footstep audio
onready var footstep_holder := XRToolsFootstepHolder.find_instance(self)
## PlayerBody - Player Physics Body Script
onready var player_body := XRToolsPlayerBody.find_instance(self)
# Some value indicating the player wants to walk at a moderate speed
const WALK_SOUND_THRESHOLD := 0.3
# Add support for is_class on XRTools classes
func is_class(name : String) -> bool:
	return name == "XRToolsMovementFootstep" or .is_class(name)

func _ready():
	# Set as always active
	is_active = true
	player_body.connect("player_jumped", self, "_on_player_jumped")

func physics_movement(_delta: float, player_body: XRToolsPlayerBody, disabled: bool):
	# Detect landing on ground
	if not _old_on_ground and player_body.on_ground:
		if on_default:
			footstep_holder.default.play()
		if on_fabric:
			footstep_holder.fabric.play()
		if on_glass:
			footstep_holder.glass.play()
		if on_grass:
			footstep_holder.grass.play()
		if on_leafes:
			footstep_holder.leafes.play()
		if on_metal:
			footstep_holder.metal.play()
		if on_mud:
			footstep_holder.mud.play()
		if on_plastic:
			footstep_holder.plastic.play()
		if on_puddle:
			footstep_holder.puddle.play()
		if on_rubber:
			footstep_holder.rubber.play()
		if on_sand:
			footstep_holder.sand.play()
		if on_silk:
			footstep_holder.silk.play()
		if on_snow:
			footstep_holder.snow.play()
		if on_stone:
			footstep_holder.stone.play()
		if on_tile:
			footstep_holder.tile.play()
		if on_water:
			footstep_holder.water.play()
		if on_wood:
			footstep_holder.wood.play()
	# Update the old on_ground state
	_old_on_ground = player_body.on_ground
	# Count down the step timer, and skip if silenced
	step_time = max(0, step_time - _delta)
	if step_time > 0:
		return
	# Skip if the player wants footsteps on the ground, and the player isn't on the ground
	if ground_only and not player_body.on_ground:
		return
	# Play walking sounds if the player is trying to walk
	if player_body.ground_control_velocity.length() > WALK_SOUND_THRESHOLD:
		# Play the step sound and set the step delay timer
		step_time = step_rate
		if player_body.ground_node.get_node_or_null("SurfaceAudio") != null:
			audio = player_body.ground_node.get_node_or_null("SurfaceAudio")
			if audio.current_surface == audio.STATE.DEFAULT:
				footstep_holder.default.play()
				on_default = true
			else:
				on_default = false
			if audio.current_surface == audio.STATE.FABRIC:
				footstep_holder.fabric.play()
				on_fabric = true
			else:
				on_fabric = false
			if audio.current_surface == audio.STATE.GLASS:
				footstep_holder.glass.play()
				on_glass = true
			else:
				on_glass = false
			if audio.current_surface == audio.STATE.GRASS:
				footstep_holder.grass.play()
				on_grass = true
			else:
				on_grass = false
			if audio.current_surface == audio.STATE.LEAFES:
				footstep_holder.leafes.play()
				on_leafes = true
			else:
				on_leafes = false
			if audio.current_surface == audio.STATE.METAL:
				footstep_holder.metal.play()
				on_metal = true
			else:
				on_metal = false
			if audio.current_surface == audio.STATE.MUD:
				footstep_holder.mud.play()
				on_mud = true
			else:
				on_mud = false
			if audio.current_surface == audio.STATE.PLASTIC:
				footstep_holder.plastic.play()
				on_plastic = true
			else:
				on_plastic = false
			if audio.current_surface == audio.STATE.PUDDLE:
				footstep_holder.puddle.play()
				on_puddle = true
			else:
				on_puddle = false
			if audio.current_surface == audio.STATE.RUBBER:
				footstep_holder.rubber.play()
				on_rubber = true
			else:
				on_rubber = false
			if audio.current_surface == audio.STATE.SAND:
				footstep_holder.sand.play()
				on_sand = true
			else:
				on_sand = false
			if audio.current_surface == audio.STATE.SILK:
				footstep_holder.silk.play()
				on_silk = true
			else:
				on_silk = false
			if audio.current_surface == audio.STATE.SNOW:
				footstep_holder.snow.play()
				on_snow = true
			else:
				on_snow = false
			if audio.current_surface == audio.STATE.STONE:
				footstep_holder.stone.play()
				on_stone = true
			else:
				on_stone = false
			if audio.current_surface == audio.STATE.TILE:
				footstep_holder.tile.play()
				on_tile = true
			else:
				on_tile = false
			if audio.current_surface == audio.STATE.WATER:
				footstep_holder.water.play()
				on_water = true
			else:
				on_water = false
			if audio.current_surface == audio.STATE.WOOD:
				footstep_holder.wood.play()
				on_wood = true
			else:
				on_water = false
func _on_player_jumped():
	if on_default:
		footstep_holder.default.play()
	if on_fabric:
		footstep_holder.fabric.play()
	if on_glass:
		footstep_holder.glass.play()
	if on_grass:
		footstep_holder.grass.play()
	if on_leafes:
		footstep_holder.leafes.play()
	if on_metal:
		footstep_holder.metal.play()
	if on_mud:
		footstep_holder.mud.play()
	if on_plastic:
		footstep_holder.plastic.play()
	if on_puddle:
		footstep_holder.puddle.play()
	if on_rubber:
		footstep_holder.rubber.play()
	if on_sand:
		footstep_holder.sand.play()
	if on_silk:
		footstep_holder.silk.play()
	if on_snow:
		footstep_holder.snow.play()
	if on_stone:
		footstep_holder.stone.play()
	if on_tile:
		footstep_holder.tile.play()
	if on_water:
		footstep_holder.water.play()
	if on_wood:
		footstep_holder.wood.play()
## Find an [XRToolsMovementFootstep] node.
##
## This function searches from the specified node for an [XRToolsMovementFootstep]
## assuming the node is a sibling of the body under an [ARVROrigin].
static func find_instance(node: Node) -> XRToolsMovementFootstep:
	return XRTools.find_child(
		ARVRHelpers.get_arvr_origin(node),
		"*",
		"XRToolsMovementFootstep") as XRToolsMovementFootstep
