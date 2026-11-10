class_name WorldClock
extends RefCounted

const DAY_SECONDS := 7200.0
const YEAR_DAYS := 96
var elapsed := DAY_SECONDS * 8.5 / 24.0

func advance(seconds: float) -> void:
	elapsed += maxf(0.0, seconds)

func total_day() -> int:
	return floori(elapsed / DAY_SECONDS)

func hour() -> float:
	return fposmod(elapsed, DAY_SECONDS) / DAY_SECONDS * 24.0

func year() -> int:
	return floori(float(total_day()) / YEAR_DAYS) + 1

func day_of_year() -> int:
	return posmod(total_day(), YEAR_DAYS) + 1

func time_text() -> String:
	var minutes := floori(hour() * 60.0 + 0.000001)
	return "%02d:%02d" % [floori(minutes / 60.0), minutes % 60]
