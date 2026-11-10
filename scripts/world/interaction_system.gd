class_name InteractionSystem
extends RefCounted

var targets: Array[Dictionary] = []

func register(label: String, position: Vector3, action: Callable, radius := 2.4) -> void:
	targets.append({"label": label, "position": position, "action": action, "radius": radius})

func closest(origin: Vector3) -> Dictionary:
	var nearest: Dictionary = {}
	var distance := INF
	for target in targets:
		var offset: Vector3 = target.position - origin
		var range_squared: float = target.radius * target.radius
		var squared := offset.length_squared()
		if squared <= range_squared and squared < distance:
			nearest = target
			distance = squared
	return nearest

func interact(origin: Vector3) -> bool:
	var target := closest(origin)
	if target.is_empty():
		return false
	target.action.call()
	return true
