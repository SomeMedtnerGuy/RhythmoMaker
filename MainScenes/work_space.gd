class_name Workspace
extends Node

const EDITOR_WINDOW_COLOR_ACTIVE := Color(1,1,1,1)
const EDITOR_WINDOW_COLOR_INACTIVE := Color(1,1,1,0.34)

@onready var editor_window: EditorWindow = $EditorWindow
@onready var editor_window_inactive_indicator := $EditorWindow/InactiveIndicator
@onready var main_menu_tree: Control = $CanvasLayer/MarginContainer/MainMenuTree


func setup(specs: Dictionary) -> void:
		editor_window.setup(specs)


## When Main Menu is opened, the main layer should fade out. The inactive_indicator does just that
func _on_main_menu_tree_menu_open_changed(is_open) -> void:
	if editor_window:
		editor_window.active = not is_open


func load_menu_vars(vars: Dictionary) -> void:
	var automatic_mode_settings_menu := main_menu_tree.get_node("AutomaticSettings")
	automatic_mode_settings_menu.set_tempo.line_edit.text = str(vars.track_bpm)
	automatic_mode_settings_menu.set_delay.line_edit.text = str(vars.first_highlight_delay)
