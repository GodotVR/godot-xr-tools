extends AudioStreamPlayer3D

var prev_pitch = 1.0

func play(start_position = 0.0):
	randomize()
	pitch_scale = rand_range(0.8, 1.2)
	while abs(pitch_scale - prev_pitch) < .1:
		randomize()
		pitch_scale = rand_range(0.8, 1.2)
	prev_pitch = pitch_scale
	.play(start_position)
