class_name BossNet
extends NetFollow

## ── UN JEFE POR LA RED (18/11/2026; módulo Jefes; plan de la partida en red, paso 8) ────────────────────────────────
## Lo simula EL HOST: su cabeza (BrawlerBrain) piensa sólo ahí, decide los ataques y los golpes, y la vida la decide el
## host (Health). Las demás máquinas no lo simulan: ponen su cuerpo donde dice el host (lo común de NetFollow) y arman
## con eso su esqueleto, sus capas y su caja de golpe, igual que en el host. Viaja lo físico y lo que se ve del cuerpo:
## dónde está, el rumbo de las orugas y de la cintura, la pose, el trompo, el horno y la ira, si vuela, a cuánto va y el
## resorte. Lo que se ve de sus ataques, abajo («Lo que se ve de sus ataques»).

var boss: Brawler = null


func _state_now() -> Array:
	return [boss.global_position, boss.hull_yaw, boss.waist_yaw, int(boss.pose), boss.spin, boss.furnace, boss.rage,
		boss.aloft(), boss.speed, boss.body_spring.y, boss.body_spring.xz]


func _apply(from: Array, to: Array, share: float, _ahead: float, _delta: float) -> void:
	boss.follow_net(from, to, share)


## ── LO QUE SE VE DE SUS ATAQUES (18/11/2026) ─────────────────────────────────────────────────────────────────────
## Cada efecto (las zonas en el piso, la piedra, el fuego, la onda, la mano del gancho, las bombas) se anima solo con
## unas pocas órdenes (armarse, apuntar, lanzar, tirar, romperse). LOS PODERES NO LOS ARMAN DIRECTO: los piden acá
## (`fx_make`) y les dan las órdenes acá (`fx_do`, `fx_set`). En el host, cada efecto lleva un número y lo mismo va a
## las demás máquinas: arman su copia, le dan las mismas órdenes, y se borra cuando se borra el del host. Las órdenes de
## cada paso (apuntar, sostener la piedra, el aviso del fuego) van sin garantía (`steady`); las demás, con garantía. El
## daño lo sigue decidiendo sólo el host (sus poderes miran sus efectos). Sin red, sólo los arma y les da las órdenes.

var _fx := {}
var _next_fx := 1


## ARMA un efecto `kind` («flame», «hook», «wave», «rock», «circle», «ring», «shot», «toss») con `args`.
func fx_make(kind: String, args: Array = []) -> Node3D:
	var made := _build(kind, args)
	if networked() and multiplayer.is_server():
		var id := _next_fx
		_next_fx += 1
		_fx[id] = made
		made.set_meta("fx", id)
		made.tree_exiting.connect(_fx_gone.bind(id))
		_fx_new.rpc(id, kind, args)
	return made


## UNA ORDEN a un efecto: `method` con `args`, acá y en las demás.
func fx_do(node: Object, method: String, args: Array = [], steady := false) -> void:
	node.callv(method, args)
	if not node.has_meta("fx") or not networked():
		return
	if steady:
		_fx_steady.rpc(int(node.get_meta("fx")), method, args)
	else:
		_fx_call.rpc(int(node.get_meta("fx")), method, args)


func fx_set(node: Object, property: String, value: Variant) -> void:
	fx_do(node, "set", [property, value])


## UNA NUBE DE TIERRA (BossBursts.dirt), acá y en las demás.
func fx_dirt(at: Vector3, size: float) -> void:
	BossBursts.dirt(boss.get_parent(), at, size)
	if networked() and multiplayer.is_server():
		_fx_dirt.rpc(at, size)


func _build(kind: String, args: Array) -> Node3D:
	var world := boss.get_parent()
	var made: Node3D = null
	match kind:
		"flame":
			made = BrawlerFlame.new()
			made.name = "Lanzallamas"
		"hook":
			made = BrawlerHook.new()
			made.name = "Mano"
		"wave":
			made = BrawlerWave.new()
			made.name = "Onda"
		"rock":
			made = BrawlerRock.new()
			made.name = "Piedra"
		"orbs":
			made = BossOrbField.new()
			made.name = "Bolitas"
		"circle":
			return BossZone.circle(world, float(args[0]))
		"ring":
			return BossZone.ring(world, float(args[0]), float(args[1]), float(args[2]), float(args[3]))
		"shot":
			return BossShot.launch(world, args[0], args[1], float(args[2]), float(args[3]), float(args[4]))
		"toss":
			return BossShot.toss(world, args[0], args[1], float(args[2]), int(args[3]), float(args[4]), float(args[5]),
				[boss.solid()])
	world.add_child(made)
	return made


func _fx_gone(id: int) -> void:
	_fx.erase(id)
	if is_inside_tree() and networked():
		_fx_free.rpc(id)


@rpc("authority", "call_remote", "reliable")
func _fx_new(id: int, kind: String, args: Array) -> void:
	_fx[id] = _build(kind, args)


@rpc("authority", "call_remote", "reliable")
func _fx_call(id: int, method: String, args: Array) -> void:
	# Sin tipo: la copia pudo haberse borrado sola (una bomba que ya cayó).
	var node: Variant = _fx.get(id)
	if is_instance_valid(node):
		(node as Object).callv(method, args)


@rpc("authority", "call_remote", "unreliable_ordered")
func _fx_steady(id: int, method: String, args: Array) -> void:
	_fx_call(id, method, args)


@rpc("authority", "call_remote", "reliable")
func _fx_free(id: int) -> void:
	var node: Variant = _fx.get(id)
	_fx.erase(id)
	if is_instance_valid(node):
		(node as Node).queue_free()


@rpc("authority", "call_remote", "reliable")
func _fx_dirt(at: Vector3, size: float) -> void:
	BossBursts.dirt(boss.get_parent(), at, size)
