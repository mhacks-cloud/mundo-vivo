class_name NPCManager
extends RefCounted

var plans: Array[Dictionary] = []
var construction: ConstructionManager

func _init(bridge: ConstructionManager) -> void:
	construction = bridge
	var depot := Vector3(6.18, 0.10, -12.05)
	var site := Vector3(9.03, 0.10, -12.02)
	plans = [
		{"name": "Ivo", "job": "carpinteiro", "worker": true, "palette": "8b653e", "hair": "604332", "hat": 1,
			"route": [depot, Vector3(7.55, 0.10, -12.06), site, Vector3(7.45, 0.10, -11.55)],
			"home": Vector3(6.60, 0.10, -9.65), "exit": [Vector3(6.20, 0.10, -11.65)]},
		{"name": "Mara", "job": "carpinteira", "worker": true, "palette": "97604e", "hair": "493a37", "hat": 2,
			"route": [depot + Vector3(0, 0, 0.50), Vector3(7.55, 0.10, -12.56), site + Vector3(0, 0, -0.43), Vector3(7.10, 0.10, -12.62)],
			"home": Vector3(5.35, 0.10, -10.15), "exit": [Vector3(5.28, 0.10, -11.65)]},
		{"name": "Lina", "job": "estalajadeira", "worker": false, "palette": "875c8b", "hair": "7b503a", "hat": 0,
			"route": [Vector3(-6.72, 0.10, -3.79), Vector3(-4.85, 0.10, -2.45), Vector3(-3.0, 0.10, -0.25), Vector3(-4.65, 0.10, 0.8), Vector3(-6.62, 0.10, -0.26)],
			"home": Vector3(-6.72, 0.10, -3.76), "exit": []},
		{"name": "Baltasar", "job": "ferreiro", "worker": false, "palette": "537783", "hair": "53433b", "hat": 1,
			"route": [Vector3(-11.21, 0.10, 5.04), Vector3(-8.9, 0.10, 5.35), Vector3(-6.25, 0.10, 3.19), Vector3(-6.44, 0.10, 1.35), Vector3(-7.0, 0.10, 0.71), Vector3(-11.80, 0.10, 0.31), Vector3(-11.88, 0.10, 2.39)],
			"home": Vector3(-8.74, 0.10, 5.12), "exit": []},
		{"name": "Teresa", "job": "hortelã", "worker": false, "palette": "637e4b", "hair": "a1744e", "hat": 2,
			"route": [Vector3(-10.22, 0.10, 11.27), Vector3(-12.12, 0.10, 12.64), Vector3(-12.0, 0.10, 9.6), Vector3(-10.17, 0.10, 8.7), Vector3(-8.87, 0.10, 7.1)],
			"home": Vector3(-7.04, 0.10, 13.87), "exit": [Vector3(-9.48, 0.10, 13.85)]},
		{"name": "Nilo", "job": "viajante", "worker": false, "palette": "467c79", "hair": "8e6947", "hat": 0,
			"route": [Vector3(2.85, 0.10, 2), Vector3(9.2, 0.10, 2), Vector3(16.7, 0.10, 2), Vector3(20.9, 0.10, 1.93), Vector3(21.1, 0.10, -3.80), Vector3(21.1, 0.10, -0.6), Vector3(21.0, 0.10, 2.0), Vector3(16.8, 0.10, 2.0), Vector3(9.0, 0.10, 2.0)],
			"home": Vector3(24.8, 0.10, -0.80), "exit": [Vector3(9.2, 0.10, 2.0), Vector3(16.7, 0.10, 2.0), Vector3(22.48, 0.10, 2.0), Vector3(22.48, 0.10, -0.48)]}
	]
	reset()

func reset() -> void:
	for plan in plans:
		plan.index = 0
		plan.wait = 0.0
		plan.carry = false
		plan.returning = false
		plan.exit_index = 0
		plan.retreat = -1
		plan.at_start = true
		plan.building = false

func working(plan: Dictionary, hour: float) -> bool:
	return hour >= 6.0 and hour < 19.5 and (not plan.worker or not construction.complete())

func goal(plan: Dictionary, hour: float) -> Vector3:
	if working(plan, hour):
		if plan.returning and plan.exit_index > 0:
			return plan.exit[plan.exit_index - 1]
		return plan.route[plan.index]
	if not plan.returning:
		plan.retreat = posmod(plan.index - 1, plan.route.size())
		if plan.index == 0 and not plan.carry:
			plan.retreat = 0 if plan.at_start else plan.retreat
		plan.returning = true
		plan.building = false
		plan.carry = false
	if plan.retreat >= 0:
		return plan.route[plan.retreat]
	if plan.exit_index < plan.exit.size():
		return plan.exit[plan.exit_index]
	return plan.home

func arrived(plan: Dictionary, hour: float) -> bool:
	if not working(plan, hour):
		if plan.retreat >= 0:
			plan.retreat -= 1
		else:
			plan.exit_index = mini(plan.exit_index + 1, plan.exit.size())
		return false
	if plan.returning:
		plan.retreat = -1
		if plan.exit_index > 0:
			plan.exit_index -= 1
			return false
		plan.returning = false
		plan.index = 0
	plan.at_start = plan.index == 0
	if plan.worker:
		if plan.index == 0:
			plan.carry = true
		elif plan.index == 2 and plan.carry:
			plan.carry = false
			plan.building = true
			plan.wait = 2.8
			return false
	var delivery: bool = plan.building
	plan.building = false
	plan.wait = 1.1 if plan.worker else 2.3
	plan.index = (plan.index + 1) % plan.route.size()
	return delivery
