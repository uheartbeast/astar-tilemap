extends Control

var astar
var board setget set_board

func set_board(value):
	board = value
	if board is AstarTileMap:
		astar = board.astar

func _physics_process(delta):
	update()

func position_has_obstacle(obstacle_position):
	return board.position_has_obstacle(obstacle_position) or board.position_has_unit(obstacle_position)

func _draw():
	if not astar is AStar2D: return
	var offset = board.cell_size/2
	for point in astar.get_points():
		if astar.is_point_disabled(point): continue
		var point_position = astar.get_point_position(point)
		if position_has_obstacle(point_position): continue
		
		draw_circle(point_position+offset, 4, Color.white)
		
		var point_connections = astar.get_point_connections(point)
		var connected_positions = []
		for connected_point in point_connections:
			if astar.is_point_disabled(connected_point): continue
			var connected_point_position = astar.get_point_position(connected_point)
			if position_has_obstacle(connected_point_position): continue
			connected_positions.append(connected_point_position)
			
		for connected_position in connected_positions:
			draw_line(point_position+offset, connected_position+offset, Color.white, 2)
