class_name StompFeet
extends Node3D

## LOS PIES CON CHOQUE (13/11/2026): cuerpos cinemáticos que van donde están los pies de las piernas (BodyLegs), con
## CHOQUE DE VERDAD. El usuario: «que las piernas tengan colisión y que si pisan algo, lo rompen y lo achatan». Los usa
## la meca cinemática (ver KinematicMover): la física los tiene sólo de dibujo.
##   · DE COSTADO, PATEAN: lo suelto que encuentran al avanzar lo empuja el motor (para él pesan infinito).
##   · DE ARRIBA, PISAN Y ACHATAN (`flatten`): lo suelto que queda DEBAJO de un pie que baja no se aprieta contra el
##     piso —eso era lo que hacía explotar al motor—: suena, larga polvo y desaparece («por ahora… un sonido, una
##     partícula… y que lo aplanado desaparezca»; «todo lo no estático se achata»).
## *Eran los del cubo del Laboratorio (PillarFeet), con sus propios pasos, hasta el 13/11/2026: ahora siguen a las piernas
## de la meca, que ya dan los pasos.*
## *Los personajes todavía no se achatan (hay que ver cómo muere uno): se saltean.*

## Cuántas cosas acható (para mirar).
var flattened := 0

var _feet: Array[AnimatableBody3D] = []
var _last_y: Array[float] = []
var _under := BoxShape3D.new()
var _size := Vector3.ONE


## ARMA los pies, de `size`, ya en `places` (mundo): un cuerpo entra a la física donde está al agregarlo al árbol, y si
## nace en otro lado y salta a su lugar, barre lo que hay en el medio. *Naciendo en el origen del mundo, a una caja que
## estaba ahí la reventaba (medido: a 143 m/s).*
func build(size: Vector3, places: Array[Transform3D]) -> void:
	top_level = true
	global_transform = Transform3D()
	_size = size
	_under.size = Vector3(size.x, size.y + 0.5, size.z)
	for i in places.size():
		var body := AnimatableBody3D.new()
		body.name = "Pie %d" % i
		body.sync_to_physics = false
		body.transform = places[i]
		add_child(body)
		Clay.shape_box(body, size, Vector3.ZERO)
		body.sync_to_physics = true
		_feet.append(body)
		_last_y.append(places[i].origin.y)


## CADA PASO: van a `places` (mundo); lo que queda debajo de uno que baja, se achata antes.
func follow(places: Array[Transform3D]) -> void:
	for i in mini(places.size(), _feet.size()):
		var place := places[i]
		if place.origin.y < _last_y[i] - 0.0001:
			_stomp(place)
		_last_y[i] = place.origin.y
		_feet[i].global_transform = place


## LOS PONE en `places` sin barrer el camino (al poner la meca en otro lugar).
func place_now(places: Array[Transform3D]) -> void:
	for i in mini(places.size(), _feet.size()):
		_feet[i].sync_to_physics = false
		_feet[i].global_transform = places[i]
		_feet[i].sync_to_physics = true
		_last_y[i] = places[i].origin.y


## Los cuerpos de los pies (para que lo que va con la meca no los cuente).
func bodies() -> Array[AnimatableBody3D]:
	return _feet


## LO QUE QUEDA DEBAJO de un pie que baja (en `where`, su centro): se achata.
func _stomp(where: Transform3D) -> void:
	var space := get_world_3d().direct_space_state
	for body in AreaStrike.loose_in(space, _under, where * Transform3D(Basis(), Vector3.DOWN * 0.25)):
		# Para un pie, «debajo» es más abajo que su medio: lo bajo que toca al bajar, aunque sea con el borde.
		if StompFeet.is_under(body, where, _size, 0.0) and StompFeet.flatten(body, get_parent()):
			flattened += 1


## SI `body` ESTÁ DEBAJO de una caja de `size` centrada en `where` que baja: su medio queda más abajo que `level` (en la
## caja; por defecto, su cara de abajo), y se pisan de costado aunque sea en parte. Lo que está AL LADO, a su altura,
## no: eso se patea. *Contando sólo lo que tenía el centro adentro de la planta, o sólo lo que estaba más abajo que la
## suela, una caja baja pisada a medias quedaba en cuña contra el piso y salía a más de 100 m/s (medido el 13/11/2026).*
static func is_under(body: RigidBody3D, where: Transform3D, size: Vector3, level := -INF) -> bool:
	if body is BalanceBody:
		return false
	var local := where.affine_inverse() * body.global_position
	var half := StompFeet.half_of(body)
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


## ACHATA `body` (ver arriba): un sonido, polvo, y desaparece. Devuelve si lo acható (un personaje, todavía no). LO DE
## `by` MISMO NO (quien pisa: lo que cuelga de él, como las piezas de un brazo con músculos que quedaron debajo de su
## caja; 17/11/2026: la meca se achataba el antebrazo y el brazo seguía andando con la pieza borrada).
static func flatten(body: RigidBody3D, by: Node) -> bool:
	if body.is_queued_for_deletion() or StompFeet._is_person(body) or (by != null and by.is_ancestor_of(body)):
		return false
	var holder := body.get_parent() as Node3D
	if holder != null:
		var at := Node3D.new()
		holder.add_child(at)
		at.global_position = body.global_position
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
