class_name CampaignJournal
extends RefCounted

const TASKS := {
	"home": ["Raízes no Vale", "Registre um terreno e instale a primeira peça da propriedade.", 12],
	"market": ["Mãos que trabalham", "Conclua um contrato no quadro da praça ou um pedido de fornecimento.", 16],
	"journey": ["Além do rio", "Cruze o portão para Alto da Bruma.", 10],
	"guild": ["Companhia do Vau", "Registre-se na sede da Companhia perto da praça.", 10],
	"ruin": ["A Ruína da Serra", "Abra o cofre da Ruína depois de derrotar seu guardião.", 22]
}
var claimed: Array[String] = []
var fishing_day := -1
var catches := 0

func ready(id: String, game: Node3D) -> bool:
	var career: ValeLife = game.career
	match id:
		"home": return not career.life.estate.owned(PlayerLife.ID).is_empty() and not career.life.estate.pieces.is_empty()
		"market":
			if not career.life.completed.is_empty():
				return true
			for order in game.markets.contracts.values():
				if order.state == "CONCLUÍDO" and order.uid == career.life.profile.get("uid"):
					return true
		"journey": return "capital" in game.realms.world.discovered
		"guild": return not career.guild.member.is_empty() and career.guild.member == career.life.profile.get("uid")
		"ruin": return career.ruin.run.claimed
	return false

func claim(id: String, game: Node3D) -> bool:
	if not TASKS.has(id) or id in claimed or not ready(id, game):
		return false
	claimed.append(id)
	game.career.life.award(int(TASKS[id][2]))
	game.career.life.logbook("Diário · " + TASKS[id][0])
	return true

func fish(life: PlayerLife, day: int, weather: String) -> String:
	if weather == "Neve":
		return "A margem está congelada."
	if day == fishing_day and catches >= 2:
		return "A margem precisa descansar até amanhã."
	if not life.bag.transform({"seed": 1}, "fish", 1):
		return "Use uma semente como isca e reserve espaço na bolsa."
	if day != fishing_day:
		fishing_day = day
		catches = 0
	catches += 1
	life.award(3)
	return "Peixe pescado · uma semente usada como isca."

func snapshot() -> Dictionary:
	return {"claimed": claimed.duplicate(), "day": fishing_day, "catches": catches}

func restore(value: Variant) -> void:
	claimed.clear()
	fishing_day = -1
	catches = 0
	if not value is Dictionary:
		return
	fishing_day = int(LifeCatalog.number(value.get("day"), -1, -1, 3650000))
	catches = int(LifeCatalog.number(value.get("catches"), 0, 0, 2))
	if value.get("claimed") is Array:
		for id in TASKS:
			if id in value.claimed:
				claimed.append(id)
