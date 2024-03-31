extends Node3D

## Rate to obscure
##
## @desc:
##    This property controls the rate the fader will adjust to obscure the
##    view. Larger numeric values will obscure faster. For example a value of 3
##    will fully obscure the scene in 1/3rd of a second.
@export var obscure_rate := 3.0

## Rate to reveal
##
## @desc:
##     This property controls the rate the fader will adjust to reveal the
##     view. Larger numeric values will reveal faster. For example a value of
##     3 will fully reveal the scene in 1/3rd of a second.
@export var reveal_rate := 1.0

## Default fade if not in a fade area
##
## @desc:
##    This property sets the default fade if the player is not in a fade area
@export var default_fade := 1.0

## Layers to check
##
## @desc:
##    This property sets the layers this fade area checks for.
@export var fade_area_layers := 2 # (int, LAYERS_3D_PHYSICS)

# Current fade contribution [0..1] - used by Fader
var fade_contribution := 0.0

# World space to use for collision detection
var space : PhysicsDirectSpaceState3D = null

# Called when the node enters the scene tree for the first time.
func _ready():
	# Get the space to test collisions in
	space = get_world_3d().get_direct_space_state()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	add_to_group("fade_contributor")
	# Find all area collisions
	var collisions = PhysicsRayQueryParameters3D.new()
	collisions.from = global_transform.origin
	#collisions.to = 32
	collisions.exclude = []

	collisions.collision_mask = 2
	var result = space.intersect_ray(collisions)
	if result:
		return false
		return true 
	# Calculate the fade
	var fade = default_fade
	var fade_priority = -1;
	for c in collisions:
		var area = c["collider"]
		if area.is_in_group("fade_area"):
			if area.priority > fade_priority:
				fade = area.fade_level
				fade_priority = area.priority;
	
	# Adjust the contribution
	if fade_contribution < fade:
		# Fade in to target (obscure)
		fade_contribution = min(fade_contribution + obscure_rate * delta, fade)
	elif fade_contribution > fade:
		# Fade out to target (reveal)
		fade_contribution = max(fade_contribution - reveal_rate * delta, fade)
