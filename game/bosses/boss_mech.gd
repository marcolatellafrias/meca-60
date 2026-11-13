class_name BossMech
extends BalanceBody

## UNA MECA ENEMIGA (13/11/2026) — TRABAJO EN CURSO, en bloques: el mismo cuerpo con equilibrio que la meca propia (ver
## BalanceBody y docs/technical/base-comun.md), armado con las piezas de su diseño (BossDesign): el torso (caja o
## redondo), la pelvis, el medio de moverse (BossLegs: dos, cuatro o seis patas; BossRolling: orugas o ruedas), dos
## brazos con su antebrazo (BossArm) y lo del pecho (BossChest). La maneja su cerebro (BossBrain).
##
## TIENE VIDA (`health`), a diferencia de la meca propia (que no tiene: todo es equilibrio, ver
## docs/conceptual/la-meca.md). El usuario: «un boss con vida… que tenga vida arriba, que se puede ver». La bajan las
## piñas de la meca propia (PoseArm), según lo rápido que conectan. Sin vida se cae y no se levanta más.

signal hurt_by(amount: float)
signal died

## SU BANDO: lo que tira no le pega a ninguna meca enemiga (ver AreaStrike.spares).
const TEAM := "mecas enemigas"
## La vida de todas, por ahora.
const HEALTH := 100.0
## Una piña a esta velocidad (m/s) saca `PUNCH_DAMAGE` de vida; más rápida, más (con tope).
const PUNCH_SPEED := 35.0
const PUNCH_DAMAGE := 7.0

var design: BossDesign = BossDesign.new()
var field: ProjectileField = null
var brain: BossBrain = null
var arms: Array[BossArm] = []
var chest: BossChest = null
var health := HEALTH
var max_health := HEALTH
## El salto que el cerebro pidió termina en una onda al caer.
var stomp_armed := false
## El cartel de arriba (lo que mide el péndulo): para mirar las piezas, no para pelear.
var show_label := true

var _was_airborne := false


func _ready() -> void:
	team = TEAM
	size = design.torso_size
	mass = design.mass()
	knobs = BodySettings.current.duplicate() as BodySettings
	_tune(knobs)
	if brain == null:
		brain = BossBrain.new(self)
	name = design.title
	super()
	label.visible = show_label


## SUS PERILLAS: las de la meca propia, con el alto, los pasos y la velocidad de su medio de moverse.
func _tune(k: BodySettings) -> void:
	var drop := pelvis_drop()
	match design.legs:
		BossDesign.Legs.BIPED:
			k.hover_height = 6.5 + drop
			k.walk_speed = 6.0
			k.step_reach = 3.2
			k.step_height = 1.8
		BossDesign.Legs.QUAD:
			k.hover_height = 4.5 + drop
			k.walk_speed = 7.0
			k.step_reach = 2.8
			k.step_height = 1.6
		BossDesign.Legs.SPIDER:
			k.hover_height = 3.0 + drop * 0.5
			k.walk_speed = 7.5
			k.step_reach = 2.4
			k.step_height = 2.4
		BossDesign.Legs.TREADS:
			k.hover_height = 3.4
			k.walk_speed = 7.0
		BossDesign.Legs.WHEELS:
			k.hover_height = 3.8
			k.walk_speed = 10.0
	k.settle_gap = 0.8
	k.turn_speed = 70.0
	k.jump_height = 10.0


## El alto de la pelvis (m): 0 sin pelvis. Las orugas y las ruedas no tienen.
func pelvis_drop() -> float:
	if design.legs == BossDesign.Legs.TREADS or design.legs == BossDesign.Legs.WHEELS:
		return 0.0
	return design.pelvis * 1.8


func _make_shape() -> void:
	if design.torso == BossDesign.Torso.ROUND:
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = size.x * 0.5
		cylinder.height = size.y
		shape.shape = cylinder
		add_child(shape)
	else:
		super()


func _make_legs() -> BodyLegs:
	if design.legs == BossDesign.Legs.TREADS or design.legs == BossDesign.Legs.WHEELS:
		var rolling := BossRolling.new()
		rolling.setup(design, size, knobs.hover_height)
		return rolling
	var legs_made := BossLegs.new()
	legs_made.setup(design, size, knobs.hover_height, pelvis_drop())
	return legs_made


func _build() -> void:
	var colors := design.colors()
	var hull: Color = colors["hull"]
	var joint: Color = colors["joint"]
	var accent: Color = colors["accent"]
	# EL TORSO.
	if design.torso == BossDesign.Torso.ROUND:
		Clay.cylinder(look, size.x * 0.5, size.y, Vector3.ZERO, hull)
		Clay.cylinder(look, size.x * 0.52, size.y * 0.12, Vector3(0, -size.y * 0.3, 0), joint)
		Clay.cylinder(look, size.x * 0.35, size.y * 0.15, Vector3(0, size.y * 0.55, 0), hull.darkened(0.15))
		Clay.box(look, Vector3(size.x * 0.5, size.y * 0.1, 0.5), Vector3(0, size.y * 0.32, -size.x * 0.48), accent)
	else:
		Clay.box(look, size, Vector3.ZERO, hull)
		Clay.box(look, Vector3(size.x * 1.02, size.y * 0.12, size.z * 1.02), Vector3(0, -size.y * 0.3, 0), joint)
		Clay.box(look, Vector3(size.x * 0.6, size.y * 0.12, 0.4), Vector3(0, size.y * 0.32, -size.z * 0.5), accent)
	# LA PELVIS, debajo.
	var drop := pelvis_drop()
	if drop > 0.0:
		var width := size.x * (0.75 if design.legs == BossDesign.Legs.BIPED else 0.85)
		Clay.box(look, Vector3(width, drop, size.z * 0.55), Vector3(0, -size.y * 0.5 - drop * 0.5, 0), joint)
	# LOS BRAZOS: a los costados, un poco arriba del medio, corridos su offset (en espejo).
	for one in design.arms:
		var arm := BossArm.new()
		arm.boss = self
		arm.side = float(one["side"])
		arm.hand = int(one["hand"]) as BossDesign.Hand
		arm.gear = int(one["gear"]) as BossDesign.Gear
		arm.radius = size.y * 0.08
		arm.upper = size.y * 0.6 * float(one["length"])
		arm.forearm = size.y * 0.6 * float(one["length"])
		var shift: Vector3 = one["offset"]
		var half := size.x * 0.5
		arm.shoulder_local = Vector3(arm.side * (half + arm.radius * 1.4 + shift.x), size.y * 0.18 + shift.y, shift.z)
		add_child(arm)
		arms.append(arm)
	chest = BossChest.new()
	chest.boss = self
	chest.kind = design.chest
	chest.position = design.chest_offset
	look.add_child(chest)


func _think() -> void:
	brain.think(get_physics_process_delta_time())


## AL CAER DE UN SALTO DEL CEREBRO: la onda al ras (ver BossBrain).
func _after_step(_k: BodySettings, _delta: float) -> void:
	if _was_airborne and not airborne and grounded and stomp_armed:
		stomp_armed = false
		if not ProjectileField.is_client(self):
			strike({"shape": AreaStrike.Shape.WAVE_RING, "element": AreaStrike.Element.BLAST,
				"at": support, "delay": 0.1, "speed": 28.0, "reach": 90.0, "push": 10.0})
	_was_airborne = airborne


## LO QUE TIRA Y LAS ZONAS QUE PEGAN, por su ProjectileField y con su bando (sin campo, nada).
func strike(spec: Dictionary) -> void:
	if field != null:
		spec["team"] = team
		field.strike(spec)


func launch(kind: Missile.Kind, from: Vector3, to: Vector3, flight: float, delay := 0.0, target: Node3D = null) -> void:
	if field != null:
		field.launch(kind, from, to, flight, delay, target, team)


## ── LOS ATAQUES (los elige el cerebro) ──────────────────────────────────────────────────────────────────────────

## LOS QUE TIENE: con cada brazo, la mano y lo del antebrazo; el pecho; y, con patas, el salto.
func attack_names() -> PackedStringArray:
	var out := PackedStringArray()
	for i in arms.size():
		if arms[i].can_hand():
			out.append("brazo %d mano" % i)
		if arms[i].can_gear():
			out.append("brazo %d arma" % i)
	if design.chest != BossDesign.Chest.NONE:
		out.append("pecho")
	if design.legs in [BossDesign.Legs.BIPED, BossDesign.Legs.QUAD, BossDesign.Legs.SPIDER]:
		out.append("salto")
	return out


## Empieza el ataque `which` contra `target`; devuelve cuánto dura.
func attack_with(which: String, target: Node3D) -> float:
	if which == "pecho":
		return chest.attack(target)
	var parts := which.split(" ")
	if parts.size() == 3 and parts[0] == "brazo":
		return arms[int(parts[1])].attack(target, parts[2] == "arma")
	return 0.0


## CERCA, CUÁNTO DEJA ENTRE SU CAJA Y LA OTRA (m): lo que alcanzan sus manos, con margen.
func melee_gap() -> float:
	var most := 0.0
	for arm in arms:
		if arm.can_hand():
			most = maxf(most, arm.reach())
	return most * 0.45


func busy() -> bool:
	for arm in arms:
		if arm.busy():
			return true
	return chest != null and chest.busy()


func rooted() -> bool:
	return chest != null and chest.roots()


## ── LA VIDA ─────────────────────────────────────────────────────────────────────────────────────────────────────

## LE SACA `amount` de vida; sin vida, se cae para siempre (con una explosión).
func hurt(amount: float) -> void:
	if broken or amount <= 0.0:
		return
	health = maxf(health - amount, 0.0)
	hurt_by.emit(amount)
	if health <= 0.0:
		broken = true
		_fall_down()
		apply_torque_impulse(global_basis.x * inertia() * 1.2)
		for i in 3:
			var burst := ParticleSystems.explosion_flash(ParticleMeshes.Kind.SPHERE, Missile.BLAST_SIZE * 1.5)
			burst.top_level = true
			add_child(burst)
			burst.global_transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), global_position + Vector3(
				randf_range(-3, 3), randf_range(-2, 3), randf_range(-3, 3)))
			burst.restart()
		died.emit()


## La vida que saca una piña que conecta a `speed` (m/s).
static func punch_damage(speed: float) -> float:
	return PUNCH_DAMAGE * clampf(speed / PUNCH_SPEED, 0.3, 1.6)
