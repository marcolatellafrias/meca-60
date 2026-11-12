class_name ProjectileField
extends Node3D

## LOS PROYECTILES DE UN LUGAR, POR RED (13/11/2026). Los usan los jefes y, después, las armas de la meca propia (el
## usuario: «esto después lo vamos a reusar para meca propia y [jefes] enemigos… que soporte sincronización online»).
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


## PIDE UN PROYECTIL de `kind` que sale de `from` y cae en `to` (mundo) en `flight` segundos.
func launch(kind: Missile.Kind, from: Vector3, to: Vector3, flight: float) -> void:
	if ProjectileField.is_client(self):
		_request.rpc_id(1, kind, from, to, flight)
		return
	_next += 1
	_announce.rpc(_next, kind, from, to, flight)


## Si esta máquina es un cliente de una sesión (no el host, y no sin red): entonces no decide nada.
static func is_client(node: Node) -> bool:
	return node.multiplayer.has_multiplayer_peer() and not node.multiplayer.is_server()


@rpc("any_peer", "reliable")
func _request(kind: int, from: Vector3, to: Vector3, flight: float) -> void:
	if multiplayer.is_server():
		launch(kind as Missile.Kind, from, to, flight)


@rpc("authority", "call_local", "reliable")
func _announce(id: int, kind: int, from: Vector3, to: Vector3, flight: float) -> void:
	var missile := Missile.new()
	missile.name = "Proyectil %d" % id
	missile.kind = kind as Missile.Kind
	missile.from = from
	missile.to = to
	missile.flight = flight
	missile.landed.connect(_landed.bind(missile))
	add_child(missile)


## LLEGÓ: la explosión, en todas; el empujón, sólo en el host.
func _landed(missile: Missile) -> void:
	if not ProjectileField.is_client(self):
		missile.blast()
	exploded.emit(missile.to, missile.kind)
