class_name Synchronizer2
extends Node

signal finished
signal page_changed


enum MODE { RECORDING, PLAYBACK }
enum DURATION_SETTING { AUTOMATIC, MANUAL }

var _highlighter: Highlighter2

var mode: MODE = MODE.PLAYBACK
var duration_setting: DURATION_SETTING = DURATION_SETTING.AUTOMATIC

var _audio_positions := [0.0]
var _next_pos_i := 0

## Track speed in beats per minute
@export var _track_bpm := 60
## Length of each beat in seconds. Used as base measure to each rhythmic figure.
@onready var beat_length := 60.0 / _track_bpm

@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer


func _ready() -> void:
	set_process(false)
	
	### Test ###
	audio_stream_player.stream = load("res://AssetsAndResources/cs50 final project.wav")


func _process(_delta: float) -> void:
	var time: float = _get_time()
	
	# Recording logic:
	if mode == MODE.RECORDING:
		if Input.is_action_just_pressed("tap"):
			_audio_positions.append(time)
			_highlighter.next()
	
	# Playback Logic:
	else:
		if time >= _audio_positions[_next_pos_i]:
			_highlighter.next()
			_next_pos_i += 1


func set_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio


func start_recording(staff: Staff) -> void:
	_audio_positions.clear()
	_setup(staff)
	mode = MODE.RECORDING
	_start_audio()
	set_process(true)


func start_playback(staff: Staff) -> void:
	_setup(staff)
	# Sets up the figures' duration_time depending on the duration setting mode chosen by the user
	# In case of automatic, it just has to convert each figure's duration into duration_time
	if duration_setting == DURATION_SETTING.AUTOMATIC:
		_audio_positions = [0.0]
		var last_pos = 0.0
		var temp_highlighter = Highlighter2.new()
		temp_highlighter.setup(staff)
		while true:
			var figure = temp_highlighter.next()
			if figure:
				_audio_positions.append(last_pos + (figure.duration * beat_length))
				last_pos = _audio_positions[-1]
			else:
				break
	mode = MODE.PLAYBACK
	_start_audio()
	set_process(true)


func stop() -> void:
	set_process(false)
	audio_stream_player.stop()
	_highlighter.clear_highlight()


func _setup(staff: Staff) -> void:
	_next_pos_i = 0
	_highlighter = Highlighter2.new()
	_highlighter.setup(staff)
	_highlighter.finished.connect(_on_highlighter_finished)
	_highlighter.page_changed.connect(_on_highlighter_page_changed)


func _get_time() -> float:
	return (
		audio_stream_player.get_playback_position()
		# Godot processes audio in batches. By adding the time since the last mix, we have that into account (playback position is actually position of last mix)
		+ AudioServer.get_time_since_last_mix()
		# Time it gets for sound to reach the speakers
		- AudioServer.get_output_latency()
	)


func _start_audio() -> void:
	audio_stream_player.play()


func _start_countdown() -> void:
	await get_tree().create_timer(3).timeout
	return


func _on_highlighter_finished() -> void:
	finished.emit()


func _on_highlighter_page_changed(page: int) -> void:
	page_changed.emit(page)


func _on_manual_duration_setting_ui_enabled_disabled(enabled) -> void:
	duration_setting = DURATION_SETTING.MANUAL if enabled else DURATION_SETTING.AUTOMATIC
