class_name SeasonManager
extends RefCounted

const NAMES := ["Primavera", "Verão", "Outono", "Inverno"]
const DAYS_PER_SEASON := 24

func index(day: int, latitude: float) -> int:
	var shift := 2 if latitude < 0.0 else 0
	return posmod(floori(float(day) / DAYS_PER_SEASON) + shift, NAMES.size())

func name_for(day: int, latitude: float) -> String:
	return NAMES[index(day, latitude)]
