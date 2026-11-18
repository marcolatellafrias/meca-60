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
## botones, sillas de la meca y quince escenas): acá quedan seis escenas y lo mínimo.* Sus paneles: F1 lo de todos los
## arquetipos (LocomotionPanel), F3 lo de cada arquetipo (LocomotionTuner).

enum Scene { RUN, JUMP, DROP, CARRY, CATCH, CLASH, SLALOM }
const NAMES := ["Correr y frenar", "Saltar", "Caer de alto", "Llevar y tirar", "Atajar", "Chocar",
	"Esquivar barriles"]

const FOOTPRINT := Vector2(12.0, 24.0)
## Esquivar barriles necesita carriles más anchos: el zigzag se abre a cada costado del barril.
const SLALOM_FOOTPRINT := Vector2(26.0, 24.0)

## LAS VARIANTES DE CADA ESCENA: [nombre de la J, sus valores], [de la U, sus valores].
const RUN_ENDS := ["suelta y frena sola", "frena apretando para atrás", "contra una pared"]
const JUMP_OBSTACLES := [["valla de 0,3 m", 0.3], ["valla de 0,6 m", 0.6], ["valla de 0,9 m", 0.9],
	["viga a la cabeza", -1.0]]
const DROP_HEIGHTS := [2.0, 4.0, 8.0]
const THROW_CHARGES := [0.3, 0.6, 1.0]
const CATCH_SPEEDS := [5.0, 8.0, 11.0]
const CATCH_FROM := ["de frente", "alto", "al costado"]
const CLASH_WAYS := ["de frente", "en ángulo", "contra uno quieto"]
## ESQUIVAR BARRILES (la de character-parametric del 04/11/2026, la más simple): un zigzag fijo alrededor de barriles
## en fila, sin ver nada; los barriles cada tantos m (la J: separados o juntos).
const SLALOM_STEPS := [["separados", 6.5], ["juntos", 4.5]]

var scene := Scene.RUN
## La variante de la J y de la U, y si corren (o caminan).
var option_j := 0
var option_u := 0
var sprint := true
## Si uno está adentro de su parcela (ver LocomotionLab, DESPIERTA SÓLO CON UNO ADENTRO).
var _inside := false


static func catalogue() -> Array[SeededArchetype]:
	var out: Array[SeededArchetype] = []
	for each: int in Scene.values():
		var row := LocomotionLabArchetype.new()
		row.scene = each as Scene
		row.display_name = NAMES[each]
		out.append(row)
	return out


func max_footprint() -> Vector2:
	return SLALOM_FOOTPRINT if scene == Scene.SLALOM else FOOTPRINT


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
		Scene.SLALOM:
			return "zigzag entre barriles %s, %s" % [SLALOM_STEPS[option_j][0], pace]
	return ""


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var lab := LocomotionLab.new()
	lab.name = "Locomocion"
	# En el sandbox nace despierta sólo con uno adentro (la K la rearma estando adentro); fuera de él, siempre.
	lab.setup(self, _inside or not (parent is SandboxParcel))
	parent.add_child(lab)
	return lab


func entered(parcel: SandboxParcel, inside: bool) -> void:
	_inside = inside
	var lab := parcel.root() as LocomotionLab
	if lab != null:
		lab.set_awake(inside)


## LAS TECLAS: K otra vez; J y U, la variante (y otra vez); en las que tienen paso, U camina o corre.
func keys() -> Array[SandboxKey]:
	var out: Array[SandboxKey] = [
		SandboxKey.action(KEY_K, SandboxKey.Weight.MAIN, "otra vez", func(parcel: SandboxParcel) -> void: _restart(parcel)),
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
		Scene.SLALOM:
			j_names = SLALOM_STEPS.map(func(o: Array) -> String: return "barriles " + o[0])
	out.append(SandboxKey.cycle(KEY_J, SandboxKey.Weight.MAIN, "prueba", j_names, func() -> int: return option_j,
		func(parcel: SandboxParcel, index: int) -> void:
			option_j = index
			_restart(parcel)))
	if scene == Scene.CATCH:
		out.append(SandboxKey.cycle(KEY_U, SandboxKey.Weight.NORMAL, "desde", CATCH_FROM, func() -> int: return option_u,
			func(parcel: SandboxParcel, index: int) -> void:
				option_u = index
				_restart(parcel)))
	else:
		out.append(SandboxKey.toggle(KEY_U, SandboxKey.Weight.NORMAL, "corriendo", func() -> bool: return sprint,
			func(parcel: SandboxParcel, on: bool) -> void:
				sprint = on
				_restart(parcel)))
	if scene == Scene.CLASH:
		out.append(SandboxKey.toggle(KEY_Y, SandboxKey.Weight.NORMAL, "con un cubo", func() -> bool: return option_u == 1,
			func(parcel: SandboxParcel, on: bool) -> void:
				option_u = 1 if on else 0
				_restart(parcel)))
	return out


func _restart(parcel: SandboxParcel) -> void:
	parcel.regenerate(parcel.seed_value)
