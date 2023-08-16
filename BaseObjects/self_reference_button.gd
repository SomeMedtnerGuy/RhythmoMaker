## Object that returns itself inside the custom "typed_pressed" signal
class_name SelfReferenceButton
extends TextureButton

signal typed_pressed(type: int)

## Variable used to hold the Resource which holds the type of the button itself, which is used on its "typed_pressed" signal. ButtonCategory is an empty Resource class only to group all other inherited types that will have the sub-type as an exported variable. For example, "SectionOptions" inherits from ButtonCategory, and its exported variable holds which section the button actually references. The emmited signal has to get "button_category" (the particular SectionOptions resource) and use its "type" property to get the type of that specific button.
@export var button_category: ButtonCategory


func _ready() -> void:
	pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	typed_pressed.emit(button_category.type)
