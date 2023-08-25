extends MenuTree

signal menu_open_changed(is_open)


func _ready() -> void:
	
	setup_buttons()
	# Initial state of the tree should be with only the MainButton visible
	MenuManager.clear()
	MenuManager.change_to_menu($MainButton)


## Forwards the signal of the visibility of the MainMenuButton, effectively telling if the Main Menu is open or not. When it is open, the button disappears, so is_being_used = !button.visible
func _on_main_visibility_changed() -> void:
	menu_open_changed.emit(not get_node("MainButton").visible)


## Callback for the MainButton's "pressed" signal. Opens the main menu. Cannot be a menu in itself because the Button and the Menu which should go to are children of the same Parent, therefore cannot have the same name (required in the current setup for the button to lead to the menu).
func _on_main_button_pressed() -> void:
	MenuManager.change_to_menu($Main)
