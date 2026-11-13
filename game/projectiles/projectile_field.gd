class_name ProjectileField
extends Node3D

## LOS PROYECTILES Y LAS ZONAS QUE PEGAN DE UN LUGAR, POR RED (13/11/2026; las zonas, en AreaStrike). Los usan los jefes
## y, después, las armas de la meca propia (el usuario: «esto después lo vamos a reusar para meca propia y [jefes] enemigos… que soporte sincronización online»).
##
## UN PROYECTIL ES UNA TRAYECTORIA CONOCIDA: de dónde sale, adónde va y cuánto tarda (ver Missile). Con eso cada máquina
## lo dibuja sola, sin mandar posiciones por la red: se manda UN mensaje por proyectil.
##   · LANZAR SE LE PIDE AL HOST (`launch`, desde cualquier máquina): el host le pone un número y lo ANUNCIA a todos,
##     él incluido; cada uno arma su Missile y lo hace volar. Sin red, es lo mismo en una sola máquina.
##   · LO QUE SE VE (la marca en el piso, la estela, la explosión) lo hace cada máquina.
##   · LO QUE HACE (empujar lo que agarra la explosión) LO APLICA SÓLO EL HOST, que es quien manda en la física. Avisa
##     con `exploded`, en todas las máquinas.
## Tiene que estar en el mismo lugar del árbol en todas las máquinas (el anuncio va por su camino): un hijo fijo de la
## parcela o del mapa, no algo que aparece en una sola.
## *Lo que falta: quien se une a mitad de una andanada no ve los que ya estaban en el aire (duran unos segundos).*

signal exploded(at: Vector3, kind: Missile.Kind)

var _next := 0


## PIDE UN PROYECTIL de `kind` que sale de `from` y cae en `to` (mundo) en `flight` segundos, a los `delay` segundos;
## el guiado persigue a `target`; no le pega a los de `team` (ver Missile).
func launch(kind: Missile.Kind, from: Vector3, to: Vector3, flight: float, delay := 0.0, target: Node3D = null,
		team := "") -> void:
	var path := get_path_to(target) if target != null else NodePath()
	if ProjectileField.is_client(self):
		_request.rpc_id(1, kind, from, to, flight, delay, path, team)
		return
	_next += 1
	_announce.rpc(_next, kind, from, to, flight, delay, path, team)


## PIDE UNA ZONA QUE PEGA (ver AreaStrike, y lo que dice su `spec`). Como `launch`: la decide el host y la ven todos.
func strike(spec: Dictionary) -> void:
	if ProjectileField.is_client(self):
		_request_strike.rpc_id(1, spec)
		return
	_next += 1
	_announce_strike.rpc(_next, spec)


@rpc("any_peer", "reliable")
func _request_strike(spec: Dictionary) -> void:
	if multiplayer.is_server():
		strike(spec)


@rpc("authority", "call_local", "reliable")
func _announce_strike(id: int, spec: Dictionary) -> void:
	var zone := AreaStrike.new()
	zone.name = "Zona %d" % id
	zone.spec = spec
	add_child(zone)


## Si esta máquina es un cliente de una sesión (no el host, y no sin red): entonces no decide nada.
static func is_client(node: Node) -> bool:
	return node.multiplayer.has_multiplayer_peer() and not node.multiplayer.is_server()


@rpc("any_peer", "reliable")
func _request(kind: int, from: Vector3, to: Vector3, flight: float, delay: float, path: NodePath, team: String) -> void:
	if multiplayer.is_server():
		launch(kind as Missile.Kind, from, to, flight, delay, get_node_or_null(path) as Node3D, team)


@rpc("authority", "call_local", "reliable")
func _announce(id: int, kind: int, from: Vector3, to: Vector3, flight: float, delay: float, path: NodePath,
		team: String) -> void:
	var missile := Missile.new()
	missile.name = "Proyectil %d" % id
	missile.kind = kind as Missile.Kind
	missile.from = from
	missile.to = to
	missile.flight = flight
	missile.delay = delay
	missile.target = get_node_or_null(path) as Node3D if not path.is_empty() else null
	missile.team = team
	missile.landed.connect(_landed.bind(missile))
	add_child(missile)


## LLEGÓ: la explosión, en todas; el empujón, sólo en el host.
func _landed(missile: Missile) -> void:
	if not ProjectileField.is_client(self):
		missile.blast()
	exploded.emit(missile.to, missile.kind)
