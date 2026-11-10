class_name WorldSimulation
extends RefCounted

var clock := WorldClock.new()
var climate := RegionalClimate.new()
var construction := ConstructionManager.new()

func tick(seconds: float) -> void:
	clock.advance(seconds)

func command(action: StringName) -> bool:
	match action:
		&"deliver_bridge_material":
			return construction.deliver()
	return false

func snapshot() -> Dictionary:
	return {"elapsed": clock.elapsed, "bridge": construction.snapshot()}

func restore(data: Dictionary) -> void:
	clock.elapsed = float(data["elapsed"])
	construction.restore(data["bridge"])
