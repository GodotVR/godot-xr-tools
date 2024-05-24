extends Node3D


# Damaging flag
var _damaging : bool = false

# Damage cycle
var _damage_cycle : float = 0.0


func _exit_tree() -> void:
	_stop_damage()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta : float) -> void:
	# Disable processing if not doing damage
	if not _damaging:
		set_process(false)
		return

	# Advance the cycle counter
	_damage_cycle = fmod(_damage_cycle + delta, 1.0)

	# Generate the cycling alpha value
	var alpha := cos(_damage_cycle * PI * 2)
	alpha = remap(alpha, 1.0, -1.0, 0.0, 0.5)

	# Fade cycling to red tint
	var color := Color(1.0, 0.0, 0.0, alpha)
	XRToolsFade.set_fade(self, color)


func _on_area_3d_body_entered(body : Node3D):
	# Skip if not the player body
	if not body.is_in_group("player_body"):
		return

	_start_damange()


func _on_area_3d_body_exited(body : Node3D):
	# Skip if not the player body
	if not body.is_in_group("player_body"):
		return

	_stop_damage()


func _start_damange() -> void:
	# Set damaging
	_damaging = true
	_damage_cycle = 0.0
	set_process(true)


func _stop_damage() -> void:
	# Cancel any current damaging effect
	_damaging = false
	XRToolsFade.set_fade(self, Color.TRANSPARENT)
