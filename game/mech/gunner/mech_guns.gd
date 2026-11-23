class_name MechGuns
extends Node3D

## LA AMETRALLADORA Y EL LANZAMISILES, SOBRE LA TAPA (22/11/2026; el usuario: «están como arriba del hombro en vez de arriba
## de la tapa… que no tapen al pasajero»; «quisiera que esas dos herramientas sean 360 grados»). Van en dos torretas, centradas en
## profundidad a los costados del pozo: la ametralladora a la derecha y la caja de misiles a la izquierda, siempre horizontales. Lo que
## disparan y sus tiempos, en GunnerWeapons.
## LA MIRA LAS ENCAMINA (MechAim): cada torreta da la vuelta entera hacia la mira de quien la usa y, sin nadie, vuelve al
## frente; cada misil se tuerce hacia la mira de quien lo lanzó (las perillas, «Puntería» en el F4).
## EN RED: las simula el dueño de la meca (BodyNet). Cada disparo es un mensaje a todas las máquinas, que dibujan el suyo;
## el golpe lo aplica sólo el host (la zona de la ametralladora, `_zone_step`, y GunnerMissile).

## El tamaño de los modelos (×), a escala de meca.
const MODEL_SCALE := 1.7
## LA TORRETA: lo alto de su pie sobre la tapa, y lo que se aparta del borde del costado (m).
const POST := 0.34
const EDGE := 0.12
const POD_CELL := 0.11
const BARREL_TURNS := 4.0
const GUNMETAL := Color(0.24, 0.25, 0.27)
const MISSILE_TIP := Color(0.85, 0.35, 0.25)
## Cuántas veces por segundo el dueño manda el calor y la munición.
const STATE_RATE := 10.0
## LA ZONA QUE PEGA: su largo (m), su medio ancho (°), cada cuánto pega (s) y lo que le cuenta a un jefe por pulso (las 14
## balas por segundo de antes, repartidas en 10 pulsos).
## (Su largo y su abertura, en HitSettings: ver MechSkills.) El tope de la mira con los valores de arranque.
const ZONE_LENGTH := MechSkills.RANGE
const ZONE_PULSE := 0.1
const ZONE_STRENGTH := 21000.0
## Lo que pega de más la perforante.
const PIERCING_POWER := 1.7
## A cuántos metros al frente del torso se cruzan los misiles con su línea del centro.
const MISSILE_MEET := 12.0
## Lo que sale la boca de la ametralladora desde su eje (m).
const MUZZLE := 0.76 * MODEL_SCALE
## Lo rápido que las demás máquinas alcanzan el giro que les dice el dueño.
const GUN_FOLLOW := 12.0

var mech: BalanceBody = null
var weapons: GunnerWeapons = null
var aim: MechAim = null

## LO GIRADA QUE ESTÁ LA AMETRALLADORA respecto del frente del torso (radianes), y lo último que dijo el dueño.
var _gun_turn := 0.0
var _gun_told := 0.0
var _gun_model: Node3D = null
## Lo mismo para la caja de misiles.
var _pod_turn := 0.0
var _pod_told := 0.0
var _pod_model: Node3D = null
var _gun_at := Vector3.ZERO
var _pod_at := Vector3.ZERO
var _barrels: Node3D = null
var _skip: Array[RID] = []
var _state_clock := 0.0
var _zone_clock := 0.0


func _init() -> void:
	name = "Armas de los costados"
	weapons = GunnerWeapons.new()
	weapons.name = "Armas"
	weapons.guns = self
	add_child(weapons)


func _ready() -> void:
	var form := CageCabin.shape()
	var lid := form.height() * 0.5 + CageCabin.pit_of(form).top()
	# CENTRADAS EN PROFUNDIDAD (el usuario: «si es que van a ser 360 grados»), a los costados del pozo y contra el borde.
	var out := (form.octagon_apothem() if form.is_round() else form.side() * 0.5) - EDGE
	var high := lid + POST
	_gun_at = Vector3(out, high, 0.0)
	_pod_at = Vector3(-out, high, 0.0)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(self, 0.2, POST, Vector3(side * out, lid + POST * 0.5, 0.0), GUNMETAL)
	_gun_model = _holder(_gun_at)
	_gun_model.rotation.y = _gun_model_yaw()
	_minigun(_gun_model)
	_pod_model = _holder(_pod_at)
	_pod_model.rotation.y = _pod_model_yaw()
	_missiles(_pod_model)


## Si esta máquina las simula (sin red, siempre).
func is_mine() -> bool:
	return mech == null or mech.net == null or not mech.net.remote()


## ── DE DÓNDE SALEN: hacia donde mira el torso, siempre horizontal ─────────────────────────────────────────────────

func _front() -> Basis:
	return Basis(Vector3.UP, mech.yaw() if mech != null else global_rotation.y)


## HACIA DONDE TIRA LA AMETRALLADORA (mundo, plano).
func gun_way() -> Vector3:
	return _front() * Basis(Vector3.UP, _gun_turn) * Vector3.FORWARD


## LA AMETRALLADORA TIRA DERECHO DESDE SU TORRETA: su línea sale de ahí, no del centro de la meca.
func _gun_model_yaw() -> float:
	return _gun_turn


## Dónde arranca su línea, a la altura `height`.
func gun_floor(height: float) -> Vector3:
	var at := global_transform * _gun_at
	return Vector3(at.x, height, at.z)


## SU ZONA: una línea desde la torreta que termina en el círculo del alcance alrededor de la meca, así nunca llega más lejos
## que las demás habilidades ni sale de lo que se ve.
func gun_zone() -> Dictionary:
	var zone := MechSkills.minigun()
	var off := gun_floor(mech.global_position.y) - mech.global_position
	var along := off.dot(gun_way())
	var limit := float(zone["length"])
	zone["length"] = -along + sqrt(maxf(along * along - off.length_squared() + limit * limit, 0.0))
	return zone


func _pod_model_yaw() -> float:
	var goal := Basis(Vector3.UP, _pod_turn) * Vector3.FORWARD * MISSILE_MEET
	return atan2(_pod_at.x - goal.x, _pod_at.z - goal.z)


## HACIA DONDE SALEN LOS MISILES (mundo, plano).
func missile_way() -> Vector3:
	return _front() * Basis(Vector3.UP, _pod_turn) * Vector3.FORWARD


func minigun_muzzle() -> Transform3D:
	var tip := Basis(Vector3.UP, _gun_turn) * Vector3(0.0, 0.0, -MUZZLE)
	return Transform3D(Basis.looking_at(gun_way(), Vector3.UP), global_transform * (_gun_at + tip))


## La boca del tubo `index`: de tres por dos, de arriba a la izquierda.
func missile_mouth(index: int) -> Transform3D:
	var spot := Vector3((index % 3 - 1) * POD_CELL, (0.5 - index / 3) * POD_CELL, -POD_CELL * 2.5 - 0.02) * MODEL_SCALE
	var turned := Basis(Vector3.UP, _pod_model_yaw()) * spot
	return _converging(global_transform * (_pod_at + turned), missile_way(), MISSILE_MEET)


## LAS ARMAS VAN A LOS COSTADOS PERO APUNTAN A LA LÍNEA DEL CENTRO: desde `origin`, plano, hacia el punto a `meters` del
## centro del torso en la dirección `way`. En paralelo, un blanco justo al frente les quedaba al costado.
func _converging(origin: Vector3, way: Vector3, meters: float) -> Transform3D:
	var goal := mech.global_position + way * meters
	goal.y = origin.y
	return Transform3D(Basis.looking_at((goal - origin).normalized(), Vector3.UP), origin)


## ── LOS DISPAROS, en todas las máquinas ───────────────────────────────────────────────────────────────────────────

## UNA BALA (sólo se ve): si la zona tiene un blanco, va hacia él y termina en su borde, así lo que se ve es lo que pega.
func shoot_bullet(at: Transform3D) -> void:
	var aimed := at
	# Sin blanco, la bala se apaga al final de la zona: nada sale de lo que se ve.
	var zone := gun_zone()
	var reach := maxf(float(zone["length"]) - MUZZLE, 0.1)
	var target := HitTarget.first_in_line(get_tree(), gun_floor(at.origin.y), gun_way(), zone["length"], zone["size"],
		_own_bodies())
	if target != null:
		var goal := target.surface(at.origin) + at.basis.x * randf_range(-0.5, 0.5) * target.flat_radius() \
			+ Vector3.UP * randf_range(-0.6, 0.6)
		var way := goal - at.origin
		if way.length() > 0.1:
			aimed = Transform3D(Basis.looking_at(way.normalized(), Vector3.UP), at.origin)
			reach = way.length()
	if NetFollow.online(self):
		_bullet.rpc(aimed, reach, target != null, weapons.bullet_kind)
	else:
		_bullet(aimed, reach, target != null, weapons.bullet_kind)


@rpc("any_peer", "call_local", "unreliable")
func _bullet(at: Transform3D, reach: float, lands: bool, kind: int) -> void:
	var bullet := GunnerBullet.new()
	bullet.skip = _own_bodies()
	bullet.reach = reach
	bullet.lands = lands
	if kind != SupplyKinds.Kind.BULLETS:
		bullet.tint = SupplyKinds.tag_color(kind).lightened(0.25)
	get_tree().current_scene.add_child(bullet)
	bullet.global_transform = at
	var sounds_node := MechSounds.of(self)
	if sounds_node != null:
		sounds_node.pulse(MechSounds.MINIGUN_FIRE, self)
	GunnerFx.muzzle(at.origin, 0.3)


## Lo que vuela, lo que explota y lo que se guía: va en el mensaje, para que sea igual en todas.
func _missile_shape() -> Array:
	var knobs := HitSettings.current
	return [knobs.missile_reach * MechSkills.reach_limit(), float(MechSkills.missile()["size"]), knobs.missile_guide,
		weapons.missile_kind]


## UN MISIL, encaminado por la mira de `launcher`. Su velocidad y lo que dobla van en el mensaje: así vuela igual en todas.
func shoot_missile(at: Transform3D, launcher: int) -> void:
	var knobs := HitSettings.current
	if NetFollow.online(self):
		_missile.rpc(at, launcher, knobs.missile_speed, knobs.missile_turn, _missile_shape())
	else:
		_missile(at, launcher, knobs.missile_speed, knobs.missile_turn, _missile_shape())


@rpc("any_peer", "call_local", "reliable")
func _missile(at: Transform3D, launcher: int, top: float, turn: float, shape: Array) -> void:
	MechSounds.hit(self, MechSounds.MISSILE_LAUNCH, self, randf_range(0.95, 1.05))
	var missile := GunnerMissile.new()
	missile.skip = _own_bodies()
	missile.launcher = launcher
	missile.top = top
	missile.turn = turn
	missile.reach = float(shape[0])
	missile.radius = float(shape[1])
	missile.guide = float(shape[2])
	missile.kind = int(shape[3])
	missile.steer = _missile_goal.bind(launcher)
	get_tree().current_scene.add_child(missile)
	missile.global_transform = at
	GunnerFx.muzzle(at.origin, 0.5)


func _missile_goal(launcher: int) -> Vector3:
	return aim.point_of(launcher) if aim != null else Vector3.INF


## Lo que sus tiros no tienen que tocar: la meca, con todo lo que choca de ella.
func _own_bodies() -> Array[RID]:
	if _skip.is_empty() and mech != null:
		_skip.append(mech.get_rid())
		for found in mech.find_children("*", "CollisionObject3D", true, false):
			_skip.append((found as CollisionObject3D).get_rid())
	return _skip.duplicate()


## ── LO QUE SE VE ─────────────────────────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if _barrels != null:
		_barrels.rotate_object_local(Vector3.BACK, weapons.spin * TAU * BARREL_TURNS * delta)
	if _gun_model != null:
		if not is_mine():
			var follow := 1.0 - exp(-GUN_FOLLOW * delta)
			_gun_turn = lerp_angle(_gun_turn, _gun_told, follow)
			_pod_turn = lerp_angle(_pod_turn, _pod_told, follow)
		_gun_model.rotation.y = _gun_model_yaw()
		_pod_model.rotation.y = _pod_model_yaw()


## CADA TORRETA GIRA hacia la mira de quien la usa, por el lado más corto; sin nadie, vuelve al frente.
func _turret(now: float, slot: int, delta: float) -> float:
	var goal := 0.0
	if aim != null and aim.crew.aimer_of(slot) != 0:
		var point := aim.point_of(aim.crew.aimer_of(slot))
		if point.is_finite():
			# La ametralladora apunta desde su torreta; los misiles se guían solos desde el centro.
			var to := point - (gun_floor(mech.global_position.y) if slot == MechCrew.MINIGUN else mech.global_position)
			# Con la mira encima de la meca no hay dirección: se queda como está.
			goal = now
			if Vector2(to.x, to.z).length() > 1.0:
				goal = wrapf(atan2(-to.x, -to.z) - mech.yaw(), -PI, PI)
	return wrapf(rotate_toward(now, goal, deg_to_rad(HitSettings.current.gun_turn) * delta), -PI, PI)


## LA ZONA DE LA AMETRALLADORA (22/11/2026): una línea plana que, mientras tira balas, le pega al primer blanco a la vista, de
## a pulsos. La decide el host.
func _zone_step(delta: float) -> void:
	_zone_clock = maxf(_zone_clock - delta, 0.0)
	if _zone_clock > 0.0 or not weapons.firing() or ProjectileField.is_client(self):
		return
	_zone_clock = ZONE_PULSE
	var muzzle := minigun_muzzle()
	var way := gun_way()
	var zone := gun_zone()
	var from := gun_floor(muzzle.origin.y)
	var kind := weapons.bullet_kind
	var targets: Array[HitTarget] = []
	if kind == SupplyKinds.Kind.PIERCING:
		targets = HitTarget.all_in_line(get_tree(), from, way, zone["length"], zone["size"], _own_bodies())
	else:
		var first := HitTarget.first_in_line(get_tree(), from, way, zone["length"], zone["size"], _own_bodies())
		if first != null:
			targets.append(first)
	var power := PIERCING_POWER if kind == SupplyKinds.Kind.PIERCING else 1.0
	for target in targets:
		target.strike("minigun", power, ZONE_STRENGTH * power, target.surface(muzzle.origin), way)
		if kind == SupplyKinds.Kind.INCENDIARY:
			target.effects.ignite()
		elif kind == SupplyKinds.Kind.ELECTRIC:
			target.effects.charge()


## EL DUEÑO MANDA EL CALOR Y LA MUNICIÓN, para los cuadrados de las demás máquinas.
func _physics_process(delta: float) -> void:
	if is_mine():
		_gun_turn = _turret(_gun_turn, MechCrew.MINIGUN, delta)
		_pod_turn = _turret(_pod_turn, MechCrew.MISSILES, delta)
	_zone_step(delta)
	if not is_mine() or not NetFollow.online(self):
		return
	_state_clock -= delta
	if _state_clock <= 0.0:
		_state_clock = 1.0 / STATE_RATE
		_weapons_state.rpc(weapons.get_state(), _gun_turn, _pod_turn)


@rpc("any_peer", "call_remote", "unreliable_ordered")
func _weapons_state(state: Array, gun_turn: float, pod_turn: float) -> void:
	if mech != null and multiplayer.get_remote_sender_id() == mech.net.authority:
		weapons.apply_state(state)
		_gun_told = gun_turn
		_pod_told = pod_turn


func _holder(at: Vector3) -> Node3D:
	var holder := Node3D.new()
	holder.position = at
	holder.scale = Vector3.ONE * MODEL_SCALE
	add_child(holder)
	return holder


## LA AMETRALLADORA: el motor atrás, seis caños en rueda con dos aros, y el tambor de munición abajo.
func _minigun(parent: Node3D) -> void:
	Clay.box(parent, Vector3(0.14, 0.14, 0.22), Vector3(0.0, 0.0, 0.06), GUNMETAL)
	Clay.cylinder(parent, 0.075, 0.12, Vector3(0.0, 0.0, -0.1), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	_barrels = Node3D.new()
	_barrels.name = "Caños"
	parent.add_child(_barrels)
	for k in 6:
		var angle := TAU * k / 6.0
		var spot := Vector3(cos(angle), sin(angle), 0.0) * 0.045
		Clay.cylinder(_barrels, 0.014, 0.62, spot + Vector3(0.0, 0.0, -0.45), CageCabin.RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	for z: float in [-0.42, -0.72]:
		Clay.cylinder(_barrels, 0.068, 0.025, Vector3(0.0, 0.0, z), CageCabin.METAL, Vector3(90.0, 0.0, 0.0))
	Clay.cylinder(parent, 0.09, 0.12, Vector3(0.0, -0.17, 0.05), CageCabin.YELLOW.darkened(0.25), Vector3(0.0, 0.0, 90.0))
	Clay.box(parent, Vector3(0.05, 0.12, 0.04), Vector3(0.0, -0.08, -0.02), GUNMETAL)


## LA CAJA DE MISILES: tres por dos tubos, con las bocas adelante (−Z) y la tapa amarilla.
func _missiles(parent: Node3D) -> void:
	var size := Vector3(3.0 * POD_CELL + 0.03, 2.0 * POD_CELL + 0.03, POD_CELL * 5.0)
	Clay.box(parent, size, Vector3.ZERO, CageCabin.METAL)
	for c in 3:
		for k in 2:
			var spot := Vector3((c - 1.0) * POD_CELL, (k - 0.5) * POD_CELL, -size.z * 0.5 - 0.005)
			Clay.cylinder(parent, POD_CELL * 0.36, 0.012, spot, CageCabin.HOLE, Vector3(90.0, 0.0, 0.0))
			Clay.cylinder(parent, POD_CELL * 0.2, 0.014, spot, MISSILE_TIP, Vector3(90.0, 0.0, 0.0))
	Clay.box(parent, Vector3(size.x + 0.01, 0.02, size.z * 0.6), Vector3(0.0, size.y * 0.5 + 0.01, 0.0), CageCabin.YELLOW)
