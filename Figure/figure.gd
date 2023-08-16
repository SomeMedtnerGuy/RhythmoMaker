class_name Figure
extends Sprite2D

const MIN_WIDTH = 30.0
const MAX_WIDTH = 120.0

## Maps the duration of the figures to their x position in the spritesheet
const DURATION_TO_REGION_X := {
	4.0: 0,
	2.0: 128,
	1.0: 256,
	0.5: 384,
	0.25: 512,
	6.0: 640,
	3.0: 768,
	1.5: 896,
	0.75: 1024,
	0.125: 1152
}

const IS_REST_TO_REGION_Y := {
	false: 0,
	true: 64
}
## Maps the way the figure connects to the neighbor to the sprite y position in the spritesheet
const DIRECTION_TO_REGION_Y := {
	next = 128,
	previous = 192,
	both = 256
}
## Height of the sprite (width is variable, according to how far away the neighbor is)
const RECT_SIZE_Y = 64

## Duration in beats
var duration := 1.0
## Duration in seconds, to be calculated after bpm is defined, or manual highlighting is performed. Used by synchronizer to know when to highlight
var duration_time: float

var is_rest := false
var is_last_of_page := false

## How wide the sprite is. Allows connections to neighbors no matter their distance to oneanother
var sprite_width := 128.0:
	set(value):
		sprite_width = clamp(value, MIN_WIDTH, MAX_WIDTH)


func setup(params) -> void:
	duration = params.duration
	is_rest = params.is_rest
	sprite_width = params.sprite_width
	# Draws from spritesheet aaccording to duration, is_rest flag and the sprite width
	region_rect = Rect2(
		DURATION_TO_REGION_X[duration], IS_REST_TO_REGION_Y[is_rest], 
		sprite_width, RECT_SIZE_Y
	)


## OPTIONS: "next", "previous", "both"
func connect_to(direction) -> void:
	region_rect = Rect2(DURATION_TO_REGION_X[duration], DIRECTION_TO_REGION_Y[direction], sprite_width, 64)

