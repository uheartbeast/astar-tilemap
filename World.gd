extends Node2D

onready var board = $Board
onready var astarDebug = $AstarDebug
onready var player = $Board/Player
onready var line = $Line

func _input(event):
	if event.is_action_pressed("mouse_left"):
		var target_cell = (event.position / board.cell_size).floor() * board.cell_size
		var path_points = board.get_astar_path_avoiding_obstacles(player.global_position, target_cell)
		line.position = board.cell_size/2 # Use offset to move line to center of tiles
		line.points = path_points
	
	if event.is_action_pressed("mouse_right"):
		line.points = []
	
	if event.is_action_pressed("ui_accept"):
		astarDebug.visible = !astarDebug.visible
