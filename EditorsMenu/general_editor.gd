@tool
## General class for an editor
class_name GeneralEditor
extends HBoxContainer

## Every editor has choices available. This signal notifies the listener that a choice was made, and send that option with it. (Usually in the form of an enum)
signal option_chosen(option)


## Makes sure all buttons have the typed_pressed signal provided by the SelfReferenceButton class, so it can be connected in the _ready() function.
func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is SelfReferenceButton:
			continue
		else:
			return ["All children must be of type SelfReferenceButton!"]
	return []


func _ready() -> void:
	for button in get_children():
		button.typed_pressed.connect(_on_typed_button_typed_pressed)


func _on_typed_button_typed_pressed(button_type) -> void:
	option_chosen.emit(button_type)
