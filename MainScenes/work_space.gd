extends Node

const EDITOR_WINDOW_COLOR_ACTIVE := Color(1,1,1,1)
const EDITOR_WINDOW_COLOR_INACTIVE := Color(1,1,1,0.34)

@onready var editor_window: EditorWindow = $EditorWindow
@onready var editor_window_inactive_indicator := $EditorWindow/InactiveIndicator


func setup(specs: Dictionary) -> void:
	if specs.new:
		editor_window.setup(specs)
	else:
		for loader in get_tree().get_nodes_in_group("loader"):
			loader.call("load_data", specs)


## When Main Menu is opened, the main layer should fade out. The inactive_indicator does just that
func _on_main_menu_tree_menu_open_changed(is_open) -> void:
	if editor_window:
		editor_window.active = not is_open
