class_name Synchronizer
extends Node

## Bubble-up signals from Highlighter
signal finished
signal page_changed(page_i: int)

## Lists the two modes the synchronizer can work in: RECORDING plays the audion and listens to key presses, saving at which point in the audio the key was pressed in an array. It can only be triggered when Manual Duration Setting is on. PLAYBACK plays the audio while highlighting the figures by itself, using the durations that were automatically calculated or manually set by the user.
enum MODE { RECORDING, PLAYBACK }
## Automatic: Synchronizer calculates on playback button pressed the duration of each figure based on the bpm set by the user
## Manual: User sets the duration of each figure manually
enum DURATION_SETTING { AUTOMATIC, MANUAL }

## This is where the highlighter used for playbacks is stored
var _highlighter: Highlighter

## The default settings
var mode: MODE = MODE.PLAYBACK
var duration_setting: DURATION_SETTING = DURATION_SETTING.AUTOMATIC

## The array where the audio positions of each figure are saved. It can be filled automatically right before playback starts (when in AUTOMATIC Duration Setting) or manually using RECORDING (in MANUAL Duration Setting). 
var _audio_positions := [0.0]
## Holds the index of the next position of the list compared to the one last processed
var _next_pos_i := 0

## Holds how long the first value in _audio_positions should be in Automatic mode
@export var first_highlight_delay := 0.0
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
	# We find where we are at in the audio as often as we can
	var time: float = _get_time()
	
	# Recording logic:
	if mode == MODE.RECORDING:
		# Every time the user taps, we save the moment of the audio we are in, and move on to the next figure.
		if Input.is_action_just_pressed("tap"):
			_audio_positions.append(time)
			_highlighter.next()
	
	# Playback Logic:
	else:
		# Every time we reach the next audio position in the array, it is time to highlight the next figure, and move on to waiting for the next in the _audio_positions array
		if time >= _audio_positions[_next_pos_i]:
			_highlighter.next()
			_next_pos_i += 1


func set_audio(audio: AudioStream) -> void:
	audio_stream_player.stream = audio


## Starts the Synchronizer in Recording mode (listening to input)
func start_recording(staff: Staff) -> void:
	# We want a fresh Array to input audio positions in. This way, even the first highlight delay is set manually.
	_audio_positions.clear()
	# A small setup must be performed. See function implementation for details
	_setup(staff)
	mode = MODE.RECORDING
	_start_audio()
	set_process(true)


## Starts the Synchronizer in Playback mode (just plays back using the recorded values)
func start_playback(staff: Staff) -> void:
	_setup(staff)
	## If the duration was set manually, _audio_positions is ready to go. However, if that is not the case, the positions must first be calculated.
	if duration_setting == DURATION_SETTING.AUTOMATIC:
		# The position just played, in the beginning, is the position where the first figure should be highlighted
		var last_pos = first_highlight_delay
		# The starting point of _audio_positions should be only that initial pos
		_audio_positions = [last_pos]
		# A new Highlighter is created and setup, to avoid manually resetting all variables and avoid missing some
		var temp_highlighter = Highlighter.new()
		temp_highlighter.setup(staff)
		
		# Where the actual duration setting takes place. Figures are processed (and their positions stored) until highlighter finds the end of the score (at which point, it returns null instead of a figure). Highlighter is only used here as a means to loop over figures in accurate fashion, not to actually visually highlight figures.
		while true:
			var figure = temp_highlighter.next()
			if figure:
				# Each time a figure is "highlighted", this actually calculates the audio position the NEXT figure should be in. We do this by taking the position of the currently highlighted figure (remember, last_pos is the previously appended pos, aka the current figure's pos) and we add how long the current figure lasts. This gives us the point where highlighter, during playback, should move on and highlight the next figure.
				_audio_positions.append(last_pos + (figure.duration * beat_length))
				# last_pos is updated for the next iteration of the loop
				last_pos = _audio_positions[-1]
			# Break when no figure is returned
			else:
				break
	mode = MODE.PLAYBACK
	_start_audio()
	set_process(true)


## Stops the Synchronizer.
func stop() -> void:
	set_process(false)
	audio_stream_player.stop()
	# Makes sure there are no visual leftovers.
	_highlighter.clear_highlight()


## Setup needed for a fresh start
func _setup(staff: Staff) -> void:
	# Resets the only variable that must be accesible at script-scope, as it is used in the _process() function. It makes sure that _audio_positions starts looping from the beginning
	_next_pos_i = 0
	# Creates and sets up the Highlighter instance that will be used for playback
	_highlighter = Highlighter.new()
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


## Used in case one needs an initial delay. (Behavior code should go here)
func _start_countdown() -> void:
	await get_tree().create_timer(3).timeout
	return


## Bubble-up callbacks (from highlighter to EditorWindow)
func _on_highlighter_finished() -> void:
	finished.emit()


func _on_highlighter_page_changed(page: int) -> void:
	page_changed.emit(page)


## Callback that updates the duration setting mode according to what is chosen in the respective UI
func _on_manual_duration_setting_ui_enabled_disabled(enabled) -> void:
	duration_setting = DURATION_SETTING.MANUAL if enabled else DURATION_SETTING.AUTOMATIC
