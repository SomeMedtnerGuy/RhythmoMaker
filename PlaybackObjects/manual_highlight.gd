class_name ManualHighlight
extends Node

## Bubbling up the request from highlighter to the editor, which is the object that controlls the visibility of the staff
signal pageturn_requested
## Time from pressing start to the first key-stroke is sent to editor, which FOR NOW is the one sending this value to synchronizer
signal delay_set(delay)
## Emitted when done. This happens when highlighter finishes all the figures in the list.
signal finished()

var _highlighter: Highlighter
## Holds a value which is what I assume to be natural human delay when key-striking along with the audio (aka the time between when the beat occurs and when the key-stroke is detected). This value feels pretty good, but still subject to a little more experimentation and further testing to check if that is actually the reason.
@export var _human_press_delay := 0.05

var _currently_highlighted: Figure
## Holds the audio position in which the last key-stroke happened 
var _previous_position := 0.0

@onready var audio_stream_player := $AudioStreamPlayer


## Process should only run when play button is pressed, so it starts deactivated
func _ready() -> void:
	set_process(false)


func load_data(specs: Dictionary) -> void:
	audio_stream_player.stream = load(specs.audio)


func setup(highlighter: Highlighter) -> void:
	_highlighter = highlighter
	_highlighter.end_of_figures_reached.connect(_on_highlighter_end_of_figures_reached)
	_highlighter.pageturn_requested.connect(_on_highlighter_pageturn_requested)


func _process(_delta) -> void:
	# When the user presses the highlight key, save the length in the highlighted figure and move on to the next one.
	if Input.is_action_just_pressed("highlight_figure"):
		var playback_position: float = (
			audio_stream_player.get_playback_position()
			# Godot processes audio in batches. By adding the time since the last mix, we have that into account (playback position is actually position of last mix)
			+ AudioServer.get_time_since_last_mix()
			# Time it gets for sound to reach the speakers
			- AudioServer.get_output_latency()
			# Has the press delay into account,so the highlighting is more precise
			- _human_press_delay
		)
		# If no figure is highlighted, it means the keystroke happens when the first figure should, which means thet the time calculated is the time between play is pressed and the first figure happens (aka delay)
		if not _currently_highlighted:
			delay_set.emit(playback_position)
		else:
			# Save the duration in the highlighted figure
			_currently_highlighted.duration_time = playback_position - _previous_position
		# Now that figure is processed, the playback positiion becomes the new previous position which the next key-stroke timing must be compared to.
		_previous_position = playback_position
		# finally, highlight the next figure
		_currently_highlighted = _highlighter.highlight_next()


func update_audio(audio: AudioStreamMP3) -> void:
	audio_stream_player.stream = audio


## The next two functions start and stop the manual highlighting process.
func start(figures_list) -> void:
	_highlighter.setup(figures_list)
	audio_stream_player.play()
	set_process(true)

## This can happen either when the stop button is pressed or highlighter reaches its end. In both cases it is called by editor, because since this behavior is common to both, but in one case the behavior is triggered by the UI, it is easier to have highligher emit the signal directly to Editor (bubbled up by this node regardless) and have it connected to the same function there which calls this one.
func stop() -> void:
	set_process(false)
	audio_stream_player.stop()
	_highlighter.clear_highlight()


## Bubble-up callbacks
func _on_highlighter_end_of_figures_reached():
	finished.emit()


func _on_highlighter_pageturn_requested():
	pageturn_requested.emit()
