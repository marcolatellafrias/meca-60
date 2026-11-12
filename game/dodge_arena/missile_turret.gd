class_name MissileTurret
extends StaticBody3D

## EL JEFE DE MENTIRA DE LA ARENA DE ESQUIVAR (13/11/2026): una torre fija que tira andanadas de misiles de mortero a la
## meca, para probar cómo se siente moverla (el usuario: «al medio tenga un boss que sea nada, algo muy simple, que me
## tiren misiles hacia el cielo y caigan en el piso, pero que marque con un círculo donde van a caer… para ir viendo
## cómo se siente el movimiento de la mecha… que es esquivar»).
##   · CADA `EVERY` SEGUNDOS, UNA ANDANADA: uno donde está la meca, uno donde va a estar si sigue igual (su velocidad por
##     lo que tarda en caer; quieta, ése va al azar) y unos cuantos al azar alrededor. Todos tardan lo mismo en caer.
##   · DECIDE SÓLO EL HOST; los misiles los lanza su ProjectileField, que los pasa por la red.
## No es un jefe: no se mueve, no tiene equilibrio ni se rompe. Los jefes de verdad son de su módulo.

const EVERY := 3.2
const FLIGHT := 2.8
## Los de al azar: cuántos y a qué distancia de la meca, como mucho (m).
const LOOSE := 3
const SCATTER := 26.0
## La torre: su radio y su alto (m).
const RADIUS := 6.0
const HEIGHT := 14.0

var field: ProjectileField = null
## Prendida o apagada (la P de la parcela).
var firing := true

var _clock := 0.0
var _salvos := 0
var _random := RandomNumberGenerator.new()


func _ready() -> void:
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = RADIUS
	cylinder.height = HEIGHT
	shape.shape = cylinder
	shape.position = Vector3.UP * HEIGHT * 0.5
	add_child(shape)
	Clay.cylinder(self, RADIUS, HEIGHT, Vector3.UP * HEIGHT * 0.5, Clay.METAL.darkened(0.3))
	Clay.cylinder(self, RADIUS * 1.08, 1.2, Vector3.UP * HEIGHT, Clay.DARK)
	# Los tubos de arriba, de donde salen.
	for i in 6:
		var angle := TAU * i / 6.0
		Clay.cylinder(self, 0.9, 3.0, Vector3(cos(angle) * 3.2, HEIGHT + 1.8, sin(angle) * 3.2), Clay.DARK)
	_random.randomize()


func _physics_process(delta: float) -> void:
	if not firing or field == null or ProjectileField.is_client(self):
		return
	_clock += delta
	if _clock < EVERY:
		return
	_clock = 0.0
	var target := _target()
	if target == null:
		return
	_salvo(target)


## UNA ANDANADA (ver arriba).
func _salvo(target: Mech) -> void:
	_salvos += 1
	var floor_y := target.support.y if target.grounded else global_position.y
	var here := Vector3(target.global_position.x, floor_y, target.global_position.z)
	var going := Vector3(target.linear_velocity.x, 0.0, target.linear_velocity.z)
	var spots: Array[Vector3] = [here]
	# Quieta, el de adelante caería en el mismo lugar: va al azar.
	var loose := LOOSE
	if going.length() * FLIGHT > float(Missile.KINDS[Missile.Kind.MORTAR]["radius"]):
		spots.append(here + going * FLIGHT)
	else:
		loose += 1
	for i in loose:
		var angle := _random.randf() * TAU
		spots.append(here + Vector3(cos(angle), 0.0, sin(angle)) * _random.randf_range(SCATTER * 0.35, SCATTER))
	for i in spots.size():
		# Adentro del redondel.
		var flat := spots[i] - global_position
		flat.y = 0.0
		spots[i] = global_position + flat.limit_length(DodgeArenaArchetype.RADIUS - 6.0) + Vector3.UP * (floor_y - global_position.y)
		var angle := TAU * (i % 6) / 6.0
		var mouth := global_transform * Vector3(cos(angle) * 3.2, HEIGHT + 3.3, sin(angle) * 3.2)
		field.launch(Missile.Kind.MORTAR, mouth, spots[i], FLIGHT)


## A quién le tira: la meca con brazos más cercana de su parcela.
func _target() -> Mech:
	var parcel := SandboxParcel.owner_of(self)
	var holder: Node = parcel if parcel != null else get_parent()
	var best: Mech = null
	var nearest := INF
	for mech: Mech in holder.find_children("*", "Mech", true, false):
		if mech.arms_kind == Mech.Arms.NONE:
			continue
		var far := mech.global_position.distance_to(global_position)
		if far < nearest:
			nearest = far
			best = mech
	return best
