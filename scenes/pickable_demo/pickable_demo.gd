extends DemoSceneBase

@onready var left_hand : XRToolsHand = $XROrigin3D/LeftHand/XRToolsCollisionHand/LeftHand
@onready var left_ghost_hand : XRToolsHand = $XROrigin3D/LeftHand/GhostHand
@onready var right_hand : XRToolsHand = $XROrigin3D/RightHand/XRToolsCollisionHand/RightHand
@onready var right_ghost_hand : XRToolsHand = $XROrigin3D/RightHand/GhostHand

func _process(_delta):
	# Show our ghost hands when when our visible hands aren't where our hands are...
	if left_hand and left_ghost_hand:
		var offset = left_hand.global_position - left_ghost_hand.global_position
		left_ghost_hand.visible = offset.length() > 0.01

	if right_hand and right_ghost_hand:
		var offset = right_hand.global_position - right_ghost_hand.global_position
		right_ghost_hand.visible = offset.length() > 0.01
