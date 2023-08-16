## Class which handles scene changes
class_name Main
extends Node

enum SCENES { START, WORKSPACE }

const scenes :={
	SCENES.START: preload("res://MainScenes/start.tscn"),
	SCENES.WORKSPACE: preload("res://MainScenes/work_space.tscn")
}


func _ready() -> void:
	# This signal is emitted by the new_project_menu's "create" button, the only button that triggers a scene change.
	EventBus.new_project_setup_complete.connect(_on_new_project_setup_complete)
	
	change_scene(SCENES.START)


## Changes the current scene
func change_scene(scene: SCENES, specs: Dictionary = {}) -> void:
	# In case a scene is active, remove it first
	if get_child_count() != 0:
		remove_child(get_child(0))
	
	var new_scene: Node = scenes[scene].instantiate()
	add_child(new_scene)
	# In case a setup is needed (for example sending the specs to a new project)
	if not specs.is_empty():
		new_scene.setup(specs)



## Callback for when the user presses "create" in the new_project_menu
func _on_new_project_setup_complete(specs) -> void:
	change_scene(SCENES.WORKSPACE, specs)
