extends Node
class_name AstarHelper

static func cantor_pair(a : int, b : int) -> int :
	var result : float = 0.5 * (a + b) * (a + b + 1) + b
	return int(result)

static func cantor_pair_signed(a:int, b:int) -> int :
	if a >= 0 :
		a = a * 2
	else :
		a = (a * -2) - 1
	if b >= 0 :
		b = b * 2
	else :
		b = (b * -2) - 1
	return cantor_pair(a, b)

static func szudzik_pair(a:int, b:int) -> int :
	if a >= b :
		return (a * a) + a + b
	else :
		return (b * b) + a

static func szudzik_pair_signed(a: int, b: int) -> int :
	if a >= 0 :
		a = a * 2
	else :
		a = (a * -2) - 1
	if b >= 0 :
		b = b * 2
	else :
		b = (b * -2) - 1
	return int(szudzik_pair(a, b))

static func szudzik_pair_improved(x:int, y:int) -> int :
	var a : int
	var b : int
	if x >= 0 :
		a = x * 2
	else :
		a = (x * -2) - 1
	if y >= 0 :
		b = y * 2
	else :
		b = (y * -2) - 1
	var c : int = szudzik_pair(a,b)
	if a >= 0 and b < 0 or b >= 0 and a < 0 :
		return -c - 1
	return c

static func set_path_length(point_path: Array, max_distance: int) -> Array :
	if max_distance < 0: return point_path
	var new_size : int = int(min(point_path.size(), max_distance))
	point_path.resize(new_size)
	return point_path

static func path_directions(path) -> Array :
	# Convert a path into directional vectors whose sum would be path[length-1]
	var directions = []
	for p in range(1, path.size()):
		directions.append(path[p] - path[p - 1])
	return directions
