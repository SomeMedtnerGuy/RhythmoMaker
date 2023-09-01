class_name Highlighter2
extends RefCounted

signal page_changed(page_i: int)
signal finished

## Colors with which to highlight
const DEFAULT_COLOR := Color.BLACK
const HIGHLIGHT_COLOR := Color.WHITE

#To be updated each time Recorder or Playback starts
var _staff: Staff

var currently_highlighted: Figure

var _p := 0
var _m := 0
var _f := -1

var _pages: Array
var _measures: Array
var _figures: Array

## x: page_i, y: measure_i
var _start_rep := Vector2i(0, 0)
var _has_repeated := false


func setup(staff: Staff) -> void:
	_staff = staff
	_pages = staff.get_pages()
	_measures = _pages[_p].get_measures()
	_figures = _measures[_m].get_figures()


func next() -> Figure:
	if currently_highlighted:
		clear_highlight()
	if more_figures_exist():
		update_vars()
		currently_highlighted = _figures[_f]
		currently_highlighted.modulate = HIGHLIGHT_COLOR
		
		return currently_highlighted
	else:
		finished.emit()
		return null


func more_figures_exist() -> bool:
	if _f + 1 <= len(_figures) - 1:
		_f += 1
		return true
	else:
		return more_measures_exist()


func more_measures_exist() -> bool:
	if _measures[_m].barline_type == Types.BARLINES.ENDREP and not _has_repeated:
		_p = _start_rep.x
		_m = _start_rep.y
		_f = 0
		_has_repeated = true
		page_changed.emit(_p)
		return true
	elif _m + 1 <= len(_measures) - 1:
		_m += 1
		_f = 0
		if _measures[_m].get_figures().is_empty():
			return false
		if _measures[_m].is_start_repeat:
			_start_rep = Vector2(_p, _m)
			_has_repeated = false
		return true
	else:
		return more_pages_exist()


func more_pages_exist() -> bool:
	if _p + 1 <= len(_pages) - 1:
		_p += 1
		_m = 0
		_f = 0
		page_changed.emit(_p)
		return true
	else:
		return false


func update_vars() -> void:
	_measures = _pages[_p].get_measures()
	_figures = _measures[_m].get_figures()


func clear_highlight() -> void:
	if currently_highlighted:
		currently_highlighted.modulate = DEFAULT_COLOR
		currently_highlighted = null
