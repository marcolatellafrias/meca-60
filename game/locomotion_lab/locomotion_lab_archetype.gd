class_name LocomotionLabArchetype
extends SeededArchetype

## ── LA FILA LOCOMOCIÓN: LOS SEIS ARQUETIPOS HACIENDO COSAS (13/11/2026) ─────────────────────────────────────────────
## Para mirar cómo se mueven los personajes (el usuario: «cómo aceleran, cómo corren, cómo se chocan, cómo saltan, cómo
## aterrizan, cómo llevan paquetes, cómo arrojan paquetes, cómo atajan paquetes y cómo chocan entre sí… y la viga en la
## cabeza»). Una parcela por escena, los seis en carriles, manejados por guion (ver CharacterActions) con los mismos
## botones que un jugador; arriba de cada uno, su velocidad. Al entrar arrancan solos; la K vuelve a empezar, la J y la U
## cambian la variante. Se caen con el equilibrio de siempre y se levantan solos (ver CharacterGetUp).
##
## *Viene de la parcela «Experimentos de locomoción» de character-parametric (2.261 líneas, con pasillos de obstáculos,
## botones, sillas de la nave y quince escenas): acá quedan seis escenas y lo mínimo.* Sus paneles: F1 lo de todos los
## arquetipos (LocomotionPanel), F3 lo de cada arquetipo (LocomotionTuner).

enum Scene { RUN, JUMP, DROP, CARRY, CATCH, CLASH }
const NAMES := ["Correr y frenar", "Saltar", "Caer de alto", "Llevar y tirar", "Atajar", "Chocar"]

const FOOTPRINT := Vector2(12.0, 24.0)

## LAS VARIANTES DE CADA ESCENA: [nombre de la J, sus valores], [de la U, sus valores].
const RUN_ENDS := ["suelta y frena sola", "frena apretando para atrás", "contra una pared"]
const JUMP_OBSTACLES := [["valla de 0,3 m", 0.3], ["valla de 0,6 m", 0.6], ["valla de 0,9 m", 0.9],
	["viga a la cabeza", -1.0]]
const DROP_HEIGHTS := [2.0, 4.0, 8.0]
const THROW_CHARGES := [0.3, 0.6, 1.0]
const CATCH_SPEEDS := [5.0, 8.0, 11.0]
const CATCH_FROM := ["de frente", "alto", "al costado"]
const CLASH_WAYS := ["de frente", "en ángulo", "contra uno quieto"]

var scene := Scene.RUN
## La variante de la J y de la U, y si corren (o caminan).
var option_j := 0
var option_u := 0
var sprint := true


static func catalogue() -> Array[SeededArchetype]:
	var out: Array[SeededArchetype] = []
	for each: int in Scene.values():
		var row := LocomotionLabArchetype.new()
		row.scene = each as Scene
		row.display_name = NAMES[each]
		out.append(row)
	return out


func max_footprint() -> Vector2:
	return FOOTPRINT


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([_what(), "K otra vez · arriba de cada uno, su velocidad"])


func _what() -> String:
	var pace := "corriendo" if sprint else "caminando"
	match scene:
		Scene.RUN:
			return "aceleran %s y al final %s" % [pace, RUN_ENDS[option_j]]
		Scene.JUMP:
			return "%s, %s" % [JUMP_OBSTACLES[option_j][0], pace]
		Scene.DROP:
			return "se tiran de %.0f m, %s" % [DROP_HEIGHTS[option_j], pace]
		Scene.CARRY:
			return "levantan un cubo, lo llevan %s y lo tiran (carga %d %%)" % [pace, roundi(THROW_CHARGES[option_j] * 100.0)]
		Scene.CATCH:
			return "atajan un cubo a %.0f m/s, %s" % [CATCH_SPEEDS[option_j], CATCH_FROM[option_u]]
		Scene.CLASH:
			return "de a dos, %s, %s%s" % [CLASH_WAYS[option_j], pace, ", con un cubo" if option_u == 1 else ""]
	return ""


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var lab := LocomotionLab.new()
	lab.name = "Locomocion"
	lab.setup(self)
	parent.add_child(lab)
	return lab


## LAS TECLAS: K otra vez; J y U, la variante (y otra vez); en las que tienen paso, U camina o corre.
func parcel_options() -> Array[Dictionary]:
	var out: Array[Dictionary] = [
		{"key": KEY_K, "label": "otra vez", "apply": func(parcel: SandboxParcel) -> void: _restart(parcel)},
	]
	var j_names: Array = []
	match scene:
		Scene.RUN:
			j_names = RUN_ENDS
		Scene.JUMP:
			j_names = JUMP_OBSTACLES.map(func(o: Array) -> String: return o[0])
		Scene.DROP:
			j_names = DROP_HEIGHTS.map(func(h: float) -> String: return "de %.0f m" % h)
		Scene.CARRY:
			j_names = THROW_CHARGES.map(func(c: float) -> String: return "tiro al %d %%" % roundi(c * 100.0))
		Scene.CATCH:
			j_names = CATCH_SPEEDS.map(func(v: float) -> String: return "a %.0f m/s" % v)
		Scene.CLASH:
			j_names = CLASH_WAYS
	out.append({"key": KEY_J, "label": func() -> String: return str(j_names[option_j]),
		"apply": func(parcel: SandboxParcel) -> void:
			option_j = (option_j + 1) % j_names.size()
			_restart(parcel)})
	if scene == Scene.CATCH:
		out.append({"key": KEY_U, "label": func() -> String: return "desde: %s" % CATCH_FROM[option_u],
			"apply": func(parcel: SandboxParcel) -> void:
				option_u = (option_u + 1) % CATCH_FROM.size()
				_restart(parcel)})
	else:
		out.append({"key": KEY_U, "label": func() -> String: return "corriendo" if sprint else "caminando",
			"apply": func(parcel: SandboxParcel) -> void:
				sprint = not sprint
				_restart(parcel)})
	if scene == Scene.CLASH:
		out.append({"key": KEY_Y, "label": func() -> String: return "con un cubo" if option_u == 1 else "sin cubo",
			"apply": func(parcel: SandboxParcel) -> void:
				option_u = 1 - option_u
				_restart(parcel)})
	return out


func _restart(parcel: SandboxParcel) -> void:
	parcel.regenerate(parcel.seed_value)
