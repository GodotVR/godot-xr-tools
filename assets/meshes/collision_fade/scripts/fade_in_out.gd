extends Node

## Rate to obscure
##
## @desc:
##    This property controls the rate the fader will adjust to obscure the
##    view. Larger numeric values will obscure faster. For example a value of 3
##    will fully obscure the scene in 1/3rd of a second.
@export var obscure_rate := 1.0

## Rate to reveal
##
## @desc:
##     This property controls the rate the fader will adjust to reveal the
##     view. Larger numeric values will reveal faster. For example a value of
##     3 will fully reveal the scene in 1/3rd of a second.
@export var reveal_rate := 1.0

## Initial fade contribution [0..1]
##
## @desc:
##    This property contains the initial fade level at start.
@export var initial_fade := 1.0

## Current fade target [0..1]
##
## @desc:
##    This property contains the target fade for this fade function. The 
##    'fade_contribution' will slew to this target based on the 'fade_in_rate'
##    and 'fade_out_rate' properties. The user can set this value for an initial
##    fade target at start.
@export var fade_target := 0.0

# Current fade contribution [0..1] - used by Fader
var fade_contribution := 1.0

# Called when the node enters the scene tree for the first time.
func _ready():
	add_to_group("fade_contributor")
	fade_contribution = initial_fade

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# Adjust the fade
	if fade_contribution < fade_target:
		# Fade in to target (obscure)
		fade_contribution = min(fade_contribution + obscure_rate * delta, fade_target)
	elif fade_contribution > fade_target:
		# Fade out to target (reveal)
		fade_contribution = max(fade_contribution - reveal_rate * delta, fade_target)
