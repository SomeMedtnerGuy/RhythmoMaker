class_name Highlighter
extends RefCounted

## Emitted when highlighter finds the last note of a page or the last note of a repeated section that must jump back
signal page_changed(page_i: int)
## Emitted when highlighter reaches the last note of the score
signal finished

## Constant values used for highlight
const DEFAULT_COLOR := Color.BLACK
const HIGHLIGHT_COLOR := Color.WHITE
const DEFAULT_SCALE := Vector2(1.0, 1.0)
const HIGHLIGHT_SCALE := Vector2(1.3, 1.3)

## Holds a reference to the score, so it can read it
var _staff: Staff
## Keeps the figure that is currently being highlighted
var currently_highlighted: Figure

## These variables hold the index numbers of the page, measure and figure respectively currently being processed 
var _p := 0
var _m := 0
var _f := -1
## Holds the Array containing all pages of the Staff. 
var _pages: Array
## Holds the Array containing all measures in the _pages[_p] page.
var _measures: Array
## Holds the Array containing all figures in the _measures[_m] measure.
var _figures: Array

## Represents the measure with a start rep barline which the highlighter should go back to after reaching the last figure of the very first end rep measure. x: page_i, y: measure_i, i.e. the measure can be accessed by _pages[_start_rep.x].get_measures()[_start_rep.y]
var _start_rep := Vector2i(0, 0)
## Makes sure the section is only repeated once. It gets set to false after any start_rep is reached for the first time, and set to true when it is reached for the second time.
var _has_repeated := false


## Called everytime a highlighter is created. Just in case, a new one is created everytime a playback or a duration setting is requested (they are light to produce) and this way there is no need to keep track which variables should be reset. This function simply gives the staff and its arrays of pages, measures and figures to the corresponding vars, using the default values for which set of measures and arrays to use (0 for _p, so _measures is the set of measures of the first page, and 0 for _m, so _figures is the set of figures of the first measure).
func setup(staff: Staff) -> void:
	_staff = staff
	_pages = staff.get_pages()
	_measures = _pages[_p].get_measures()
	_figures = _measures[_m].get_figures()


## Highlights the next figure in the staff. The logic below allows highlighter to read music in order like a human would.
func next() -> Figure:
	# First of all, if there is a highlighted figure, clear it (most times except at the very beginning of the playback)
	if currently_highlighted:
		clear_highlight()
	# Then, check if there is a figure after the previoulsy highlighted one. This can be in the same bar, the next, the next page or even back to the start of the start_rep bar, if the end of a end_rep one is reached.
	if more_figures_exist():
		# In that case, make sure that the arrays are all up to speed, because more_figures_exist() might have changed the index variables (_p, _m and _f) and the arrays in the Array vars must reflect those changes
		update_arrays()
		# Highlight the figure that comes next (_f is already the index of that figure)
		highlight_figure(_figures[_f])
		# Returns the figure so synchronizer can do extra calculations if needed.
		return currently_highlighted
	else:
		# If there are no figures left, just announce it and leave
		finished.emit()
		return null


## Returns true if there is a figure to highlight after the current one, false otherwise
func more_figures_exist() -> bool:
	# _f + 1 is the index of the next figure. len(_figures) - 1 is the index of the last figure of the array of figures of the current measure. If the index of the next figure is still equal or smaller than the index of the last figure of the measure, it means that the next figure exists in _figures.
	if _f + 1 <= len(_figures) - 1:
		# Update the var accordingly
		_f += 1
		return true
	# If no more figures exist in the current measure, we must check if there are more measures afterwards
	else:
		return more_measures_exist()


## Returns true if more measures exist after the current one, false otherwise
func more_measures_exist() -> bool:
	# The first check that must be made is if the bar has a end_rep barline, in which case it must repeat if it hasn't done so yet.
	if _measures[_m].barline_type == Types.BARLINES.ENDREP and not _has_repeated:
		# Get the correct page and measure where start_rep can be found. I there isn't any, the default is (0, 0), which is the beginning of the piece
		_p = _start_rep.x
		_m = _start_rep.y
		# The figure highlighted should be the first of the measure
		_f = 0
		# As we are repeating, we must update the flag accordingly
		_has_repeated = true
		# Just in case that new measure is in a new page, request a pageturn. The signal can be sent either way, because if the page is the same, nothing happens anyway (page is turn to the same page)
		page_changed.emit(_p)
		# As we are going back, it counts as there being more measures
		return true
	# In case the measure does not have any repeat sign, we must check if there are any measures afterwards. The logic is the same as for figures.
	elif _m + 1 <= len(_measures) - 1:
		_m += 1
		# Return to first figure, this time of new measure
		_f = 0
		# In case the next measure is empty, the chosen behavior is for the synchronizer to end playback immediately (it means that the rhythmogram is not complete)
		if _measures[_m].get_figures().is_empty():
			return false
		# Here a check is made to see if the highlighter should come back here when it encounters a repeat sign.
		if _measures[_m].is_start_repeat:
			# Save the measure in the right spot
			_start_rep = Vector2(_p, _m)
			# As we are seeing this barline for the first time at this point, it means we haven't arrived here from a repetition. So, a flag update is in order
			_has_repeated = false
		return true
	# Finally, if there are no more measures in the page, we check if there are more pages
	else:
		return more_pages_exist()


## Checks if there is a page after the current one. Logic is the same as previous two functions
func more_pages_exist() -> bool:
	if _p + 1 <= len(_pages) - 1:
		_p += 1
		_m = 0
		_f = 0
		page_changed.emit(_p)
		return true
	else:
		return false


## Whenever the index vars change, the arrays must be updated. This functions does that
func update_arrays() -> void:
	_measures = _pages[_p].get_measures()
	_figures = _measures[_m].get_figures()


## Function that holds highlighting behavior
func highlight_figure(figure: Figure) -> void:
	currently_highlighted = figure
	currently_highlighted.modulate = HIGHLIGHT_COLOR
	currently_highlighted.scale = Vector2(1.2, 1.2)


## Clears highlight from current figure by undoing highlight_figure()'s work
func clear_highlight() -> void:
	if currently_highlighted:
		currently_highlighted.modulate = DEFAULT_COLOR
		currently_highlighted.scale = DEFAULT_SCALE
		currently_highlighted = null

