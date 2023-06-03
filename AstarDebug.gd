extends Control

@export var board : AstarGridTileMap
@onready var astar : AStarGrid2D = board.astar if board else null

func _draw():
	if not astar is AStarGrid2D : return
	var offset : Vector2 = board.tile_set.tile_size/2
	var cell_size = board.tile_set.tile_size
	for i in cell_size.x :
		for e in cell_size.y :
			var point = Vector2i(i, e)
			if astar.is_in_boundsv(point) :
				if not astar.is_point_solid(point) and not board.position_has_obstacle(board.map_to_local(point)) :
					var point_position = astar.get_point_position(point)
					draw_circle(point_position + offset, 4, Color.WHITE)
#	for cell in board.get_used_cells(0):
#		if astar.is_point_solid(cell) : continue
#		var point_position = astar.get_point_position(cell)
##		if position_has_obstacle(point_position) : continue
#
#		draw_circle(point_position + offset, 4, Color.WHITE)

#		var point_connections = astar.connec(cell)
#		var connected_positions = []
#		for connected_point in point_connections:
#			if astar.is_point_disabled(connected_point): continue
#			var connected_point_position = astar.get_point_position(connected_point)
#			if position_has_obstacle(connected_point_position): continue
#			connected_positions.append(connected_point_position)
