class_name Synchronizer
extends Node

## Emitted everytime a figure is played
signal figure_played
signal pageturn_requested
signal playback_finished


var _highlighter: Highlighter

## Track speed in beats per minute
@export var _track_bpm := 120
## Initial delay in the music track
@export var initial_delay := 0.0


var _current_figure: Figure


var _elapsed_beats_until_last_figure
## Length of each beat in seconds. Used as base measure to each rhythmic figure.
@onready var beat_length := 60.0 / _track_bpm
## Time since the beginning of the track up to when the currently highlighted figure played
@onready var _elapsed_time_until_last_figure

@onready var audio_stream_player := $AudioStreamPlayer


func _ready():
	# We just want the synchronizer to start working when we press play
	set_process(false)


func save_data() -> Dictionary:
	var data := {}
	data.audio = audio_stream_player.stream
	data.initial_delay = initial_delay
	
	return data


func load_data(specs: Dictionary) -> void:
	audio_stream_player.stream = load(specs.audio)
	initial_delay = specs.initial_delay


func setup(highlighter: Highlighter) -> void:
	_highlighter = highlighter
	_highlighter.end_of_figures_reached.connect(_on_highlighter_end_of_figures_reached)
	_highlighter.pageturn_requested.connect(_on_highlighter_pageturn_requested)



func _process(_delta):
	# Accurate time elapsed since track started
	var time: float = (
		audio_stream_player.get_playback_position()
		# Godot processes audio in batches. By adding the time since the last mix, we have that into account (playback position is actually position of last mix)
		+ AudioServer.get_time_since_last_mix()
		# Time it gets for sound to reach the speakers
		- AudioServer.get_output_latency()
	)
	# Keeps track whether the current point in the track became bigger than the point when the next figure should be highlighted, and highlights it if that is the case.
	if time > (_elapsed_time_until_last_figure + (_current_figure.duration_time)):
		_elapsed_beats_until_last_figure += _current_figure.duration

		_elapsed_time_until_last_figure += _current_figure.duration_time
		
		_current_figure = _highlighter.highlight_next()


func update_audio(audio: AudioStreamMP3) -> void:
	audio_stream_player.stream = audio


## Enters playback mode. Highlights each figure in the argument rhythms_list (a reference to all figures placed in the editor) according to the beat.
func start_playback(figures_list: Array) -> void:
	_highlighter.setup(figures_list)
	# Plays the audio file
	play_track()
	# In case the user needs to have a delay before the playing mode starts (if the audio file has a certain amount of silence in the beginning), it is accounted for in this timer
	await get_tree().create_timer(initial_delay).timeout
	# Sets the current figure to the first one, highlighting it in the process (setter does that)
	# Also (re)initialize all variables (necessary to do here for when user presses play after 1st time)
	_current_figure = _highlighter.highlight_next()
	_elapsed_beats_until_last_figure = 0.0
	_elapsed_time_until_last_figure = initial_delay
	# Starts the Synchronizer loop
	set_process(true)
	


func stop_playback() -> void:
	set_process(false)
	audio_stream_player.stop()
	# Makes sure that no figure is highlighted
	_highlighter.clear_highlight()
	_current_figure = null
	_elapsed_time_until_last_figure = initial_delay


## Plays audio file
func play_track() -> void:
	var delay: float = AudioServer.get_time_since_last_mix() + AudioServer.get_output_latency()
	await get_tree().create_timer(delay).timeout
	audio_stream_player.play()


## This function does not call stop_playback() directly because the playback can be stopped in different ways, so it is better to have it be called by the object that has accessto all of those ways, aka the Editor. The emitted signal serves that purpose.
func _on_highlighter_end_of_figures_reached():
	playback_finished.emit()


func _on_highlighter_pageturn_requested():
	pageturn_requested.emit()
