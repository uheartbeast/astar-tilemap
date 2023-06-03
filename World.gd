extends Node2D

@onready var board : AstarGridTileMap = $Board
@onready var astarDebug = $AstarDebug
@onready var player = $Board/Player
@onready var line : Line2D = $Line

func _input(event):
	if event.is_action_pressed("mouse_left"):
		var cell_size = board.tile_set.tile_size
		var target_cell = board.get_point_local_position(event.position)
		var player_cell = board.get_point_local_position(player.position)
		var path_points = board.get_astar_path_avoiding_obstacles_and_units(player_cell, target_cell)
		for i in path_points.size() :
			path_points[i] = path_points[i] + Vector2(cell_size/2)
		line.points = path_points

	if event.is_action_pressed("mouse_right"):
		line.points = []

	if event.is_action_pressed("ui_accept"):
		astarDebug.visible = !astarDebug.visible
