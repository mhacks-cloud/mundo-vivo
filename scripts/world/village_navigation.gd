class_name VillageNavigation
extends RefCounted

const CELL := 0.45
const REGION := Rect2i(-70, -74, 144, 147)
var grid := AStarGrid2D.new()
var revision := 0
var obstacles: Array[Rect2] = []

func rebuild(root: Node3D, bridge_open: bool) -> void:
	grid.clear()
	obstacles.clear()
	grid.region = REGION
	grid.cell_size = Vector2.ONE * CELL
	grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	grid.update()
	for z in range(REGION.position.y, REGION.end.y):
		if absf(z * CELL - 2.0) < 0.87 or (bridge_open and absf(z * CELL + 12.0) < 0.87):
			continue
		grid.fill_solid_region(Rect2i(Vector2i(22, z), Vector2i(15, 1)))
	for body in root.find_children("*", "StaticBody3D", true, false):
		if (body.collision_layer & 1) == 0:
			continue
		for hit in body.get_children():
			if not hit is CollisionShape3D or hit.disabled or not hit.shape is BoxShape3D:
				continue
			var center: Vector3 = hit.global_position
			var local: Vector3 = hit.shape.size * 0.5
			var orientation: Basis = hit.global_basis
			var half := orientation.x.abs() * local.x + orientation.y.abs() * local.y + orientation.z.abs() * local.z
			_block(Vector2(center.x, center.z), Vector2(half.x, half.z) + Vector2.ONE * 0.36)
	revision += 1

func _block(center: Vector2, half: Vector2) -> void:
	obstacles.append(Rect2(center - half, half * 2.0))
	var begin := Vector2i(((center - half) / CELL).ceil())
	var end := Vector2i(((center + half) / CELL).floor()) + Vector2i.ONE
	var cut := Rect2i(begin, end - begin).intersection(REGION)
	if cut.has_area():
		grid.fill_solid_region(cut)

func find(origin: Vector3, destination: Vector3) -> PackedVector3Array:
	var path := PackedVector3Array()
	var from := _nearest(Vector2(origin.x, origin.z))
	var to := _nearest(Vector2(destination.x, destination.z))
	if not _free(from) or not _free(to):
		return path
	var nodes := grid.get_id_path(from, to)
	if nodes.is_empty():
		return path
	var anchor := Vector2(origin.x, origin.z)
	if not _free(Vector2i((anchor / CELL).round())):
		anchor = grid.get_point_position(from)
		path.append(Vector3(anchor.x, origin.y, anchor.y))
	for i in range(1, nodes.size()):
		var point := grid.get_point_position(nodes[i])
		if i > 1 and not _clear(anchor, point):
			var previous := grid.get_point_position(nodes[i - 1])
			path.append(Vector3(previous.x, origin.y, previous.y))
			anchor = previous
	var end := Vector2(destination.x, destination.z)
	if not _clear(anchor, end):
		end = grid.get_point_position(to)
	path.append(Vector3(end.x, origin.y, end.y))
	return path

func _clear(a: Vector2, b: Vector2) -> bool:
	var count := maxi(1, ceili(a.distance_to(b) / (CELL * 0.30)))
	for i in range(1, count + 1):
		var point := a.lerp(b, float(i) / count)
		if not _free(Vector2i((point / CELL).round())):
			return false
		for obstacle in obstacles:
			if not obstacle.has_point(a) and obstacle.has_point(point):
				return false
	return true

func _nearest(point: Vector2) -> Vector2i:
	var cell := Vector2i((point / CELL).round())
	if _free(cell):
		return cell
	var best := cell
	var nearest := INF
	for y in range(-3, 4):
		for x in range(-3, 4):
			var candidate := cell + Vector2i(x, y)
			if _free(candidate):
				var cost := grid.get_point_position(candidate).distance_squared_to(point)
				if cost < nearest:
					nearest = cost
					best = candidate
	return best

func _free(cell: Vector2i) -> bool:
	return grid.is_in_boundsv(cell) and not grid.is_point_solid(cell)
