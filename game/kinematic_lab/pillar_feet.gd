class_name PillarFeet
extends Node3D

## LOS DOS PIES DEL CUBO CINEMÁTICO (13/11/2026) — EXPERIMENTO: cajas cinemáticas CON CHOQUE DE VERDAD que dan pasos
## debajo del cubo. El usuario: «tal vez podemos hacer que las piernas tengan colisión y que si pisan algo, lo rompen y
## lo achatan».
##   · DE COSTADO, PATEAN: lo suelto que encuentran al avanzar lo empuja el motor (para él pesan infinito). A qué
##     velocidad sale lo pateado es lo que hay que mirar («quiero ver a qué velocidad patea cosas y vemos después»).
##   · DE ARRIBA, PISAN Y ACHATAN (`flatten`): lo suelto que queda DEBAJO de un pie que baja no se aprieta contra el
##     piso —eso era lo que hacía explotar al motor—: suena, larga polvo y desaparece («por ahora… un sonido, una
##     partícula… y que lo aplanado desaparezca»; «todo lo no estático se achata»).
##   · ENTRE LOS PIES QUEDA LIBRE: por ahí se pasa.
## Los pasos son simples: el pie que quedó más lejos de su lugar sale hacia donde va a estar, en arco.
## *Los personajes todavía no se achatan (hay que ver cómo muere uno): se saltean.*

## Un pie: ancho, alto y largo (m).
const FOOT := Vector3(2.0, 1.2, 3.4)
## En el aire, a qué velocidad se juntan debajo del cubo (m/s).
const GATHER := 6.0

## Cuántas cosas acható (para mirar).
var flattened := 0
## Dónde nacen los pies (mundo): lo pone el cubo antes de agregarlos al árbol.
var born_at := Transform3D()

var _feet: Array[Dictionary] = []
var _swing := -1
var _clock := 0.0
var _from := Vector3.ZERO
var _under := BoxShape3D.new()
var _last_place := Vector3.ZERO


func _ready() -> void:
	top_level = true
	global_transform = Transform3D()
	_under.size = Vector3(FOOT.x, FOOT.y + 0.5, FOOT.z)
	for i in 2:
		var body := AnimatableBody3D.new()
		# NACE YA EN SU LUGAR (`born_at`), y sin sincronizar hasta que `place_now` lo acomode. *Un cuerpo entra a la física
		# donde está al agregarlo al árbol: naciendo en el origen del mundo estaba ahí un paso entero, y a una caja
		# que hubiera justo ahí la reventaba (medido el 13/11/2026: a 143 m/s, con el cubo quieto a 22 m).*
		body.sync_to_physics = false
		body.name = "Pie %d" % i
		body.transform = born_at
		add_child(body)
		Clay.solid(body, FOOT, Vector3.ZERO, Clay.DARK.lightened(0.15))
		var leg := Clay.limb(self, 0.7, 1.0, Vector3.ZERO, Clay.METAL.darkened(0.25))
		_feet.append({"body": body, "leg": leg, "at": Vector3.ZERO, "last_y": 0.0})


## LOS PONE debajo del cubo, en `place` (el punto del piso) mirando a `yaw`, SIN BARRER el camino: al armarlos y cada vez
## que al cubo se lo pone en otro lugar. *Un cuerpo cinemático que se mueve de un paso al otro barre lo que hay en el
## medio a esa velocidad: los pies cruzaban 22 m en un paso y las cajas salían a 430 m/s (medido el 13/11/2026).*
func place_now(k: PillarSettings, place: Vector3, yaw: float) -> void:
	var turn := Basis(Vector3.UP, yaw)
	_swing = -1
	_last_place = place
	for i in 2:
		var foot := _feet[i]
		var side := -1.0 if i == 0 else 1.0
		foot["at"] = place + turn * Vector3(side * k.stance, 0.0, 0.0)
		var centre := (foot["at"] as Vector3) + Vector3.UP * FOOT.y * 0.5
		foot["last_y"] = centre.y
		var body := foot["body"] as AnimatableBody3D
		body.sync_to_physics = false
		body.global_transform = Transform3D(turn, centre)
		body.sync_to_physics = true


## UN PASO DE LA FÍSICA: `place` es el punto del piso bajo el cubo (o adonde llegaría, en el aire), `yaw` hacia dónde
## mira, `flat` su velocidad de costado, `grounded` si está apoyado y `hip` la altura de la cara de abajo del cubo.
func step(k: PillarSettings, delta: float, place: Vector3, yaw: float, flat: Vector3, grounded: bool, hip: float) -> void:
	var turn := Basis(Vector3.UP, yaw)
	for i in 2:
		var foot := _feet[i]
		var side := -1.0 if i == 0 else 1.0
		var home := place + turn * Vector3(side * k.stance, 0.0, 0.0) + flat * k.step_time * 0.5
		if not grounded:
			# En el aire, van con el cubo y se juntan debajo de a poco (`GATHER`): de un salto barrerían lo que hay.
			var under := turn * Vector3(side * k.stance, 0.0, 0.0)
			var offset := (foot["at"] as Vector3) - _last_place
			foot["at"] = place + offset.move_toward(under, GATHER * delta)
			if _swing == i:
				_swing = -1
			continue
		if _swing == i:
			_clock += delta
			var share := clampf(_clock / maxf(k.step_time, 0.05), 0.0, 1.0)
			var eased := smoothstep(0.0, 1.0, share)
			foot["at"] = _from.lerp(home, eased) + Vector3.UP * sin(share * PI) * k.step_height
			if share >= 1.0:
				foot["at"] = home
				_swing = -1
	if _swing < 0 and grounded:
		# Sale el que quedó más lejos de su lugar, si quedó lejos.
		var worst := -1
		var far := k.step_length * 0.5
		for i in 2:
			var side := -1.0 if i == 0 else 1.0
			var home := place + turn * Vector3(side * k.stance, 0.0, 0.0) + flat * k.step_time * 0.5
			var gap := Vector2(home.x - (_feet[i]["at"] as Vector3).x, home.z - (_feet[i]["at"] as Vector3).z).length()
			if gap > far:
				far = gap
				worst = i
		if worst >= 0:
			_swing = worst
			_clock = 0.0
			_from = _feet[worst]["at"]
	_last_place = place
	for i in 2:
		var foot := _feet[i]
		var side := -1.0 if i == 0 else 1.0
		var at: Vector3 = foot["at"]
		var centre := at + Vector3.UP * FOOT.y * 0.5
		# Si baja, lo que tiene debajo se achata antes de apretarlo.
		if centre.y < float(foot["last_y"]) - 0.0001:
			_stomp(Transform3D(turn, centre))
		foot["last_y"] = centre.y
		(foot["body"] as AnimatableBody3D).global_transform = Transform3D(turn, centre)
		var top := place + turn * Vector3(side * k.stance, hip, 0.0)
		var leg := foot["leg"] as Node3D
		leg.transform = MechBody.segment(top, centre, turn.z)
		leg.scale = Vector3(1.0, 1.0, maxf(top.distance_to(centre), 0.1))


## LO QUE QUEDA DEBAJO de un pie que baja (en `where`, su centro): se achata.
func _stomp(where: Transform3D) -> void:
	var space := get_world_3d().direct_space_state
	for body in AreaStrike.loose_in(space, _under, where * Transform3D(Basis(), Vector3.DOWN * 0.25)):
		# Para un pie, «debajo» es más abajo que su medio: lo bajo que toca al bajar, aunque sea con el borde.
		if PillarFeet.is_under(body, where, FOOT, 0.0) and PillarFeet.flatten(body):
			flattened += 1


## SI `body` ESTÁ DEBAJO de una caja de `size` centrada en `where` que baja: su medio queda más abajo que `level` (en la
## caja; por defecto, su cara de abajo), y se pisan de costado aunque sea en parte. Lo que está AL LADO, a su altura,
## no: eso se patea. *Contando sólo lo que tenía el centro adentro de la planta del pie, o sólo lo que estaba más abajo
## que la suela, una caja baja pisada a medias quedaba en cuña contra el piso y salía a más de 100 m/s (medido el
## 13/11/2026).*
static func is_under(body: RigidBody3D, where: Transform3D, size: Vector3, level := -INF) -> bool:
	var local := where.affine_inverse() * body.global_position
	var half := PillarFeet.half_of(body)
	var below := -size.y * 0.5 if level == -INF else level
	return local.y < below and absf(local.x) < size.x * 0.5 + half and absf(local.z) < size.z * 0.5 + half


## Medio ancho de lo suelto, más o menos (m): de su caja de choque.
static func half_of(body: RigidBody3D) -> float:
	for child in body.get_children():
		var holder := child as CollisionShape3D
		if holder != null and holder.shape is BoxShape3D:
			var size := (holder.shape as BoxShape3D).size
			return maxf(size.x, size.z) * 0.5
	return 0.3


## ACHATA `body` (ver arriba): un sonido, polvo, y desaparece. Devuelve si lo acható (un personaje, todavía no).
static func flatten(body: RigidBody3D) -> bool:
	if body.is_queued_for_deletion() or PillarFeet._is_person(body):
		return false
	var holder := body.get_parent() as Node3D
	if holder != null:
		var at := Node3D.new()
		holder.add_child(at)
		at.global_position = Vector3(body.global_position.x, body.global_position.y, body.global_position.z)
		Sounds.play(&"aplastado", at, 0.6, 2.0)
		for make: Callable in [ParticleSystems.impact_dust, ParticleSystems.explosion_sparks]:
			var burst: GPUParticles3D = make.call(ParticleMeshes.Kind.LINE if make == ParticleSystems.explosion_sparks
				else ParticleMeshes.Kind.SPHERE, 2.5)
			at.add_child(burst)
			burst.basis = Basis(Vector3.RIGHT, PI * 0.5)
			burst.restart()
		at.get_tree().create_timer(3.0).timeout.connect(at.queue_free)
	body.queue_free()
	return true


## Si `body` es parte de un personaje (su cápsula o un hueso de su ragdoll).
static func _is_person(body: Node) -> bool:
	var node := body
	while node != null:
		if node is BoneInstantiator:
			return true
		node = node.get_parent()
	return false
