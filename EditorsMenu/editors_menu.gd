class_name EditorsMenu
extends PanelContainer


## Signals for when options that need to be handled by a different class are chosen:
signal figure_chosen(figure_specs: Dictionary)
signal barline_chosen(barline: Types.BARLINES)
signal marker_chosen(marker: Selectable)

## Color the editor_button should take when chosen and its editor is active
const DEFAULT_MODULATE := Color(1.0, 1.0, 1.0)
const ACTIVE_MODULATE := Color(1.0, 0.0, 1.0)

## Scene of object that can be selected:
const SELECTABLE_SCENE := preload("res://BaseObjects/selectable.tscn")

## Types of editors
enum EDITOR { NONE, FIGURES, BARLINES, DYNAMICS, ORFF, SECTIONS }


## Dictionaries that connect the different marker options to their respective texture_paths
var dynamics_markers := {
	Types.DYNAMICS.PIANISSIMO: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_1.png",
	Types.DYNAMICS.PIANO: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_2.png",
	Types.DYNAMICS.MEZZOPIANO: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_3.png",
	Types.DYNAMICS.MEZZOFORTE: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_4.png",
	Types.DYNAMICS.FORTE: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_5.png",
	Types.DYNAMICS.FORTISSIMO: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_6.png",
	Types.DYNAMICS.CRESCENDO: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_7.png",
	Types.DYNAMICS.DIMINUENDO: "res://EditorsMenu/DynamicsEditor/Markers/DynamicsMarkers_8.png"
}

var orffs_markers := {
	Types.ORFFS.RHYTHM_STICKS: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_1.png",
	Types.ORFFS.MARACAS: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_2.png",
	Types.ORFFS.WOODBLOCK: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_3.png",
	Types.ORFFS.BELL_STRAPS: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_4.png",
	Types.ORFFS.TUBULAR_WOODBLOCK: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_5.png",
	Types.ORFFS.TRIANGLE: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_6.png",
	Types.ORFFS.CYMBALS: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_7.png",
	Types.ORFFS.TAMBOURINE: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_8.png",
	Types.ORFFS.HAND_DRUM: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_9.png",
	Types.ORFFS.RECO_RECO: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_10.png",
	Types.ORFFS.CASTANETS: "res://EditorsMenu/OrffEditor/Markers/OrffsMarkers2_11.png",
}

var sections_markers := {
	Types.SECTIONS.A: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkerA.png",
	Types.SECTIONS.B: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersB.png",
	Types.SECTIONS.C: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersC.png",
	Types.SECTIONS.D: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersD.png",
	Types.SECTIONS.E: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersE.png",
	Types.SECTIONS.F: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersF.png",
	Types.SECTIONS.G: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersG.png",
	Types.SECTIONS.H: "res://EditorsMenu/SectionsEditor/Markers/SectionsMarkersH.png"
}
## And this one connects the types of editor to their respective dictionary of markers-textures
var type_to_markers := {
	EDITOR.DYNAMICS: dynamics_markers,
	EDITOR.ORFF: orffs_markers,
	EDITOR.SECTIONS: sections_markers
}

## Keeps track of which editor is open
var active_editor := EDITOR.NONE

## The node that holds all the editors, where the user can choose one to be open
@onready var editor_options_container := $EditorOptionsContainer
## This node holds all the editors themselves, but only the active editor is visible
@onready var active_editor_container := $ActiveEditor
## This button serves to close the active editor. It has the sprite corresponding to the active editor.
@onready var active_editor_button := $ActiveEditor/ActiveEditorButton

## This dictionary holds the nodes connected to the different editors, so they can become the used nodes for the editor choice of the user
@onready var editors_dict := {
	EDITOR.FIGURES: {
		button = $EditorOptionsContainer/FiguresEditorButton,
		editor = $ActiveEditor/PanelContainer/FiguresEditor,
	},
	EDITOR.BARLINES: {
		button = $EditorOptionsContainer/BarlinesEditorButton,
		editor = $ActiveEditor/PanelContainer/BarlinesEditor,
	},
	EDITOR.DYNAMICS: {
		button = $EditorOptionsContainer/DynamicsEditorButton,
		editor = $ActiveEditor/PanelContainer/DynamicsEditor,
	},
	EDITOR.ORFF: {
		button = $EditorOptionsContainer/OrffEditorButton,
		editor = $ActiveEditor/PanelContainer/OrffEditor,
	},
	EDITOR.SECTIONS: {
		button = $EditorOptionsContainer/SectionsEditorButton,
		editor = $ActiveEditor/PanelContainer/SectionsEditor,
	},
}


## All editor buttons are connected to this function. It opens the chosen editor (makes it visible.
func _on_editor_option_pressed(editor: EDITOR) -> void:
	# First, place the EDITOR enum int in the respective variable
	active_editor = editor
	
	# The following functions perform all the necessary steps to activate an editor. What each one does is described in the name, and the details are explained in the functions themselves.
	setup_active_editor()
	# The moving_sprite is the image that pretends to be the clicked button, moving from original position to where the active_editor_button should be
	var moving_sprite = create_moving_sprite()
	# These steps should act sequentially, hence all the "await"s 
	await fade_out_editor_options()
	await move_moving_sprite(moving_sprite)
	await fade_in_active_editor()
	moving_sprite.hide()


## This callback is triggered when the user wants to close the active editor. It basically performs the inverse of the previous function.
func _on_active_editor_button_pressed() -> void:
	# The sprite "button" is still a child and hidden, so we get it to reuse it, not having to worry about placing it anywhere (it's already in the right spot).
	var moving_sprite = get_node("MovingSprite")
	moving_sprite.show()
	await fade_out_active_editor()
	# The corresponding opposite step in the activation of the editor is performed in the setup_active_editor() function. Since in this case no other task is required other than the hiding, this is done directly here.
	editors_dict[active_editor].editor.hide()
	await move_back_moving_sprite(moving_sprite)
	await fade_in_editor_options()
	# Now we won't need the sprite anymore. When a new editor is open, a new sprite is created.
	moving_sprite.queue_free()
	# Finally, clear the reference to the editor enum int.
	active_editor = EDITOR.NONE


## Prepares the correct editor for activation
func setup_active_editor() -> void:
	# We can get the right specs by checking what is on the active_editor variable, as this is set right before this function is called
	var editor_specs: Dictionary = editors_dict[active_editor]
	# Show the editor. This for now does nothing, because the editors container is also invisible, but when that is shown, only this editor is shown with it, because it is the only visible.
	editor_specs.editor.show()
	# Ready the button that allows the editor to be closed (and shows which editor is active). All needed is to set the sprites.
	active_editor_button.texture_normal = editor_specs.button.texture_normal
	active_editor_button.texture_pressed = editor_specs.button.texture_pressed


## This sprite's task is to pretend to be the editor button and move from its place in the menu to the active_editor_button's place (looking like the same button). In this function, it is only set up.
func create_moving_sprite() -> Sprite2D:
	# Sprite is created
	var moving_sprite := Sprite2D.new()
	# The given name makes sure we can get it afterwards
	moving_sprite.name = "MovingSprite"
	# Decentering it makes sure that it matches the positions of the buttons, which are not centered by default (Sprites are)
	moving_sprite.centered = false
	# Sets the texture to match the button it mimics and places it at the button's position
	moving_sprite.texture = editors_dict[active_editor]["button"].texture_normal
	moving_sprite.position = editors_dict[active_editor]["button"].global_position
	# This makes sure the sprite is not drawn below anything else
	moving_sprite.set_as_top_level(true)
	# Finally add the child and return the reference, so it can be moved later
	add_child(moving_sprite)
	return moving_sprite


## Simply fades out all editor options by tweening its alpha value all the way down to 0. Since the sprite of the chosen button is already there at its position, it gives the ilusion that the button doesn't disappear.
func fade_out_editor_options() -> void:
	# Makes sure button cannot be innteracted more than once before disappearing
	editor_options_container.process_mode = Node.PROCESS_MODE_DISABLED
	var tween := create_tween()
	tween.tween_property(editor_options_container, "modulate:a", 0, 0.5)
	await tween.finished
	# Even though it is not seen anymore, it still needs to be hidden so input detection is deactivated.
	editor_options_container.hide()


## The exact opposite of fade_out_editor_options()
func fade_in_editor_options() -> void:
	editor_options_container.show()
	var tween := create_tween()
	tween.tween_property(editor_options_container, "modulate:a", 1, 0.5)
	# Still needs this await so the caller of this function does not move on before the tween is finished
	await tween.finished
	editor_options_container.process_mode = Node.PROCESS_MODE_INHERIT


## Moves the "pretend-button" (aka the sprite) from its position to the left edge.
func move_moving_sprite(moving_sprite: Sprite2D) -> void:
	var tween = create_tween()
	# By default, multiple tweens run one after another. Calling this method ensures they run at the same time
	tween.set_parallel()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	# We want the top left corner of the sprite to be on top of the top left corner of the PanelContainer EditorsMenu. Since the sprite's position is dictated by the position of that corner, the same for all Control Nodes, we can just set the target for that position to be EditorsMenu's position.
	tween.tween_property(moving_sprite, "position", global_position, 1.0)
	tween.tween_property(moving_sprite, "self_modulate", ACTIVE_MODULATE, 1.0)
	await tween.finished


## The opposite of move_moving_sprite()
func move_back_moving_sprite(moving_sprite: Sprite2D) -> void:
	moving_sprite.show()
	var tween = create_tween()
	tween.set_parallel()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	# Target position should be the position of the respective editor's button
	tween.tween_property(moving_sprite, "position", editors_dict[active_editor]["button"].global_position, 1.0)
	tween.tween_property(moving_sprite, "self_modulate", DEFAULT_MODULATE, 1.0)
	await tween.finished


## Once the sprite is in its place, we can fade in the active editor, so the ActiveEditorButton can take its place seamlessly. Since this node was already set up (the right editor was picked), all we need to do is activate it and tween its alpha value.
func fade_in_active_editor() -> void:
	active_editor_container.show()
	var tween = create_tween()
	tween.tween_property(active_editor_container, "modulate:a", 1, 0.5)
	await tween.finished
	active_editor_container.process_mode = Node.PROCESS_MODE_INHERIT


## The opposite of fade_in_active_editor().
func fade_out_active_editor() -> void:
	# Makes sure the buttons in the active editor are immediately disabled, so they cannot be clicked more than once before disappearing
	active_editor_container.process_mode = Node.PROCESS_MODE_DISABLED
	var tween = create_tween()
	tween.tween_property(active_editor_container, "modulate:a", 0, 0.5)
	await tween.finished
	active_editor_container.hide()


## The only two editors that need to forward choices are figures and barlines, because the alterations are made directly on the measures, which EditorsMenu doesn't have access to. The following two callbacks do just that
func _on_figures_editor_figure_chosen(figure_specs: Dictionary) -> void:
	figure_chosen.emit(figure_specs)


func _on_barlines_editor_barline_chosen(barline: Types.BARLINES) -> void:
	barline_chosen.emit(barline)


## All other editors create markers upon choice made, so they are connected here instead. 
func _on_editor_marker_chosen(option) -> void:
	# "type_to_markers" links the enum values of the different general types of markers that exist (dynamics, orffs and sections) to the dictionaries that will provide the correct textures. We find which general type should be used by checking which editor is currently active.
	var markers_dict: Dictionary = type_to_markers[active_editor]
	# Each "markers_dict" connects the enum value of the particular marker to the texture_path for that marker. The option was sent by the button itself.
	var marker_texture_path: String = markers_dict[option]
	# Now the marker is created with the newly found texture
	var marker: Selectable = create_marker(marker_texture_path)
	# After all is done, the marker should be sent to the tracker to be attached to the correct page
	marker_chosen.emit(marker)

## A marker is an object that, when selected, moves along with the mouse.
func create_marker(texture_path: String) -> Selectable:
	var marker = SELECTABLE_SCENE.instantiate()
	# "markers" links an enum value to a texture_path. That enum value represents the marker chosen to be created (sent by the marker's respective menus). Therefore, the texture_path that it is linked to should lead to the texture of the sprite of the marker object, so the function loads it and assigns it to the correct property of the marker.
	marker.get_node("Sprite2D").texture = load(texture_path)
	marker.texture_path = texture_path
	# Returns the marker, so the caller can forward it to be attached to the page
	return marker
