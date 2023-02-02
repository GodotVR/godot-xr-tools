extends Spatial

## random_audio: gets the child and child count nodes
## randi is used to get a random child to play the audio file,
## the play() function introduced in the random_audiostream.gd is responsible for playing the actual audio file
func play():
	get_child(randi() % get_child_count()).play()
