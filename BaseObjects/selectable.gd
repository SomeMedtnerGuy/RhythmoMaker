## Base object for all objects that can be selected/highlighted
class_name Selectable
extends Area2D

## Emitted when user clicks on selectable. Sends reference to itself, so it can be attached by receiver to any object it wishes
signal selection_toggled(marker, was_selected)

## Modulate constants to distinguish between selected and not selected
const DEFAULT_COLOR := Color(1, 1, 1, 1)
const SELECT_COLOR := Color(1, 1, 0.57, 0.35)

## Keeps track whether the selectable is being hovered or not
var _hovered := false
## Holds whether the object is selected or not. Changes the visual representation and emits the signal in case other classes need to react to it.
var selected := true:
	set(value):
		selected = value
		if selected:
			sprite.modulate = SELECT_COLOR
			selection_toggled.emit(self, true)
		else: 
			sprite.modulate = DEFAULT_COLOR
			selection_toggled.emit(self, false)

## Used to save and load texture
var texture_path: String
@onready var sprite := $Sprite2D


## The only way to check for input in this case is using the generic _input() function, because the event's propagation must be stopped right away so other objects underneath are not selected. Collision callbacks are only called at the end, while this function is called at the very beggining of event cycle.
func _input(event: InputEvent) -> void:
	if _hovered and event.is_action_pressed("left-click"):
		# This method is what avoids event propagation
		get_viewport().set_input_as_handled()
		# Toggles selection
		selected = not selected


## Callbacks that update the _hovered variable
func _on_mouse_entered() -> void:
	_hovered = true


func _on_mouse_exited() -> void:
	_hovered = false
