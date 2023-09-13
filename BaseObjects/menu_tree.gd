## Class that holds and conttrols a particular set of menus, deciding which menu should be sent to MenuController for change.  
class_name MenuTree
extends Node


## Function to be called by inherited MenuTree to setup its buttons
func setup_buttons() -> void:
	# Connects all buttons that should move the user further into a MenuTree. It assumes the name of the button is the same as the name of the Menu that should move to.
	for option_button in get_tree().get_nodes_in_group("menu_button"):
		var menu_name := option_button.get_name()
		# Use the SttringName of the button to get the NodePath of the Menu, and use that to get the Node itself.
		var menu := get_node(NodePath(menu_name))
		# Finally,connect the pressed signal of the button to the function that calls the MenuManager's correct function, passing the Node of the menu it should change to.
		option_button.pressed.connect(_on_menu_button_pressed.bind(menu))
	
	# The rest of the buttons should be connected too. They could be connected directly in the menu, but since the MenuButtons must be connected here to be able to bind the Menu Node, it is nice to have all connections happen in the same place.
	for option_button in get_tree().get_nodes_in_group("return_button"):
		option_button.pressed.connect(_on_return_button_pressed)
	
	for option_button in get_tree().get_nodes_in_group("quit_button"):
		option_button.pressed.connect(_on_quit_button_pressed)


## Callback for MenuButtons' "pressed" signal. Moves the user further inside the tree.
func _on_menu_button_pressed(menu) -> void:
	MenuManager.change_to_menu(menu)


## Callback for ReturnButtons' "pressed" signal. Moves the user backwards one level of the tree.
func _on_return_button_pressed() -> void:
	MenuManager.return_to_previous()


## Callback for QuitButtons' "pressed" signal. Creates a confirmation window.
func _on_quit_button_pressed() -> void:
	var quit_confirm = ConfirmationDialog.new()
	add_child(quit_confirm)
	quit_confirm.cancel_button_text = "Cancelar"
	quit_confirm.ok_button_text = "Confirmar"
	quit_confirm.dialog_text = "Tem a certeza que quer sair do programa?"
	quit_confirm.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_PRIMARY_SCREEN
	quit_confirm.confirmed.connect(_on_quit_confirmed)
	quit_confirm.canceled.connect(_on_quit_canceled.bind(quit_confirm))
	quit_confirm.visible = true


func _on_quit_confirmed() -> void:
	get_tree().quit()


func _on_quit_canceled(quit_confirm: ConfirmationDialog) -> void:
	quit_confirm.queue_free()
