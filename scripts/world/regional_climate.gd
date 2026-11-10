class_name RegionalClimate
extends RefCounted

const WETNESS := {"vale": 0.52, "floresta": 0.73, "serra": 0.47, "estepe": 0.23}
var latitude := 42.0
var altitude := 410.0
var biome := "vale"
var seasons := SeasonManager.new()

func sample(day: int, hour: float) -> Dictionary:
	var season := seasons.index(day, latitude)
	var tilt := minf(absf(latitude) / 45.0, 1.6)
	var variation: float = [0.0, 8.0, -1.0, -8.0][season]
	var temperature := 24.0 - absf(latitude) * 0.21 - altitude * 0.0065 + variation * tilt
	temperature += sin((hour - 8.0) * TAU / 24.0) * 4.5
	var noise := sin(day * 4.39 + latitude * 0.17 + altitude * 0.02 + 1.2) * 0.33
	var humidity := clampf(float(WETNESS.get(biome, 0.5)) + noise + (0.12 if season == 0 else 0.0), 0.0, 1.0)
	var weather := "Céu limpo"
	if humidity > 0.74:
		weather = "Neve" if temperature <= 1.0 else "Chuva"
	elif humidity > 0.57:
		weather = "Névoa"
	return {"temperature": temperature, "humidity": humidity, "weather": weather}
