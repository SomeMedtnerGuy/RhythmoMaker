class_name MarkerTracker
extends Node2D

var trash_hovered := false
var current_page: MeasuresPage = null
var current_marker: Selectable = null


## The process function only serves to update the position of an active marker
func _process(_delta: float) -> void:
	if current_marker:
		current_marker.global_position = get_global_mouse_position()


func add_marker(marker: Selectable) -> void:
	current_page.markers.add_child(marker)
	marker.selection_toggled.connect(_on_marker_selection_toggled)
	current_marker = marker


func _on_hover_over_trash(is_hovered: bool) -> void:
	trash_hovered = is_hovered


## The custom signal that this function is connected to sends a reference to itself, so this class knows what to drag.
func _on_marker_selection_toggled(marker, was_selected) -> void:
	# As a reminder, everytime _marker has a reference to an object, the _process() function takes care of keeping it close to the mouse.
	if was_selected:
		current_marker = marker
	else:
		if trash_hovered:
			current_marker.queue_free()
		current_marker = null


