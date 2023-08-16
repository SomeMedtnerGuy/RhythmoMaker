class_name Highlighter
extends RefCounted

## Sent when the last note of a page stops being highlighted
signal pageturn_requested
## Sent if there are no more figures to highlight
signal end_of_figures_reached

## Colors with which to highlight
const DEFAULT_COLOR := Color.BLACK
const HIGHLIGHT_COLOR := Color.WHITE

## This node with go through this list to highlight the notes in it
var _figures_list := []

## The index of the highlighted figure
var highlighted_figure_i: int:
	# This setter actually defines which figure should be highlighted based on its index in the list
	set(value):
		highlighted_figure_i = value
		# In case a -1 was passed as an argument, it means no figure should be highlighted
		if highlighted_figure_i == -1:
			highlighted_figure = null
		else:
			highlighted_figure = _figures_list[highlighted_figure_i]

## The currently highlighted figure, defined by its index's setter
var highlighted_figure: Figure = null :
	set(value):
		# Remove highlight of previous figure before highlighting new one
		if highlighted_figure:
			highlighted_figure.modulate = DEFAULT_COLOR
		highlighted_figure = value
		# This ensures that if value == null, no figure is highlighted
		if highlighted_figure:
			highlighted_figure.modulate = HIGHLIGHT_COLOR


## Function to be called by the user of this component to pass the list of figures to highlight
func setup(figures_list) -> void:
	_figures_list = figures_list

## Highlights the next figure on the list, and returns it, so caller can use the info stored in it (length in beats, duration, etc)
func highlight_next() -> Figure:
	# If no figure is highlighted, highlight first one 
	if not highlighted_figure:
		highlighted_figure_i = 0
		return highlighted_figure
	# If the currently highlighted figure is the last one, do not return anything and send signal saying it is finished.
	elif highlighted_figure_i == len(_figures_list) - 1:
		end_of_figures_reached.emit()
		clear_highlight()
		return null
	# Otherwise, highlight the next figure
	else:
		# Request a pageturn in case the currently highlighted figure is the last of it
		if highlighted_figure.is_last_of_page:
			pageturn_requested.emit()
		# Setter does all the work. Nothing else is required.
		highlighted_figure_i += 1
		return highlighted_figure


## Stops all highlighting (see setter)
func clear_highlight() -> void:
	highlighted_figure_i = -1
