class_name ConstructionManager
extends RefCounted

signal changed
const STAGES := ["Estacas", "Longarinas", "Tabuleiro", "Inaugurada"]
const REQUIRED := [2, 3, 3]
var stage := 0
var delivered := 0

func complete() -> bool:
	return stage == REQUIRED.size()

func deliver() -> bool:
	if complete():
		return false
	delivered += 1
	if delivered >= REQUIRED[stage]:
		delivered = 0
		stage += 1
	changed.emit()
	return true

func status() -> String:
	if complete():
		return "Inaugurada · travessia aberta"
	return "%s · %d/%d cargas" % [STAGES[stage], delivered, REQUIRED[stage]]

func snapshot() -> Dictionary:
	return {"stage": stage, "delivered": delivered}

func restore(state: Dictionary) -> void:
	stage = clampi(int(state.get("stage", 0)), 0, REQUIRED.size())
	delivered = 0 if complete() else clampi(int(state.get("delivered", 0)), 0, REQUIRED[stage] - 1)
	changed.emit()
