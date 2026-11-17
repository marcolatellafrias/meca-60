class_name MechCabin
extends Node3D

## LO DE TODA CABINA DE LA MECA (hoy, una sola: la jaula, CageCabin): lo que se ve de la caja y por donde se camina
## adentro. Cada una arma lo suyo en su `_ready` y dice dónde va la silla desde la que se mira (`top_seat`), cómo es su
## marco (`build_frame`) y adónde sube la U (`board`). Lo de todas, acá:
##   · LAS SILLAS (`chairs`) y los maniquíes sentados en ellas (`seat_dummies`).
##   · EL MARCO (MotionFrame): adentro se camina. Las formas de choque van en `interior`, un cuerpo que NO choca con nada:
##     es de donde el marco copia su SOMBRA. El que entra a la caja pasa a ir en el marco, que lo lleva con la meca, y
##     choca sólo con esa sombra. Y LA CAJA DE AFUERA, que es maciza y es la que choca con el mundo, deja de chocar con
##     él (`ride`).
## *Hasta el 17/11/2026 tenía también lo de las cabinas de la meca grande (la cuadrada y la redonda): el ascensor, los
## puestos de las sillas de adelante, el vidrio y sus barras, las placas con hueco y sus choques. Se borraron con ella
## (están en el commit 0bcaeaf).*

const SEAT_SCENE := "res://game/interactables/activatable/working_seat.tscn"
const DUMMY_SCENE := "res://game/character/player.tscn"
## LOS CUERPOS DE LOS MANIQUÍES: uno al azar cada vez que nace la meca, al rearmar la parcela también (el usuario,
## 16/11/2026: «que sean aleatorios los dummies, los arquetipos, así yo veo varias cosas distintas»). Todos menos el
## genérico.
const DUMMY_BODIES: Array[EntityArchetype.Archetype] = [EntityArchetype.Archetype.fat_athletic,
	EntityArchetype.Archetype.lanky, EntityArchetype.Archetype.buff, EntityArchetype.Archetype.fat_man,
	EntityArchetype.Archetype.kid, EntityArchetype.Archetype.old]

var mech: Mech = null
var frame: MotionFrame = null
var interior: StaticBody3D = null
## Las sillas (las pone cada una, en su orden) y los maniquíes sentados en ellas (ver `seat_dummies`).
var chairs: Array[SeatInteractable] = []
var dummies: Array[Node3D] = []

var _riders := {}


## La silla desde la que se mira en primera persona al poseer la meca (la pone cada una).
func top_seat() -> Vector3:
	return Vector3.ZERO


## EL MARCO, con sus volúmenes y su sombra (lo arma cada una, cuando la meca ya tiene todo armado).
func build_frame() -> void:
	push_error("MechCabin: la cabina %s no arma su marco" % name)


## SUBE AL JUGADOR (la U del sandbox): cada una dice adónde.
func board() -> void:
	pass


## UN MANIQUÍ SENTADO EN CADA SILLA, para ver la escala de adentro (el usuario, 13/11/2026: «le pondría los asientos
## reales y dejaría sentados… unos dummies. Así veo cómo se siente la escala de adentro»). Personajes de la calle, de
## varios cuerpos, que van al lado de la meca en el árbol y los lleva su silla. Los sienta la meca de brazos, no la de
## práctica.
## *En la cuadrada de la meca grande, la primera silla de la derecha quedaba libre, para sentarse uno con E; la jaula no
## tiene sillas a la derecha, y la regla se borró con la cuadrada el 17/11/2026.*
func seat_dummies() -> void:
	var holder := mech.get_parent() as Node3D
	if holder == null:
		return
	for i in chairs.size():
		seat_dummy(i)


## UN MANIQUÍ EN LA SILLA `i` (ver `seat_dummies`).
func seat_dummy(i: int) -> void:
	var holder := mech.get_parent() as Node3D
	if holder == null:
		return
	var dummy := (load(DUMMY_SCENE) as PackedScene).instantiate() as BoneInstantiator
	dummy.kind = CharacterKind.npc()
	var dice := RandomNumberGenerator.new()
	dice.randomize()
	dummy.master_seed = EntityInstantiation.debug_seed(DUMMY_BODIES[dice.randi() % DUMMY_BODIES.size()], dice.randi() % 1000)
	holder.add_child(dummy)
	dummies.append(dummy)
	# Aparece adentro de la caja maciza: que no la empuje antes de que el marco lo lleve (ver `ride`).
	mech.add_collision_exception_with(dummy.char_rigidbody)
	dummy.place_at(chairs[i].global_position + chairs[i].global_basis.z * 0.8, chairs[i].heading())
	dummy.intent.seat = chairs[i]


## Saca a los maniquíes (van al lado de la meca en el árbol, no adentro): para cuando la meca se cambia por otra.
func free_dummies() -> void:
	for dummy in dummies:
		if is_instance_valid(dummy):
			dummy.queue_free()
	dummies.clear()


## LA CAJA DE AFUERA NO CHOCA CON LOS QUE VAN ADENTRO: ellos ya dejaron de mirar al mundo (ver MotionFrame.join), pero
## la caja los seguía viendo. Se mira quién va en el marco en cada paso.
func ride() -> void:
	var inside := {}
	for body: Variant in frame._members.keys():
		if is_instance_valid(body) and body is PhysicsBody3D:
			inside[body] = true
			if not _riders.has(body):
				mech.add_collision_exception_with(body as PhysicsBody3D)
	for body: Variant in _riders.keys():
		if not inside.has(body) and is_instance_valid(body):
			mech.remove_collision_exception_with(body as PhysicsBody3D)
	_riders = inside
