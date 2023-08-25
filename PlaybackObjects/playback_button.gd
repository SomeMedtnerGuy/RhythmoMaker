extends TextureButton

signal toggled_down
signal toggled_up


## Simply divides this callback's signal in two, so they can be connected directly to the functions in Editor that trigger the necessary behavior
func _on_toggled(_button_pressed):
	if _button_pressed:
		toggled_down.emit()
	else:
		toggled_up.emit()
