extends TileMap
class_name AstarTileMap

const DIRECTIONS : Array[Vector2i] = [Vector2i.RIGHT, Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN]
const PAIRING_LIMIT : int = int(pow(2, 30))
enum pairing_methods {
	CANTOR_UNSIGNED,	# positive values only
	CANTOR_SIGNED,		# both positive and negative values	
	SZUDZIK_UNSIGNED,	# more efficient than cantor
	SZUDZIK_SIGNED,		# both positive and negative values
	SZUDZIK_IMPROVED,	# improved version (best option)
}

@export_enum("CANTOR_UNSIGNED","CANTOR_SIGNED","SZUDZIK_UNSIGNED","SZUDZIK_SIGNED","SZUDZIK_IMPROVED")
var current_pairing_method : int = pairing_methods.SZUDZIK_IMPROVED
@export var diagonals : bool = false
@export var remove_units : bool = false
@export var remove_obstacles : bool = false
@export var tilemap_layer : int = 0

var astar : AStar2D = AStar2D.new()
var obstacles : Array[Node2D] = []
var units : Array[Node2D] = []

func _ready() -> void :
	update()

func update() -> void :
	var unitNodes : Array[Node] = get_tree().get_nodes_in_group("Units")
	for unitNode in unitNodes:
		add_unit(unitNode)
	var obstacleNodes : Array[Node] = get_tree().get_nodes_in_group("Obstacles")
	for obstacleNode in obstacleNodes:
		add_obstacle(obstacleNode)
	create_pathfinding_points()

func create_pathfinding_points() -> void :
	astar.clear()
	var used_cell_positions : Array[Vector2i] = get_used_cells(tilemap_layer)
	for i in used_cell_positions.size() :
		var cell_position : Vector2i = used_cell_positions[i]
		if remove_obstacles :
			if position_has_obstacle(cell_position) : continue
		if remove_units :
			if position_has_unit(cell_position) : continue
		astar.add_point(i, cell_position)

	for i in used_cell_positions.size() : 
		if astar.has_point(i) : connect_cardinals(i)
	
	for i in astar.get_point_ids() :
		astar.set_point_position(i, map_to_local(astar.get_point_position(i)))

func add_obstacle(obstacle: Object) -> void :
	obstacles.append(obstacle)
	if not obstacle.tree_exiting.is_connected(remove_obstacle) :
		assert(obstacle.tree_exiting.connect(remove_obstacle.bind(obstacle)) == OK,
		str(obstacle) + ": failed connect() function")

func add_unit(unit: Object) -> void :
	units.append(unit)
	if not unit.tree_exiting.is_connected(remove_unit) :
		assert(unit.tree_exiting.connect(remove_unit.bind(unit)) == OK,
		str(unit) + ": failed connect() function")

func remove_obstacle(obstacle: Object) -> void :
	if obstacles.has(obstacle) : obstacles.erase(obstacle)

func remove_unit(unit: Object) -> void :
	if units.has(unit) : units.erase(unit)

func position_has_obstacle(obstacle_position : Vector2i, ignore_obstacle_position = null) -> bool :
	if obstacle_position == ignore_obstacle_position : return false
	for obstacle in obstacles :
		if local_to_map(obstacle.global_position) == obstacle_position : return true
	return false

func position_has_unit(unit_position : Vector2i, ignore_unit_position = null) -> bool :
	if unit_position == ignore_unit_position : return false
	for unit in units :
		if local_to_map(unit.global_position) == unit_position : return true
	return false

func get_astar_path(start_position : Vector2i, end_position : Vector2i, max_distance : int = -1) -> Array :
	var astar_path : PackedVector2Array = astar.get_point_path(get_point_from_position(start_position), get_point_from_position(end_position))
	return set_path_length(astar_path, max_distance)

func get_astar_path_avoiding_obstacles(start_position: Vector2i, end_position: Vector2i, max_distance := -1) -> Array:
	set_obstacles_points_disabled(true)
	var path_points := astar.get_point_path(get_point_from_position(start_position), get_point_from_position(end_position))
	set_obstacles_points_disabled(false)
	return set_path_length(path_points, max_distance)

func get_astar_path_avoiding_obstacles_and_units(start_position: Vector2i, end_position: Vector2i, exception_units : Array[Node] = [], max_distance : int = -1) -> Array:
	set_obstacles_points_disabled(true)
	set_unit_points_disabled(true, exception_units)
	var astar_path : PackedVector2Array = astar.get_point_path(get_point_from_position(start_position), get_point_from_position(end_position))
	set_obstacles_points_disabled(false)
	set_unit_points_disabled(false)
	return set_path_length(astar_path, max_distance)

func stop_path_at_unit(potential_path_points: Array) -> Array :
	for i in range(1, potential_path_points.size()) :
		var point : Vector2i = potential_path_points[i]
		if position_has_unit(point):
			potential_path_points.resize(i)
			break
	return potential_path_points

func set_path_length(point_path: Array, max_distance: int) -> Array :
	if max_distance < 0: return point_path
	var new_size : int = int(min(point_path.size(), max_distance))
	point_path.resize(new_size)
	return point_path

func set_obstacles_points_disabled(value: bool) -> void :
#	for obstacle in obstacles :
#		astar.set_point_disabled(get_point_from_position(obstacle.global_position), value)
	for i in astar.get_point_ids() :
		if position_has_obstacle(astar.get_point_position(i)) :
			astar.set_point_disabled(i, value)

func set_unit_points_disabled(value: bool, exception_units: Array = []) -> void :
	for unit in units :
		if unit in exception_units or unit.owner in exception_units :
			continue
		astar.set_point_disabled(get_point_from_position(unit.global_position), value)

func get_floodfill_positions(start_position: Vector2i, min_range: int, max_range: int, skip_obstacles := true, skip_units := true, return_center := false) -> Array :
	var floodfill_positions := []
	var checking_positions := [start_position]

	while not checking_positions.is_empty() :
		var current_position : Vector2i = checking_positions.pop_back()
		if skip_obstacles and position_has_obstacle(current_position, start_position): continue
		if skip_units and position_has_unit(current_position, start_position): continue
		if current_position in floodfill_positions: continue

		var current_point := get_point(current_position)
		if not astar.has_point(current_point): continue
		if astar.is_point_disabled(current_point): continue

		var distance := (current_position - start_position)
		var grid_distance := get_grid_distance(distance)
		if grid_distance > max_range: continue

		floodfill_positions.append(current_position)

		for direction in DIRECTIONS:
			var new_position : Vector2i = current_position + Vector2i(map_to_local(direction))
			if skip_obstacles and position_has_obstacle(new_position) : continue
			if skip_units and position_has_unit(new_position) : continue
			if new_position in floodfill_positions : continue

			var new_point : int = get_point(new_position)
			if not astar.has_point(new_point) : continue
			if astar.is_point_disabled(new_point) : continue

			checking_positions.append(new_position)
	if not return_center:
		floodfill_positions.erase(start_position)

	var floodfill_positions_size := floodfill_positions.size()
	for i in floodfill_positions_size:
		var floodfill_position : Vector2i = floodfill_positions[floodfill_positions_size-i-1] # Loop through the positions backwards vvv
		var distance = (floodfill_position - start_position)
		var grid_distance := get_grid_distance(distance)
		if grid_distance < min_range:
			floodfill_positions.erase(floodfill_position) # Since we are modifying the array here

	return floodfill_positions

func path_directions(path) -> Array :
	# Convert a path into directional vectors whose sum would be path[length-1]
	var directions = []
	for p in range(1, path.size()):
		directions.append(path[p] - path[p - 1])
	return directions

func get_point(point_position: Vector2i) -> int :
	var a := int(point_position.x)
	var b := int(point_position.y)
	match current_pairing_method:
		pairing_methods.CANTOR_UNSIGNED:
			assert(a >= 0 and b >= 0, "Board: pairing method has failed. Choose method that supports negative values.")
			return AstarHelper.cantor_pair(a, b)
		pairing_methods.SZUDZIK_UNSIGNED:
			assert(a >= 0 and b >= 0, "Board: pairing method has failed. Choose method that supports negative values.")			
			return AstarHelper.szudzik_pair(a, b)
		pairing_methods.CANTOR_SIGNED:
			return AstarHelper.cantor_pair_signed(a, b)
		pairing_methods.SZUDZIK_SIGNED:
			return AstarHelper.szudzik_pair_signed(a, b)
		pairing_methods.SZUDZIK_IMPROVED:
			return AstarHelper.szudzik_pair_improved(a, b)
	return AstarHelper.szudzik_pair_improved(a, b)

func get_point_from_position(_position : Vector2i) -> int :
	return astar.get_closest_point(_position, true)

func get_closest_point_positon(_position : Vector2i) -> Vector2i :
	return astar.get_point_position(astar.get_closest_point(_position))

func get_closest_point_in_range(_position : Vector2) -> int :
	var a = astar.get_closest_point(_position)
	var b = astar.get_point_position(a)
	if _position.distance_to(b) == 0 : return a
	else : return 0

func has_point(point_position: Vector2i) -> bool :
	var point_id : int = get_point_from_position(point_position)
	return astar.has_point(point_id)

func get_used_cell_global_positions() -> Array :
	var cells = get_used_cells(tilemap_layer)
	var cell_positions : Array[Vector2i] = []
	for cell in cells :
		var cell_position : Vector2i = global_position + map_to_local(cell)
		cell_positions.append(cell_position)
	return cell_positions

func connect_cardinals(point : int) -> void :
	var center : int = point
	var directions : Array[Vector2i] = DIRECTIONS.duplicate()
	
	if diagonals :
		var diagonals_array : Array[Vector2i] = [Vector2i(1,1), Vector2i(1,-1)]	# Only two needed for generation
		directions.append_array(diagonals_array)
	
	for direction in directions :
		var cardinal_point : int = get_closest_point_in_range(astar.get_point_position(point) + Vector2(direction))
		if cardinal_point != center and astar.has_point(cardinal_point) and cardinal_point != 0:
			astar.connect_points(center, cardinal_point, true)

func get_grid_distance(distance: Vector2i) -> float :
	var vec : Vector2i = floor(local_to_map(distance).abs())
	return vec.x + vec.y
