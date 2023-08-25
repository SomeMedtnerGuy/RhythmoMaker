class_name Measure
extends Area2D

## Sends out the selected state, passing itself so the editor can have a reference to it
signal selected_changed(measure)

const BARLINES_SPRITESHEET := preload("res://Measure/Barlines.png")

const BARLINES_REGION := {
	Types.BARLINES.SINGLE: Vector2(0, 0),
	Types.BARLINES.DOUBLE: Vector2(40, 0),
	Types.BARLINES.END: Vector2(80, 0),
	Types.BARLINES.ENDREP: Vector2(120, 0),
	Types.BARLINES.STARTREP: Vector2(160, 0)
}

## The figure scene that is placed in each measure at the press of a figure_button
const RHYTHMIC_FIGURE = preload("res://Figure/figure.tscn")

## Amount of beats per bar (time signature, basically)
@export var beats_amount := 4.0

## Flag that keeps track if measure is selected or not
var highlighted := false:
	set(value):
		highlighted = value
		# Visual queue on the selection
		selection_rect.visible = value



var barline_type := Types.BARLINES.SINGLE:
	set(value):
		barline_type = value
		if barline:
			barline.region_rect = Rect2(BARLINES_REGION[value], Vector2(40, 190))


## Used to place the figures proportionally to the length of the measure
@onready var pathfollow2d := $Path2D/PathFollow2D
@onready var selection_rect := $SelectionRect
@onready var figures = $Figures
@onready var barline = $Barline

@onready var measure_length: float = $Path2D.curve.get_baked_length()


func save_data() -> Dictionary:
	var figures_list := []
	for figure in figures.get_children():
		figures_list.append(figure.save_data())
	var save_dict := {
		"barline_type": barline_type,
		"figures": figures_list
	}
	return save_dict


func load_figures(figures_list: Array) -> void:
	for figure_specs in figures_list:
		place_figure(figure_specs)



## Places a rhythmic figure with duration "duration" in the measure
func place_figure(figure_specs: Dictionary) -> void:
	var duration: float = figure_specs.duration
	var is_rest: bool = figure_specs.is_rest
	
	var current_duration := calculate_current_duration()
	
	# In case the added figure makes the measure too long, dont place it
	if current_duration + duration > beats_amount:
		print("Not enough space in this measure for that figure!")
		return
	
	# Dotted sixteenth is not supported, as it would become a mess to fill the 32nd-duration gap
	if duration == 0.375:
		print("figure not supported")
		return
	
	
	var figure := RHYTHMIC_FIGURE.instantiate()
	# Holds how long this figure lasts in relation to the total duration of the measure
	var duration_percentage := duration / beats_amount
	# Calculates how long the beams should be, based on how long the figure lasts (so it connects only to the next one). I cannot for the life of me understand why the fuck duration_percentage * measure_length by itself doesn't work (gives a much larger width, especially on the dotted eighth), so a cut, also proportional to the duration percentage, is made. It works, but it also itches.
	var sprite_width := (duration_percentage * measure_length) - (duration_percentage * 65.0)
	var params := {duration = duration, is_rest = is_rest, sprite_width = sprite_width}
	figure.setup(params)
	figures.add_child(figure)
	
	# Places the figure according to how long it is compared to the length of the measure, having into account how many figures were already placed.
	pathfollow2d.progress_ratio = current_duration / beats_amount
	figure.position = pathfollow2d.position
	
	# Recalculates current duration (with the new figure taken into account), so the next check works
	current_duration = calculate_current_duration()
	# Checks if the last figure placed completes a full beat. If that is the case, current_duration has no decimal value, as there are no "portion of beats" in a complete beat.
	# If so, run the function that makes the beam connections for the current, recently completed beat.
	if current_duration - int(current_duration) == 0.0:
		make_connections()
		
		# If total current duration is the duration of the entire page, set the figure as being the last of it, so highlighter knows when to request a pageturn.
		# This check is made inside the previous if-statement so <1.0 duration notes do not pass the check when converted to int (any notes placed right after the pageturn would pass it.)
		if int(current_duration) == beats_amount * 4:
			figure.is_last_of_page = true


## Groups beams that should be grouped. At some point it should be dynamic, but as the rules are surprisingly complex, right now it is done on a case by case basis.
func make_connections() -> void:
	# Array that holds all figures of the measure
	var figures_array := figures.get_children()
	# Keeps track of how long the figures that are processed in the incoming while loop are (added up). This is to not process figures outside the current beat.
	var processed_duration := 0.0
	# Will be used to loop through the figures from last to first
	var index := -1
	# Keeps track of the figures' durations of the beat being processed
	var beat_durations := []
	# Loops backwards through the figures until their duration totals an entire beat
	while processed_duration < 1.0:
		# No beam is required if any of them has a rest (at least for now), so return immediately if one is found
		if figures_array[index].is_rest:
			return
		# Keep track of the durations inside the beat, the total processed duration, and move on to next index (since it is going backwards, index has to decrease)
		beat_durations.push_front(figures_array[index].duration)
		processed_duration += figures_array[index].duration
		index -= 1
	
	# The match that makes the connections according to the figures that are in the beat.
	match beat_durations:
		[0.5, 0.5], [0.75, 0.25]:
			figures_array[-1].connect_to("previous")
			figures_array[-2].connect_to("next")
		[0.25, 0.25, 0.25, 0.25]:
			figures_array[-1].connect_to("previous")
			figures_array[-2].connect_to("both")
			figures_array[-3].connect_to("both")
			figures_array[-4].connect_to("next")


## Calculates how many beats total all placed figures in the measure
func calculate_current_duration() -> float:
	var output := 0.0
	for figure in figures.get_children():
		output += figure.duration
	return output


## Deletes the last figure of the measure
func delete_last_figure() -> void:
	if figures.get_child_count() != 0:
		figures.get_child(-1).queue_free()



func _on_input_event(_v, event: InputEvent, _s):
	if event.is_action_pressed("left-click"):
		highlighted = not highlighted
		selected_changed.emit(self)
