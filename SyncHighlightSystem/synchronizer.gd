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
var _highlighter := Highlighter.new()

## The default settings
var mode: MODE = MODE.PLAYBACK
var duration_setting: DURATION_SETTING = DURATION_SETTING.AUTOMATIC

## Audio positions of each figure calculated automatically (before each playback)
var auto_audio_pos := []
## Audio positions for each pageturn, calculated automatically (before each playback) based on auto_audio_pos
var auto_pageturn_pos := []
## Audio positions of each figure set manually with Manual Setting
var manual_audio_pos := []
## Audio positions for each pageturn, calculated automatically (before each playback) based on manual_audio_pos
var manual_pageturn_pos := []
## Holds the amount of figures that must be highlighted. Used to check if all figures have a duration associated to them
var total_figures_amount := 0
## How early the page should turn. The page will turn a 1/early_pageturn into the last figure of the page
@export var early_pageturn := 3

## Holds the index of the next position of the list compared to the one last processed
var _next_pos_i := 0
var _next_pageturn_pos_i := 0
## Length of each beat in seconds. Used as base measure to each rhythmic figure, and is calculated based on the chosen track_bpm
var beat_length: float

## Holds how long the first value in _audio_positions should be in Automatic mode
@export var first_highlight_delay := 0.0
## Track speed in beats per minute
@export var track_bpm := 120:
	set(value):
		track_bpm = value
		# Update beat_length accordingly
		beat_length = 60.0 / float(track_bpm)

## Holds the path to the audio file. Setter calls the function that loads the audio itself and feeds it to the audio_stream_player
@onready var audio_path: String:
	set(value):
		audio_path = value
		set_audio(value)
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var correct_audio_loading: AcceptDialog = $CorrectAudioLoading
@onready var incorrect_audio_loading: AcceptDialog = $IncorrectAudioLoading


## Synchronizer should not be working on startup
func _ready() -> void:
	set_process(false)


func _process(_delta: float) -> void:
	# We find where we are at in the audio as often as we can
	var time: float = _get_time()
	
	# Recording logic:
	if mode == MODE.RECORDING:
		# Every time the user taps, we save the moment of the audio we are in, and move on to the next figure.
		if Input.is_action_just_pressed("tap"):
			# In case the next figure is in the next page, turn page immediately
			if _highlighter.pageturn_coming():
				if _highlighter.repeat_exists():
					page_changed.emit(_highlighter.start_rep.x)
				else:
					page_changed.emit(_highlighter.current_page + 1)
			# Add position of tap to the positions array
			manual_audio_pos.append(time)
			_highlighter.next()
	
	# Playback Logic:
	else:
		# The below code serves to associate the correct audio and pageturn positions according to the current duration setting
		var audio_positions: Array
		var pageturn_positions: Array
		if duration_setting == DURATION_SETTING.MANUAL:
			audio_positions = manual_audio_pos
			pageturn_positions = manual_pageturn_pos
		else:
			audio_positions = auto_audio_pos
			pageturn_positions = auto_pageturn_pos
		
		# Every time we reach the next audio position in the array, it is time to highlight the next figure, and move on to waiting for the next in the _audio_positions array
		if time >= audio_positions[_next_pos_i]:
			_highlighter.next()
			_next_pos_i += 1
		
		# Pageturn logic, similar to the highlighting logic
		if not pageturn_positions.is_empty():
			if time >= pageturn_positions[_next_pageturn_pos_i]:
				# We must check if we reached a pageturn due to a repetition or to reaching the end of a page. In case of a repetition, turn back to the page that has the start_rep measure
				if _highlighter.repeat_exists():
					page_changed.emit(_highlighter.start_rep.x)
				# Otherwise, just turn to the next page
				else:
					page_changed.emit(_highlighter.current_page + 1)
				# Makes sure it does not go over the number of pageturns saved
				_next_pageturn_pos_i = min(_next_pageturn_pos_i + 1, len(pageturn_positions) - 1)


## Loads the audio, giving feedback to the user about the result
func set_audio(path: String) -> void:
	var audio: AudioStreamMP3 = LoadAudio.load_mp3(path)
	if not audio:
		incorrect_audio_loading.show()
		return
	else:
		audio_stream_player.stream = audio
		correct_audio_loading.show()


## Starts the Synchronizer in Recording mode (listening to input)
func start_recording(staff: Staff) -> void:
	# We want a fresh Array to input audio positions in. This way, even the first highlight delay is set manually.
	manual_audio_pos.clear()
	# A small setup must be performed. See function implementation for details
	_setup(staff)
	mode = MODE.RECORDING
	_start_audio()
	set_process(true)


## Starts the Synchronizer in Playback mode (just plays back using the recorded values)
func start_playback(staff: Staff) -> void:

	## If the duration was set manually, _audio_positions is ready to go. However, if that is not the case, the positions must first be calculated.
	if duration_setting == DURATION_SETTING.AUTOMATIC:
		# The position just played, in the beginning, is the position where the first figure should be highlighted
		var last_pos = first_highlight_delay
		# The starting point of _audio_positions should be only that initial pos
		auto_audio_pos = [last_pos]
		auto_pageturn_pos.clear()

		# A new Highlighter is created and setup, to avoid manually resetting all variables and avoid missing some.
		var temp_highlighter = Highlighter.new()
		temp_highlighter.setup(staff)
		
		# Where the actual duration setting takes place. Figures are processed (and their positions stored) until highlighter finds the end of the score (at which point, it returns null instead of a figure). Highlighter is only used here as a means to loop over figures in accurate fashion, not to actually visually highlight figures.
		while true:
			var figure = temp_highlighter.next()
			if figure:
				# Pages should turn a third of the duration into the last note before the end of the page
				if temp_highlighter.pageturn_coming():
					auto_pageturn_pos.append(last_pos + (figure.duration * beat_length / early_pageturn))
				
				# Each time a figure is "highlighted", this actually calculates the audio position the NEXT figure should be in. We do this by taking the position of the currently highlighted figure (remember, last_pos is the previously appended pos, aka the current figure's pos) and we add how long the current figure lasts. This gives us the point where highlighter, during playback, should move on and highlight the next figure.
				auto_audio_pos.append(last_pos + (figure.duration * beat_length))
				# last_pos is updated for the next iteration of the loop
				last_pos = auto_audio_pos[-1]
			# Break when no figure is returned
			else:
				break
	
	# If the durations were set manually, the only thing needed to calculate are the pageturns
	else:
		manual_pageturn_pos.clear()
		total_figures_amount = 0
		
		# A new Highlighter is created and setup, to avoid manually resetting all variables and avoid missing some
		var temp_highlighter = Highlighter.new()
		temp_highlighter.setup(staff)
		
		
		for pos in len(manual_audio_pos):
			var figure = temp_highlighter.next()
			if figure:
				total_figures_amount += 1
				if temp_highlighter.pageturn_coming():
					var current_pos: float = manual_audio_pos[pos]
					var next_pos: float = manual_audio_pos[pos + 1]
					manual_pageturn_pos.append(current_pos + ((next_pos - current_pos) / early_pageturn))
			# Break when no figure is returned
			else:
				break
		
		if len(manual_audio_pos) - 1 != total_figures_amount:
			temp_highlighter.clear_highlight()
			return
	
	_setup(staff)
	mode = MODE.PLAYBACK
	_start_audio()
	set_process(true)


## Stops the Synchronizer.
func stop() -> void:
	set_process(false)
	audio_stream_player.stop()
	# Makes sure there are no visual leftovers.
	_highlighter.clear_highlight()


func get_saved_vars() -> Dictionary:
	var saved_positions := {
		"auto_audio_pos": auto_audio_pos,
		"manual_audio_pos": manual_audio_pos,
		"auto_pageturn_pos": auto_pageturn_pos,
		"manual_pageturn_pos": manual_pageturn_pos,
		"first_highlight_delay": first_highlight_delay,
		"track_bpm": track_bpm,
		"audio_path": audio_path
	}
	return saved_positions


func load_saved_vars(saved_vars: Dictionary) -> void:
	auto_audio_pos = saved_vars.auto_audio_pos
	manual_audio_pos = saved_vars.manual_audio_pos
	auto_pageturn_pos = saved_vars.auto_pageturn_pos
	first_highlight_delay = saved_vars.first_highlight_delay
	track_bpm = saved_vars.track_bpm
	audio_path = saved_vars.audio_path


## Setup needed for a fresh start
func _setup(staff: Staff) -> void:
	# Resets the variables that must be accesible at script-scope, as they are used in the _process() function. It makes sure that _audio_positions and _pageturn_positions start looping from the beginning
	_next_pos_i = 0
	_next_pageturn_pos_i = 0
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
