extends AudioStreamPlayer3D

## random_audiostream: plays the audio file with a random pitch_scale
## pitch_scale:
## "higher"/"lower"/"loudness"/"duration"/"timbre"
## randomization of the audio that is being played

## previous pitch
var prev_pitch = 1.0

## start_position = float value
func play(start_position = 0.0):
	randomize()
	## rand_range - random range for the pitch_scale
	pitch_scale = rand_range(0.8, 1.2)
	while abs(pitch_scale - prev_pitch) < .1:
		randomize()
		pitch_scale = rand_range(0.8, 1.2)
	prev_pitch = pitch_scale
	.play(start_position)
