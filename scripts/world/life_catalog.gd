class_name LifeCatalog
extends RefCounted

const NATIONS := {
	"amieiro": {"name": "Coroa do Amieiro", "king": "Rei Aldren", "treasury": 800, "tax": 0.08, "regions": ["Vale do Amieiro"], "plots": ["sul-01", "sul-02"], "market": "amieiro", "playable": true},
	"brumaria": {"name": "Brumária", "king": "Rainha Elira", "treasury": 1100, "tax": 0.12, "regions": ["Serra de Bruma"], "plots": [], "market": "brumaria", "playable": false},
	"salmar": {"name": "Salmar", "king": "Rei Torven", "treasury": 1500, "tax": 0.10, "regions": ["Costa do Sal"], "plots": [], "market": "salmar", "playable": false}
}
const CLASSES := {
	"warrior": {"name": "Guerreiro", "skill": "Golpe e guarda", "start": "sword", "summary": "Espada e armadura pesada. Segure Shift para aparar no campo de treino."},
	"archer": {"name": "Arqueiro", "skill": "Disparo e rastreio", "start": "bow", "summary": "Dispare flechas e rastreie alvos no campo de treino."},
	"mage": {"name": "Mago", "skill": "Centelha", "start": "staff", "summary": "Lance centelhas com mana. Poções de mana podem ser compradas na banca."},
	"healer": {"name": "Curandeiro", "skill": "Restaurar", "start": "charm", "summary": "Restaure a vida do aliado ferido no campo de treino."},
	"farmer": {"name": "Agricultor", "skill": "Cultivar e criar", "start": "hoe", "summary": "Plante, regue e colha trigo ou ervas. Alimente as galinhas da horta para recolher ovos."},
	"doctor": {"name": "Médico", "skill": "Alquimia", "start": "kit", "summary": "Transforme ervas em remédios e poções de mana na bancada da taberna."},
	"smith": {"name": "Ferreiro", "skill": "Forjar e reparar", "start": "hammer", "summary": "Forje armas, armaduras e ferramentas com ferro e madeira. Repare peças gastas."},
	"artisan": {"name": "Artesão", "skill": "Marcenaria", "start": "chisel", "summary": "Fabrique móveis e componentes na oficina de marcenaria."}
}
const COLORS := ["417b89", "985754", "637e4b", "706189", "8b653e"]
const HAIR := ["dfaf62", "604332", "493a37", "bbb1a1"]
const RARITIES := ["Comum", "Incomum", "Raro", "Épico", "Lendário"]
const GOODS := {
	"wood": ["Madeira", "Material", 1.0, 0, 4],
	"stone": ["Pedra", "Material", 1.4, 0, 5],
	"iron": ["Ferro", "Material", 0.9, 0, 9],
	"fish": ["Peixe de rio", "Comida", 0.35, 0, 5],
	"wheat": ["Trigo", "Cultivo", 0.25, 0, 4],
	"herb": ["Erva medicinal", "Cultivo", 0.15, 0, 5],
	"seed": ["Sementes de trigo", "Cultivo", 0.05, 0, 2],
	"herb_seed": ["Sementes de erva", "Cultivo", 0.05, 0, 3],
	"egg": ["Ovo", "Comida", 0.18, 0, 5],
	"food": ["Ração", "Consumível", 0.30, 0, 6],
	"vial": ["Frasco", "Material", 0.20, 0, 4],
	"health": ["Remédio", "Consumível", 0.25, 1, 15],
	"mana": ["Poção de mana", "Consumível", 0.25, 1, 16],
	"arrow": ["Flecha", "Munição", 0.08, 0, 2],
	"chair": ["Banco de carvalho", "Mobília", 2.1, 1, 17],
	"joinery": ["Encaixe trabalhado", "Componente", 0.55, 1, 12],
	"sword": ["Espada de ferro", "Arma", 3.0, 1, 35, "weapon", 36, ["warrior"]],
	"bow": ["Arco de freixo", "Arma", 1.7, 1, 30, "weapon", 34, ["archer"]],
	"staff": ["Cajado de âmbar", "Arma", 1.6, 2, 39, "weapon", 38, ["mage"]],
	"charm": ["Talismã da aurora", "Acessório", 0.4, 2, 33, "accessory", 35, ["healer"]],
	"armor": ["Cota de ferro", "Armadura", 5.1, 1, 42, "armor", 36, ["warrior"]],
	"hoe": ["Enxada", "Ferramenta", 1.6, 0, 16, "tool", 24, ["farmer"]],
	"kit": ["Almofariz", "Ferramenta", 1.0, 0, 18, "tool", 25, ["doctor"]],
	"hammer": ["Martelo de forja", "Ferramenta", 1.9, 0, 19, "tool", 25, ["smith"]],
	"chisel": ["Formão", "Ferramenta", 0.7, 0, 16, "tool", 25, ["artisan"]]
}
const RECIPES := {
	"health": {"class": "doctor", "station": "alchemy", "cost": {"herb": 2, "vial": 1}, "qty": 1, "xp": 18, "level": 1},
	"mana": {"class": "doctor", "station": "alchemy", "cost": {"herb": 3, "vial": 1}, "qty": 1, "xp": 23, "level": 1},
	"sword": {"class": "smith", "station": "forge", "cost": {"iron": 3, "wood": 1}, "qty": 1, "xp": 26, "level": 1},
	"hoe": {"class": "smith", "station": "forge", "cost": {"iron": 1, "wood": 2}, "qty": 1, "xp": 15, "level": 1},
	"armor": {"class": "smith", "station": "forge", "cost": {"iron": 5}, "qty": 1, "xp": 32, "level": 2},
	"chair": {"class": "artisan", "station": "carpentry", "cost": {"wood": 2}, "qty": 1, "xp": 20, "level": 1},
	"joinery": {"class": "artisan", "station": "carpentry", "cost": {"wood": 1}, "qty": 2, "xp": 14, "level": 1}
}
const STOCK := {"wood": 45, "stone": 36, "iron": 22, "herb": 17, "seed": 25, "herb_seed": 18,
	"vial": 16, "food": 14, "health": 8, "mana": 8, "arrow": 70, "chair": 4, "joinery": 6, "hoe": 3, "armor": 2}
const VILLAGE_GOODS := {"wood": "madeira", "stone": "pedra", "iron": "ferro", "wheat": "trigo", "food": "alimentos"}

static func clean_name(raw: String) -> String:
	var name_value := raw.strip_edges()
	var pattern := RegEx.create_from_string("^[A-Za-zÀ-ÖØ-öø-ÿ][A-Za-zÀ-ÖØ-öø-ÿ' -]{1,20}[A-Za-zÀ-ÖØ-öø-ÿ]$")
	if pattern.search(name_value) == null or "  " in name_value:
		return ""
	return name_value

static func number(value: Variant, fallback: float, low: float, high: float) -> float:
	if (value is int or value is float) and is_finite(float(value)):
		return clampf(float(value), low, high)
	return fallback

static func label(item: String) -> String:
	return GOODS.get(item, [item])[0]

static func slot(item: String) -> String:
	var info: Array = GOODS.get(item, [])
	return info[5] if info.size() > 5 else ""

static func max_durability(item: String) -> int:
	var info: Array = GOODS.get(item, [])
	return info[6] if info.size() > 6 else 0
