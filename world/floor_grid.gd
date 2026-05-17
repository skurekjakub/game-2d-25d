class_name FloorGrid
extends Node2D

@export var size: Vector2 = Vector2(1920, 1080)
@export var cell_size: int = 64
@export var line_color: Color = Palette.FLOOR_GRID_LINE
@export var line_width: float = 1.0


func _draw() -> void:
	var half_x: float = size.x * 0.5
	var half_y: float = size.y * 0.5
	# Vertical lines
	var x: float = -half_x
	while x <= half_x:
		draw_line(Vector2(x, -half_y), Vector2(x, half_y), line_color, line_width)
		x += cell_size
	# Horizontal lines
	var y: float = -half_y
	while y <= half_y:
		draw_line(Vector2(-half_x, y), Vector2(half_x, y), line_color, line_width)
		y += cell_size
