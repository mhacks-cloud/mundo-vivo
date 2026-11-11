class_name Homestead
extends RefCounted

signal changed
const CELL := 1.5
const SIDE := 5
const PLOTS := {
	"sul-01": {"name": "Horta Velha", "at": Vector2(-10.55, 14.60), "price": 22},
	"sul-02": {"name": "Prado da Ponte", "at": Vector2(-1.25, 14.60), "price": 29}
}
const PIECES := {
	"foundation": {"name": "Fundação de pedra", "layer": "base", "cost": {"stone": 1}},
	"floor": {"name": "Piso de tábuas", "layer": "floor", "cost": {"wood": 1}},
	"wall": {"name": "Parede enxaimel", "layer": "edge", "cost": {"wood": 1}},
	"door": {"name": "Porta em arco", "layer": "edge", "cost": {"wood": 2}},
	"window": {"name": "Janela com veneziana", "layer": "edge", "cost": {"wood": 2}},
	"window_carved": {"name": "Janela entalhada", "layer": "edge", "cost": {"wood": 1, "joinery": 1}},
	"door_oak": {"name": "Porta de carvalho", "layer": "edge", "cost": {"wood": 1, "joinery": 1}},
	"roof": {"name": "Telhado de telha", "layer": "roof", "cost": {"wood": 1}},
	"roof_slate": {"name": "Telhado verde", "layer": "roof", "cost": {"wood": 1, "stone": 1}},
	"fence": {"name": "Cerca de madeira", "layer": "edge", "cost": {"wood": 1}},
	"chair": {"name": "Banco de carvalho", "layer": "furniture", "cost": {"chair": 1}},
	"garden": {"name": "Canteiro", "layer": "garden", "cost": {"wood": 1}},
	"flowers": {"name": "Vaso de flores", "layer": "garden", "cost": {"stone": 1}}
}
const DIRECTIONS := [Vector2i(0,-1), Vector2i(1,0), Vector2i(0,1), Vector2i(-1,0)]
var owners: Dictionary = {}
var pieces: Array[Dictionary] = []

static func within_residential(x: float, z: float) -> bool:
	for id in PLOTS:
		var at: Vector2 = PLOTS[id].at
		if Rect2(at - Vector2.ONE * 0.65, Vector2.ONE * (SIDE * CELL + 1.3)).has_point(Vector2(x, z)):
			return true
	return false

func owned(actor: String) -> String:
	for id in PLOTS:
		if owners.get(id, "") == actor:
			return id
	return ""

func can_claim(id: String, actor: String) -> bool:
	return not actor.is_empty() and PLOTS.has(id) and not owners.has(id) and owned(actor).is_empty()

func claim(id: String, actor: String) -> bool:
	if not can_claim(id, actor):
		return false
	owners[id] = actor
	changed.emit()
	return true

static func center(id: String, cell: Vector2i) -> Vector3:
	var at: Vector2 = PLOTS[id].at + (Vector2(cell) + Vector2.ONE * 0.5) * CELL
	return Vector3(at.x, 0.03, at.y)

static func cell_at(id: String, p: Vector3) -> Vector2i:
	var at: Vector2 = PLOTS[id].at
	return Vector2i(((Vector2(p.x, p.z) - at) / CELL).floor())

static func in_bounds(cell: Vector2i) -> bool:
	return Rect2i(0, 0, SIDE, SIDE).has_point(cell)

func layer_at(id: String, cell: Vector2i, layer: String) -> bool:
	for piece in pieces:
		if piece.plot == id and piece.cell == cell and PIECES[piece.kind].layer == layer:
			return true
	return false

static func edge_key(cell: Vector2i, direction: int) -> String:
	var edge := cell
	if direction == 2:
		edge.y += 1
	if direction == 1:
		edge.x += 1
	return "%d:%d:%d" % [direction % 2, edge.x, edge.y]

func check(actor: String, id: String, kind: String, cell: Vector2i, direction: int) -> String:
	if not PLOTS.has(id) or actor.is_empty() or owners.get(id, "") != actor:
		return "Este terreno exige permissão do proprietário."
	if not PIECES.has(kind) or direction < 0 or direction > 3 or not in_bounds(cell):
		return "Posicione dentro do seu terreno."
	var layer: String = PIECES[kind].layer
	var base := layer_at(id, cell, "base")
	var floor_exists := layer_at(id, cell, "floor")
	if layer != "edge" and layer_at(id, cell, layer):
		return "Já há uma peça nesse encaixe."
	if layer == "edge":
		var edge := edge_key(cell, direction)
		for piece in pieces:
			if piece.plot == id and PIECES[piece.kind].layer == "edge" and edge_key(piece.cell, piece.dir) == edge:
				return "Esta borda já está ocupada."
		var neighbor: Vector2i = cell + DIRECTIONS[direction]
		if kind != "fence" and not base and not layer_at(id, neighbor, "base"):
			return "A parede, porta ou janela precisa de fundação."
	if layer in ["floor", "roof"] and not base:
		return "Instale uma fundação primeiro."
	if layer == "furniture" and not floor_exists:
		return "A mobília precisa de piso."
	if (layer == "garden" and base) or (layer == "base" and layer_at(id, cell, "garden")):
		return "O jardim e a fundação precisam de espaços distintos."
	return ""

func install(actor: String, id: String, kind: String, cell: Vector2i, direction: int, bag: LifeInventory) -> String:
	var reason := check(actor, id, kind, cell, direction)
	if not reason.is_empty():
		return reason
	if not bag.spend(PIECES[kind].cost):
		return "Materiais insuficientes."
	pieces.append({"plot": id, "kind": kind, "cell": cell, "dir": direction})
	changed.emit()
	return ""

func starter(actor: String, id: String, bag: LifeInventory) -> String:
	if owned(actor) != id or id.is_empty():
		return "Reivindique um terreno primeiro."
	var plan: Array[Dictionary] = []
	for y in range(1, 3):
		for x in range(1, 3):
			for kind in ["foundation", "floor", "roof"]:
				plan.append({"kind": kind, "cell": Vector2i(x, y), "dir": 0 if x == 1 else 2})
	for edge in [[1, 1, 0, "wall"], [2, 1, 0, "window"], [1, 2, 2, "door"], [2, 2, 2, "window"],
			[1, 1, 3, "wall"], [1, 2, 3, "window"], [2, 1, 1, "wall"], [2, 2, 1, "wall"]]:
		plan.append({"kind": edge[3], "cell": Vector2i(edge[0], edge[1]), "dir": edge[2]})
	var original := pieces.size()
	var costs := {}
	for part in plan:
		var reason := check(actor, id, part.kind, part.cell, part.dir)
		if not reason.is_empty():
			pieces.resize(original)
			return reason
		part.plot = id
		pieces.append(part)
		for item in PIECES[part.kind].cost:
			costs[item] = int(costs.get(item, 0)) + int(PIECES[part.kind].cost[item])
	if not bag.spend(costs):
		pieces.resize(original)
		return "Casa inicial: 20 madeiras e 4 pedras."
	changed.emit()
	return ""

func remove(actor: String, index: int) -> String:
	if not _owns_piece(actor, index):
		return "Peça indisponível."
	var part := pieces[index]
	pieces.remove_at(index)
	var plot: String = part.plot
	var cell: Vector2i = part.cell
	var reason := ""
	match String(PIECES[part.kind].layer):
		"base":
			if layer_at(plot, cell, "floor") or layer_at(plot, cell, "roof"):
				reason = "Remova o piso e o telhado primeiro."
			for edge in pieces:
				if edge.plot != plot or PIECES[edge.kind].layer != "edge" or edge.kind == "fence":
					continue
				var neighbor: Vector2i = edge.cell + DIRECTIONS[edge.dir]
				if (edge.cell == cell or neighbor == cell) and not layer_at(plot, edge.cell, "base") and not layer_at(plot, neighbor, "base"):
					reason = "Uma parede ainda depende desta fundação."
					break
		"floor":
			if layer_at(plot, cell, "furniture"):
				reason = "Retire a mobília primeiro."
	if not reason.is_empty():
		pieces.insert(index, part)
		return reason
	changed.emit()
	return ""

func check_move(actor: String, index: int, cell: Vector2i, direction: int) -> String:
	if not _owns_piece(actor, index) or pieces[index].kind not in ["chair", "flowers"]:
		return "Selecione uma decoração ou mobília."
	var part := pieces[index]
	pieces.remove_at(index)
	var reason := check(actor, part.plot, part.kind, cell, direction)
	pieces.insert(index, part)
	return reason

func move(actor: String, index: int, cell: Vector2i, direction: int) -> String:
	var reason := check_move(actor, index, cell, direction)
	if not reason.is_empty():
		return reason
	var part := pieces[index]
	pieces.remove_at(index)
	part.cell = cell
	part.dir = direction
	pieces.append(part)
	changed.emit()
	return ""

func _owns_piece(actor: String, index: int) -> bool:
	return not actor.is_empty() and index >= 0 and index < pieces.size() and owners.get(pieces[index].plot, "") == actor

func snapshot() -> Dictionary:
	var saved: Array[Dictionary] = []
	for part in pieces:
		saved.append({"plot": part.plot, "kind": part.kind, "cell": [part.cell.x, part.cell.y], "dir": part.dir})
	return {"owners": owners.duplicate(), "pieces": saved}

func restore(data: Variant) -> void:
	owners.clear()
	pieces.clear()
	if data is Dictionary:
		if data.get("owners") is Dictionary:
			for id in PLOTS:
				var owner: Variant = data.owners.get(id)
				if owner is String and not owner.is_empty() and owner.length() <= 40 and owned(owner).is_empty():
					owners[id] = owner
		if data.get("pieces") is Array:
			var pending: Array[Dictionary] = []
			for part in data.pieces.slice(0, 450):
				if not part is Dictionary or not part.get("plot") is String or not part.get("kind") is String or not part.get("cell") is Array or part.cell.size() != 2:
					continue
				var cell := Vector2i(int(LifeCatalog.number(part.cell[0], -1, -1, SIDE)), int(LifeCatalog.number(part.cell[1], -1, -1, SIDE)))
				var dir := int(LifeCatalog.number(part.get("dir"), -1, -1, 4))
				var piece := {"plot": part.plot, "kind": part.kind, "cell": cell, "dir": dir}
				if check(owners.get(part.plot, ""), part.plot, part.kind, cell, dir).is_empty():
					pieces.append(piece)
				else:
					pending.append(piece)
			for part in pending:
				if check(owners.get(part.plot, ""), part.plot, part.kind, part.cell, part.dir).is_empty():
					pieces.append(part)
	changed.emit()
