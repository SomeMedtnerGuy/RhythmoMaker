class_name MarkerTracker
extends Node2D

## Keeps track of whether the mouse is hovering the trash button
var trash_hovered := false
## Keeps track of which page is currently open. This var is managed by Staff
var current_page: MeasuresPage = null
var current_marker: Selectable = null


## The process function only serves to update the position of an active marker
func _process(_delta: float) -> void:
	if current_marker:
		current_marker.global_position = get_global_mouse_position()


## Adds the marker to the tracker
func add_marker(marker: Selectable) -> void:
	# Makes sure that the marker is saved in the currently opened page, so it accompanies it whenever it is opened or closed
	current_page.markers.add_child(marker)
	marker.selection_toggled.connect(_on_marker_selection_toggled)
	# The default behavior is to make it a current marker, which automatically makes it follow the cursor upon creation
	current_marker = marker


func _on_hover_over_trash(is_hovered: bool) -> void:
	trash_hovered = is_hovered


## The custom signal that this function is connected to sends a reference to itself, so this class knows what to drag.
func _on_marker_selection_toggled(marker, was_selected) -> void:
	# As a reminder, everytime _marker has a reference to an object, the _process() function takes care of keeping it close to the mouse.
	if was_selected:
		current_marker = marker
	else:
		# If the marker is dropped at the trash's location, it should be deleted
		if trash_hovered:
			current_marker.queue_free()
		# In any case, it shouuld be deopped. If not at the trash's location, it'll stay at the position the mouse was in when left button was pressed
		current_marker = null


func place_saved_marker(specs: Dictionary, page: MeasuresPage) -> void:
	var marker: Selectable = load("res://BaseObjects/selectable.tscn").instantiate()
	page.markers.add_child(marker)
	marker.selection_toggled.connect(_on_marker_selection_toggled)
	marker.sprite.texture = load(specs.texture_path)
	marker.texture_path = specs.texture_path
	marker.selected = false
	marker.position = Vector2(specs.pos_x, specs.pos_y)
