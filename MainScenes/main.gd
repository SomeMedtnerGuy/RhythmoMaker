## Class which handles scene changes
class_name Main
extends Node

enum SCENES { START, WORKSPACE }

const scenes :={
	SCENES.START: preload("res://MainScenes/start.tscn"),
	SCENES.WORKSPACE: preload("res://MainScenes/work_space.tscn")
}


func _ready() -> void:
	# Makes sure the Directories used to store audio and saved projects are working properly
	var program_folder := OS.get_executable_path().get_base_dir()
	if not DirAccess.dir_exists_absolute(program_folder + "/projects"):
		DirAccess.make_dir_absolute(program_folder + "/projects")
	if not DirAccess.dir_exists_absolute(program_folder + "/audio"):
		DirAccess.make_dir_absolute(program_folder + "/audio")
	
	
	# This signal is emitted by the new_project_menu's "create" button, the only button that triggers a scene change.
	EventBus.project_specs_defined.connect(_on_project_specs_defined)
	EventBus.open_project_requested.connect(_on_open_project_requested)
	change_scene(SCENES.START)


## Changes the current scene
func change_scene(scene: SCENES) -> Node:
	# In case a scene is active, remove it first
	if get_child_count() != 0:
		remove_child(get_child(0))
	
	var new_scene: Node = scenes[scene].instantiate()
	add_child(new_scene)
	
	return new_scene


## Callback for when the user presses "create" in the new_project_menu
func _on_project_specs_defined(specs: Dictionary) -> void:
	var new_project_scene = change_scene(SCENES.WORKSPACE)
	new_project_scene.setup(specs)


func _on_open_project_requested(saved_data: Dictionary) -> void:
	var saved_workspace: Workspace = change_scene(SCENES.WORKSPACE)
	saved_workspace.editor_window.load_project(saved_data)
	saved_workspace.load_menu_vars(saved_data.synchronizer_vars)
