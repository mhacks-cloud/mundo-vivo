class_name ConstructionManager
extends RefCounted

signal changed
const REQUIRED := [2, 3, 3]
const MATERIALS := ["pedra", "madeira", "pedra", "madeira", "madeira", "madeira", "ferramentas", "madeira"]
const PHASES := ["Pedido de materiais", "Separação no depósito", "Transporte", "Descarga",
	"Preparação da margem", "Montagem dos andaimes", "Fundações", "Estrutura", "Acabamentos", "Inspeção", "Inaugurada"]
var stage := 0
var delivered := 0
var logistics_phase := 0
var inspection_until := 0.0

func complete() -> bool:
	return stage == REQUIRED.size()

func loads() -> int:
	return [0, 2, 5, 8][stage] + delivered

func phase() -> int:
	var installed := loads()
	if installed == 0:
		return logistics_phase
	if installed == 7 and inspection_until > 0.0:
		return 9
	return [0, 4, 5, 6, 7, 7, 8, 8, 10][installed]

func phase_name() -> String:
	return PHASES[phase()]

func required_item() -> String:
	return "" if complete() else MATERIALS[loads()]

func logistics(value: int) -> void:
	var prior := phase()
	logistics_phase = maxi(logistics_phase, clampi(value, 0, 3))
	if phase() != prior:
		changed.emit()

func inspect(elapsed: float) -> void:
	if loads() != 7 or inspection_until > 0.0:
		return
	inspection_until = elapsed + 2.4
	changed.emit()

func deliver() -> bool:
	if complete():
		return false
	logistics_phase = 0
	inspection_until = 0.0
	delivered += 1
	if delivered >= REQUIRED[stage]:
		delivered = 0
		stage += 1
	changed.emit()
	return true

func status() -> String:
	if complete():
		return "Inaugurada · travessia aberta"
	return "%s · %d/8" % [phase_name(), loads()]

func snapshot() -> Dictionary:
	return {"stage": stage, "delivered": delivered, "logistics": logistics_phase, "inspection_until": inspection_until}

func restore(state: Dictionary) -> void:
	stage = clampi(int(state.get("stage", 0)), 0, REQUIRED.size())
	delivered = 0 if complete() else clampi(int(state.get("delivered", 0)), 0, REQUIRED[stage] - 1)
	var stored: Variant = state.get("logistics", 0)
	logistics_phase = int(clampf(float(stored), 0, 3)) if (stored is int or stored is float) and is_finite(float(stored)) else 0
	var inspection: Variant = state.get("inspection_until")
	inspection_until = clampf(float(inspection), 0, 3.0e10) if (inspection is int or inspection is float) and is_finite(float(inspection)) and loads() == 7 else 0.0
	changed.emit()
