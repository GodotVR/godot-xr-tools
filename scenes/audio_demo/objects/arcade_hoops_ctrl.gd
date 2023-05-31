extends Node3D



## Optional audio stream to play when the player jumps on this surface
@export var start_sound : AudioStream

## Optional audio stream to play when the player lands on this surface
@export var game_over_sound : AudioStream

## Optional audio stream to play when the player lands on this surface
@export var score_sound : AudioStream

## Optional audio stream to play when the player lands on this surface
@export var voice_sound : AudioStream

@export var token: int = 0
@export var _start_count = 60

@export var start_text : String = ""
@export var game_over_text : String = ""
@export var scored_text : String= ""
## Audio streams to play when the player walks on this surface
@onready var player := $AudioStreamPlayer3D

@onready var score_label := $Score_Text
@onready var timer := $Timer
@onready var timer_label := $Timer_Text
@onready var start_button := $PlayButton/InteractableAreaButton
@onready var eject_button := $EjectButton/InteractableAreaButton
@onready var info_label := $Start_Text
@onready var zone : XRToolsSnapZone = $SnapZone
@onready var holder : Node3D = $TokenHolder
var ejected_token = preload ("res://scenes/audio_demo/objects/token.tscn")
var _count
var score
var tween

# Flag indicating when ball is inside the area
var _ball_inside := false

# Flag indicating if timer is running
var _running := false
## Signal indicating a target has been passed through
signal target_passed()
signal count_down(number)




func _ready() -> void:
	timer_label.text = str(_start_count)
	info_label.text = str(start_text)
	timer.timeout.connect(_on_start)

	start_button.button_pressed.connect(_on_game_start)

	eject_button.button_pressed.connect(_on_token_eject)
	zone.has_picked_up.connect(_on_token_insert)


func _process(delta):
	if !_running:
		zone.enabled = true
	else:
		zone.enabled = false

func _on_entrance_area_entered(_pickable):
	_ball_inside = true


func _on_entrance_area_exited(_pickable):
	_ball_inside = false


func _on_exit_area_entered(_pickable):
	if _ball_inside and _running:
		if player.playing:
				player.stop()
		if _count <= 11:
			player.stream = voice_sound
		else:
			player.stream = score_sound
		player.play()

		emit_signal("target_passed")
		score += 1
		info_label.text = str(scored_text)
		score_label.text =  str(score)

func _on_token_insert(_what : Node3D) -> void:
	token += 1
	zone.enabled = false
	tween = get_tree().create_tween()
	tween.tween_callback(_what.queue_free).set_delay(0.15)
	tween.kill


func _on_token_eject(_button) -> void:
	var token_to_eject = ejected_token.instantiate()	
	if token > 0:
		holder.add_child(token_to_eject)
		token -= 1
		zone.enabled = true


func _on_game_start(_button) -> void:
	if token > 0 and !_running:
		token -= 1
		info_label.text = str(start_text)
		_count = _start_count
		score = 0
		_running = true
		timer.start(1)
		_on_start()


func _on_start() -> void:
	emit_signal("count_down", _count)
	if _count == _start_count:
		player.stream = start_sound
		player.play()
	_count -= 1
	info_label.text = str("")
	timer_label.text =  str(_count)
	if _count < 1:
		_on_game_over()


func _on_game_over() -> void:
	if player.playing:
			player.stop()
	player.stream = game_over_sound
	player.play()
	timer.stop()
	_running = false
	info_label.text = str(game_over_text)
