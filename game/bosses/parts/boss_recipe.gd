class_name BossRecipe
extends Resource

## LA RECETA DE UN JEFE (17/11/2026): qué piezas lleva (BossParts): unas piernas, un torso, el brazo de sus hombros (y
## otro para los hombros de más, si el torso tiene cuatro) y una cabeza. Dice SI ENCAJA (`problems`) y QUÉ LE DA
## (`gives`: lo que piden los poderes, BossPower.needs). La arma BossFrame.

@export var legs := "orugas"
@export var torso := "ancho"
@export var arm := "puno"
## El brazo del segundo par de hombros (los de abajo, si el torso tiene cuatro).
@export var arm_b := "pinza"
@export var head := "visor"


static func of(legs_id: String, torso_id: String, arm_id: String, head_id: String, arm_b_id := "") -> BossRecipe:
	var made := BossRecipe.new()
	made.legs = legs_id
	made.torso = torso_id
	made.arm = arm_id
	made.arm_b = arm_b_id if not arm_b_id.is_empty() else arm_id
	made.head = head_id
	return made


## El brazo de cada hombro, en orden (los dos de arriba, y los dos de abajo si hay).
func arms() -> PackedStringArray:
	var out := PackedStringArray()
	for index in int(BossParts.TORSOS[torso]["shoulders"]):
		out.append(arm if index < 2 else arm_b)
	return out


## POR QUÉ NO ENCAJA (vacío: encaja): sólo lo que es de lugar, un brazo más grande que el hombro donde va. *Hubo una
## regla de peso (las piernas aguantaban tanto): el usuario la sacó («muy figurativa… le saca libertad… capaz quiero
## jugar con proporciones poco realistas»).*
func problems() -> PackedStringArray:
	var out := PackedStringArray()
	var shoulder: int = BossParts.TORSOS[torso]["shoulder_size"]
	var seen := {}
	for each in arms():
		var need: int = BossParts.ARMS[each]["size"]
		if need > shoulder and not seen.has(each):
			seen[each] = true
			out.append("el brazo «%s» pide un hombro %s y el torso «%s» los tiene %s" % [BossParts.ARMS[each]["title"],
				BossParts.SIZE_NAMES[need], BossParts.TORSOS[torso]["title"], BossParts.SIZE_NAMES[shoulder]])
	return out


## LO QUE LE DAN SUS PIEZAS (lo que piden los poderes). «brazos» hace falta en dos.
func gives() -> PackedStringArray:
	var count := {}
	for each: String in BossParts.LEGS[legs]["gives"] + BossParts.TORSOS[torso]["gives"] + BossParts.HEADS[head]["gives"]:
		count[each] = 2
	for each in arms():
		for part: String in BossParts.ARMS[each]["gives"]:
			count[part] = int(count.get(part, 0)) + 1
	var out := PackedStringArray()
	for part: String in count:
		if part != "brazos" or int(count[part]) >= 2:
			out.append(part)
	return out


## Qué poderes de `powers` puede usar (los que no piden nada que le falte).
func usable(powers: Array[BossPower]) -> PackedStringArray:
	var mine := gives()
	var out := PackedStringArray()
	for power in powers:
		var fits := true
		for need in power.needs():
			fits = fits and mine.has(need)
		if fits:
			out.append(power.title())
	return out


func title() -> String:
	return "%s · torso %s · %s · %s" % [BossParts.LEGS[legs]["title"], BossParts.TORSOS[torso]["title"],
		" y ".join(_arm_titles()), BossParts.HEADS[head]["title"]]


func _arm_titles() -> PackedStringArray:
	var names := PackedStringArray()
	for each in arms():
		var name: String = BossParts.ARMS[each]["title"]
		if not names.has(name):
			names.append(name)
	return names
