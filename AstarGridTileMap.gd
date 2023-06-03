extends TileMap
class_name AstarGridTileMap

## The [AStarGrid2D] diagonal mode to use for the pathfinding.
@export_enum("NEVER", "ALWAYS", "ONLY IF NO OBSTACLES", "AT LEAST ONE WALKABLE") var diagonals : String = "NEVER"

var astar : AStarGrid2D = AStarGrid2D.new()
var _obstacles : Array[Node2D] = []
var _units : Array[Node2D] = []

func _ready() -> void :
	var unitNodes : Array[Node] = get_tree().get_nodes_in_group("Units")
	for unitNode in unitNodes:
		_add_unit(unitNode)
	var obstacleNodes : Array[Node] = get_tree().get_nodes_in_group("Obstacles")
	for obstacleNode in obstacleNodes:
		_add_obstacle(obstacleNode)
	_update()

func _update() -> void :
	astar.clear()
	astar.cell_size = tile_set.tile_size
	var cell = get_used_cells(0)[0]
	astar.size = get_used_rect().size + Vector2i(cell.x, cell.y)
	match diagonals :
		"NEVER" : astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
		"ALWAYS" : astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
		"ONLY IF NO OBSTACLES" : astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		"AT LEAST ONE WALKABLE" : astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_AT_LEAST_ONE_WALKABLE
		# MAX doesn't work for some reason
#		"MAX" : astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_MAX
	astar.update()
	
	var used_cells = get_used_cells(0)
	for i in tile_set.tile_size.x :
		for e in tile_set.tile_size.y :
			var point = Vector2i(i, e)
			if used_cells.has(point) :
				astar.set_point_solid(point, false)
			elif astar.is_in_boundsv(point) : astar.set_point_solid(point, true)

## Returns the local position from the provided point. Use [method get_point_map_position] to get map position instead.
func get_point_local_position(local_position : Vector2) -> Vector2 :
	var map_position : Vector2 = local_to_map(local_position)
	return local_to_map(astar.get_point_position(map_position))

## Returns the map position from the provided point. Use [method get_point_local_position] to get local position instead.
func get_point_map_position(local_position : Vector2) -> Vector2 :
	var map_position : Vector2 = local_to_map(local_position)
	return astar.get_point_position(map_position)

func _add_obstacle(obstacle: Object) -> void :
	_obstacles.append(obstacle)
	if not obstacle.tree_exiting.is_connected(_remove_obstacle) :
		assert(obstacle.tree_exiting.connect(_remove_obstacle.bind(obstacle)) == OK,
		str(obstacle) + ": failed connect() function")

func _add_unit(unit: Object) -> void :
	_units.append(unit)
	if not unit.tree_exiting.is_connected(_remove_unit) :
		assert(unit.tree_exiting.connect(_remove_unit.bind(unit)) == OK,
		str(unit) + ": failed connect() function")

func _remove_obstacle(obstacle: Object) -> void :
	if _obstacles.has(obstacle) : _obstacles.erase(obstacle)

func _remove_unit(unit: Object) -> void :
	if _units.has(unit) : _units.erase(unit)

## Checks if position has any obstacles. For units, use [method position_has_unit] or use [method position_has_anything] to check for both.
func position_has_obstacle(obstacle_position : Vector2, ignore_obstacle_position = null) -> bool :
	if obstacle_position == ignore_obstacle_position : return false
	for obstacle in _obstacles :
		if get_point_from_local_position(obstacle.global_position) == obstacle_position : return true
	return false

## Checks if position has any units. For obstacles, use [method position_has_obstacle] or use [method position_has_anything] to check for both.
func position_has_unit(unit_position : Vector2, ignore_unit_position = null) -> bool :
	if unit_position == ignore_unit_position : return false
	for unit in _units :
		if get_point_from_local_position(unit.global_position) == unit_position : return true
	return false

## Checks if position has either obstacles or units. For individual checks, use [method position_has_unit] or [method position_has_obstacle].
func position_has_anything(_position : Vector2) -> bool :
	var has_obstacle : bool = false
	var has_unit : bool = false
	
	for obstacle in _obstacles :
		if get_point_from_local_position(obstacle.global_position) == _position : has_obstacle = true
	for unit in _units :
		if get_point_from_local_position(unit.global_position) == _position : has_unit = true
	
	if has_obstacle and has_unit : return true
	else : return false

func get_astar_path(start_position : Vector2, end_position : Vector2) -> PackedVector2Array :
	return astar.get_point_path(start_position, end_position)

func get_astar_path_avoiding_obstacles(start_position: Vector2i, end_position: Vector2i, max_distance := -1) -> Array:
	_set_obstacles_points_disabled(true)
	var path_points : PackedVector2Array = astar.get_point_path(start_position, end_position)
	_set_obstacles_points_disabled(false)
	return AstarHelper.set_path_length(path_points, max_distance)

func get_astar_path_avoiding_obstacles_and_units(start_position: Vector2i, end_position: Vector2i, exception_units : Array[Node] = [], max_distance : int = -1) -> Array:
	_set_obstacles_points_disabled(true)
	_set_unit_points_disabled(true, exception_units)
	var astar_path : PackedVector2Array = astar.get_point_path(start_position, end_position)
	_set_obstacles_points_disabled(false)
	_set_unit_points_disabled(false)
	return AstarHelper.set_path_length(astar_path, max_distance)

func _set_obstacles_points_disabled(value: bool) -> void :
	for obstacle in _obstacles :
		astar.set_point_solid(local_to_map(obstacle.global_position), value)

func _set_unit_points_disabled(value: bool, exception_units: Array = []) -> void :
	for unit in _units :
		if unit in exception_units or unit.owner in exception_units :
			continue
		astar.set_point_solid(local_to_map(unit.global_position), value)

func get_point_from_local_position(_position : Vector2) -> Vector2 :
	return map_to_local(local_to_map(_position))

func stop_path_at_unit(potential_path_points: Array) -> Array :
	for i in range(1, potential_path_points.size()) :
		var point : Vector2i = potential_path_points[i]
		if position_has_unit(point):
			potential_path_points.resize(i)
			break
	return potential_path_points

#func get_floodfill_positions(start_position: Vector2i, min_range: int, max_range: int, skip_obstacles := true, skip_units := true, return_center := false) -> Array :
#	var floodfill_positions := []
#	var checking_positions := [start_position]
#
#	while not checking_positions.is_empty() :
#		var current_position : Vector2i = checking_positions.pop_back()
#		if skip_obstacles and position_has_obstacle(current_position, start_position): continue
#		if skip_units and position_has_unit(current_position, start_position): continue
#		if current_position in floodfill_positions: continue
#
#		var current_point := get_point_from_local_position(current_position)
#		if not astar.has_point(current_point): continue
#		if astar.is_point_disabled(current_point): continue
#
#		var distance := (current_position - start_position)
#		var grid_distance := get_grid_distance(distance)
#		if grid_distance > max_range: continue
#
#		floodfill_positions.append(current_position)
#
#		for direction in DIRECTIONS:
#			var new_position : Vector2i = current_position + Vector2i(map_to_local(direction))
#			if skip_obstacles and position_has_obstacle(new_position) : continue
#			if skip_units and position_has_unit(new_position) : continue
#			if new_position in floodfill_positions : continue
#
#			var new_point : int = get_point_from_local_position(new_position)
#			if not astar.has_point(new_point) : continue
#			if astar.is_point_disabled(new_point) : continue
#
#			checking_positions.append(new_position)
#	if not return_center:
#		floodfill_positions.erase(start_position)
#
#	var floodfill_positions_size := floodfill_positions.size()
#	for i in floodfill_positions_size:
#		var floodfill_position : Vector2i = floodfill_positions[floodfill_positions_size-i-1] # Loop through the positions backwards vvv
#		var distance = (floodfill_position - start_position)
#		var grid_distance := get_grid_distance(distance)
#		if grid_distance < min_range:
#			floodfill_positions.erase(floodfill_position) # Since we are modifying the array here
#
#	return floodfill_positions
#
#func get_grid_distance(distance: Vector2i) -> float :
#	var vec : Vector2i = floor(local_to_map(distance).abs())
#	return vec.x + vec.y
