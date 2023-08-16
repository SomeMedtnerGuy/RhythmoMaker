class_name FigureButton
extends TextureButton

## Size of the button on both axis
const SIZE := 64
## For spritesheet purposes. The pressed button sprites are 64px below their unpressed counterparts. This is taken into account whenever the texture must be set for both states
const PRESSED_OFFSET := 64

## Maps each figure (and rest) duration to the respective sprite x position in the spritesheet
const DURATION_TO_REGION_X := {
	4.0: 0.0,
	2.0: 64.0,
	1.0: 128.0,
	0.5: 192.0,
	0.25: 256.0
}

## As the rests are placed 120px below their sound counterparts, this maps whether a figure is a rest or not to the respective sprite y position in the spritesheet
const IS_REST_TO_REGION_Y := {
	false: 0.0,
	true: 128.0,
}

## The spritesheet used to draw the buttons
const ATLAS := preload("res://EditorsMenu/FiguresEditor/FiguresButtons.png")

## The duration of the figure that the button holds. Determines the sprite drawn and the duration sent out when clicked
@export var duration := 1.0

## Flag that states whether the figure is a rest or not, based on whether the rest toggle button is on. Setter redraws textures.
var is_rest: bool :
	set(value):
		is_rest = value
		texture_normal.region = Rect2(DURATION_TO_REGION_X[duration], IS_REST_TO_REGION_Y[value], SIZE, SIZE)
		texture_pressed.region = Rect2(DURATION_TO_REGION_X[duration], IS_REST_TO_REGION_Y[value] + PRESSED_OFFSET, SIZE, SIZE)
		queue_redraw()


## Sets initial textures
func _ready():
	texture_normal = AtlasTexture.new()
	texture_normal.atlas = ATLAS
	texture_pressed = AtlasTexture.new()
	texture_pressed.atlas = ATLAS
	is_rest = false
