extends Node2D

@onready var board : AstarTileMap = $Board
@onready var astarDebug = $AstarDebug
@onready var player = $Board/Player
@onready var line = $Line

func _input(event):
	if event.is_action_pressed("mouse_left"):
		var target_cell = (event.position / board.tile_set.tile_size.x).floor() * board.tile_set.tile_size.x
		var path_points = board.get_astar_path_avoiding_obstacles_and_units(player.global_position, target_cell)
		line.position = board.tile_set.tile_size/2 # Use offset to move line to center of tiles
		line.points = path_points
	
	if event.is_action_pressed("mouse_right"):
		line.points = []
	
	if event.is_action_pressed("ui_accept"):
		astarDebug.visible = !astarDebug.visible
