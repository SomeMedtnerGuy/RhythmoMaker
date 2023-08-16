extends Node

## This variables holds the current menu tree, or path. When moving further inside the menu, the most recent window is simply hidden and the opened menu reference is added to the tree. This way, the references to the menus of the paths are kept, so returning to a previous menu is easy: All that is needed is to hide the last element, remove the reference and show the second-to-last, now last node of the array.
var _current_menu := []


## Changes menu. ONLY USED WHEN MOVING FURTHER INSIDE THE MENU TREE. Use return_to_previous() or return_to_first() to move backwards as needed.
func change_to_menu(menu) -> void:
	# If there is a menu in view, hide it first
	if not _current_menu.is_empty():
		_current_menu[-1].hide()
	_current_menu.push_back(menu)
	menu.show()


func return_to_previous() -> void:
	_current_menu[-1].hide()
	_current_menu.pop_back()
	_current_menu[-1].show()


func return_to_first() -> void:
	_current_menu[-1].hide()
	# By resizing the _current_menu to 1, it effectively deletes the references to the menus of the entire tree, except the first one.
	_current_menu.resize(1)
	# Just show the only menu left in the array.
	_current_menu[0].show()


## Clears the Array of menus 
func clear() -> void:
	if not _current_menu.is_empty():
		_current_menu[-1].hide()
	_current_menu.clear()



