extends TileMap
class_name AstarTileMap

const DIRECTIONS = [Vector2.RIGHT, Vector2.UP, Vector2.LEFT, Vector2.DOWN]

var astar = AStar2D.new()
var obstacles = []
var units = []

func _ready():
	update()

func update():
	create_pathfinding_points()
	var unitNodes = get_tree().get_nodes_in_group("Units")
	for unitNode in unitNodes:
		add_unit(unitNode)
	var obstacleNodes = get_tree().get_nodes_in_group("Obstacles")
	for obstacleNode in obstacleNodes:
		add_obstacle(obstacleNode)

func create_pathfinding_points():
	astar.clear()
	var used_cell_positions = get_used_cell_global_positions()
	for cell_position in used_cell_positions:
		astar.add_point(get_point(cell_position), cell_position)
	
	for cell_position in used_cell_positions:
		connect_cardinals(cell_position)

func add_obstacle(obstacle):
	obstacles.append(obstacle)
	if not obstacle.is_connected("tree_exiting", self, "remove_obstacle"):
		obstacle.connect("tree_exiting", self, "remove_obstacle", [obstacle])

func remove_obstacle(obstacle):
	obstacles.erase(obstacle)

func add_unit(unit):
	units.append(unit)
	if not unit.is_connected("tree_exiting", self, "remove_unit"):
		unit.connect("tree_exiting", self, "remove_unit", [unit])

func remove_unit(unit):
	units.erase(unit)

func position_has_obstacle(obstacle_position, ignore_obstacle_position = null):
	if obstacle_position == ignore_obstacle_position: return false
	for obstacle in obstacles:
		if obstacle.global_position == obstacle_position: return true
	return false

func position_has_unit(unit_position, ignore_unit_position = null):
	if unit_position == ignore_unit_position: return false
	for unit in units:
		if unit.global_position == unit_position: return true
	return false

func get_astar_path_avoiding_obstacles_and_units(start_position, end_position, exception_units = [], max_distance = -1):
	set_obstacles_points_disabled(true)
	set_unit_points_disabled(true, exception_units)
	var astar_path = astar.get_point_path(get_point(start_position), get_point(end_position))
	set_obstacles_points_disabled(false)
	set_unit_points_disabled(false)
	return set_path_length(astar_path, max_distance)

func get_astar_path_avoiding_obstacles(start_position, end_position, max_distance = -1):
	set_obstacles_points_disabled(true)
	var potential_path_points = astar.get_point_path(get_point(start_position), get_point(end_position))
	set_obstacles_points_disabled(false)
	var astar_path = stop_path_at_unit(potential_path_points)
	return set_path_length(astar_path, max_distance)

func stop_path_at_unit(potential_path_points):
	for i in range(1, potential_path_points.size()):
		var point = potential_path_points[i]
		if position_has_unit(point):
			potential_path_points.resize(i)
			break
	return potential_path_points

func get_astar_path(start_position, end_position, max_distance = -1):
	var astar_path = astar.get_point_path(get_point(start_position), get_point(end_position))
	return set_path_length(astar_path, max_distance)

func set_path_length(point_path, max_distance):
	if max_distance < 0: return point_path
	point_path.resize(min(point_path.size(), max_distance))
	return point_path

func set_obstacles_points_disabled(value: bool):
	for obstacle in obstacles:
		astar.set_point_disabled(get_point(obstacle.global_position), value)

func set_unit_points_disabled(value: bool, exception_units: Array = []):
	for unit in units:
		if unit in exception_units or unit.owner in exception_units:
			continue
		astar.set_point_disabled(get_point(unit.global_position), value)

func get_floodfill_positions(start_position, min_range, max_range, skip_obstacles = true, skip_units = true, return_center = false):
	var floodfill_positions = []
	var checking_positions = [start_position]
	
	while not checking_positions.empty():
		var current_position = checking_positions.pop_back()
		if skip_obstacles and position_has_obstacle(current_position, start_position): continue
		if skip_units and position_has_unit(current_position, start_position): continue
		if current_position in floodfill_positions: continue
		
		var current_point = get_point(current_position)
		if not astar.has_point(current_point): continue
		if astar.is_point_disabled(current_point): continue
		
		var distance = (current_position - start_position)
		var grid_distance = get_grid_distance(distance)
		if grid_distance > max_range: continue
		
		floodfill_positions.append(current_position)
		
		for direction in DIRECTIONS:
			var new_position = current_position + map_to_world(direction)
			if skip_obstacles and position_has_obstacle(new_position): continue
			if skip_units and position_has_unit(new_position): continue
			if new_position in floodfill_positions: continue
			
			var new_point = get_point(new_position)
			if not astar.has_point(new_point): continue
			if astar.is_point_disabled(new_point): continue
			
			checking_positions.append(new_position)
	if not return_center:
		floodfill_positions.erase(start_position)
	
	var floodfill_positions_size = floodfill_positions.size()
	for i in floodfill_positions_size:
		var floodfill_position = floodfill_positions[floodfill_positions_size-i-1] # Loop through the positions backwards vvv
		var distance = (floodfill_position - start_position)
		var grid_distance = get_grid_distance(distance)
		if grid_distance < min_range:
			floodfill_positions.erase(floodfill_position) # Since we are modifying the array here
	
	return floodfill_positions

func path_directions(path):
	# Convert a path into directional vectors whose sum would be path[length-1]
	var directions = []
	for p in range(1, path.size()):
		directions.append(path[p] - path[p - 1])
	return directions

func get_point(point_position):
	# Cantor pairing function
	var a := int(point_position.x)
	var b := int(point_position.y)
	return (a + b) * (a + b + 1) / 2 + b

func has_point(point_position):
	var point_id = get_point(point_position)
	return astar.has_point(point_id)

func get_used_cell_global_positions():
	var cells = get_used_cells()
	var cell_positions = []
	for cell in cells:
		var cell_position = global_position + map_to_world(cell)
		cell_positions.append(cell_position)
	return cell_positions

func connect_cardinals(point_position):
	var center = get_point(point_position)
	for direction in DIRECTIONS:
		var cardinal_point = get_point(point_position + map_to_world(direction))
		if cardinal_point != center and astar.has_point(cardinal_point):
			astar.connect_points(center, cardinal_point, true)

func get_grid_distance(distance):
	var vec = world_to_map(distance).abs().floor()
	return vec.x + vec.y
