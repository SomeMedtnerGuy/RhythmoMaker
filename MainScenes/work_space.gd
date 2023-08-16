extends Node

var editor_window_active := true:
	set(value):
		editor_window_active = value
		if editor_window:
			if editor_window_active:
				editor_window.process_mode = Node.PROCESS_MODE_INHERIT
			else:
				editor_window.process_mode = Node.PROCESS_MODE_DISABLED

@onready var editor_window := $EditorWindow
@onready var editor_window_inactive_indicator := $EditorWindow/InactiveIndicator


func setup(specs) -> void:
	editor_window.setup(specs)


## When Main Menu is opened, the main layer should fade out. The inactive_indicator does just that
func _on_main_menu_tree_menu_open_changed(is_open) -> void:
	# This ensures the indicater is ready for use when the signal is emitted
	if editor_window_inactive_indicator:
		editor_window_inactive_indicator.visible = is_open
	
	# When the menu is open, the editor window should be deactivated, so the user cannot click on things. The setter takes care of that
	editor_window_active = not is_open
