class_name MissileTurret
extends StaticBody3D

## EL JEFE DE MENTIRA DE LA ARENA DE ESQUIVAR (13/11/2026) — TRABAJO EN CURSO: una torre fija que le tira ataques de
## área a la meca, para probar cómo se siente moverla (el usuario: «al medio tenga un boss que sea nada, algo muy
## simple… para ir viendo cómo se siente el movimiento de la mecha… que es esquivar»). No es un jefe: no se mueve, no
## tiene equilibrio ni se rompe; los jefes de verdad, y qué ataques tienen, son de su módulo.
##
## UN ATAQUE A LA VEZ (`attack`, la K de su parcela; `ALL` los pasa de a uno). Cada uno, cada tanto (`EVERY`):
##   · LLUVIA: misiles de mortero, uno donde está la meca, uno donde va a estar si sigue igual y tres al azar.
##   · CÍRCULO GIGANTE: uno enorme donde está, con mucho aviso: correr afuera.
##   · DONA: todo menos cerca de la torre: acercarse.
##   · ONDAS: tres anillos que se abren desde la torre, uno tras otro: saltarlos.
##   · LANZA: una franja de la torre hacia la meca: un paso al costado.
##   · ALFOMBRA: misiles que caen en fila, uno tras otro, desde atrás de la meca hacia adelante.
##   · PARED QUE CRUZA: una pared baja que cruza la arena de punta a punta hacia la meca: saltarla.
## DECIDE SÓLO EL HOST; los misiles y las zonas los lanza su ProjectileField, que los pasa por la red.

enum Attack { RAIN, GIANT, DONUT, WAVES, LANCE, CARPET, WALL, ALL }

const NAMES := ["lluvia de misiles", "círculo gigante", "dona", "ondas (saltarlas)", "lanza", "alfombra de misiles",
	"pared que cruza (saltarla)", "todos, de a uno"]
## Cada cuánto tira cada uno (s).
const EVERY := [3.2, 6.5, 6.5, 5.5, 3.0, 4.5, 7.5]
const FLIGHT := 2.8
## La lluvia: cuántos al azar y a qué distancia de la meca, como mucho (m).
const LOOSE := 3
const SCATTER := 26.0
## La torre: su radio y su alto (m).
const RADIUS := 6.0
const HEIGHT := 14.0

var field: ProjectileField = null
## Prendida o apagada, y qué ataque tira.
var firing := true
var attack := Attack.RAIN

var _clock := 0.0
var _turn := 0
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


## Cambia de ataque y tira el nuevo enseguida.
func choose(which: Attack) -> void:
	attack = which
	firing = true
	_turn = 0
	_clock = 1000.0


func _physics_process(delta: float) -> void:
	if not firing or field == null or ProjectileField.is_client(self):
		return
	var now := _now()
	_clock += delta
	if _clock < float(EVERY[now]):
		return
	var target := _target()
	if target == null:
		return
	_clock = 0.0
	_fire(now, target)
	if attack == Attack.ALL:
		_turn = (_turn + 1) % Attack.ALL


## El ataque de ahora (con `ALL`, el que toca).
func _now() -> Attack:
	return (_turn if attack == Attack.ALL else attack) as Attack


func _fire(which: Attack, target: Mech) -> void:
	var floor_y := target.support.y if target.grounded else global_position.y
	var here := Vector3(target.global_position.x, floor_y, target.global_position.z)
	var going := Vector3(target.linear_velocity.x, 0.0, target.linear_velocity.z)
	var base := Vector3(global_position.x, floor_y, global_position.z)
	var toward := (here - base).normalized() if (here - base).length_squared() > 1.0 else Vector3.FORWARD
	var edge := DodgeArenaArchetype.RADIUS
	match which:
		Attack.RAIN:
			_rain(here, going)
		Attack.GIANT:
			field.strike({"shape": AreaStrike.Shape.CIRCLE, "element": AreaStrike.Element.BLAST, "at": _inside(here),
				"radius": 32.0, "delay": 4.5, "push": 14.0})
		Attack.DONUT:
			field.strike({"shape": AreaStrike.Shape.RING, "element": AreaStrike.Element.FIRE, "at": base,
				"inner": 26.0, "radius": edge, "delay": 4.0, "push": 10.0})
		Attack.WAVES:
			for i in 3:
				field.strike({"shape": AreaStrike.Shape.WAVE_RING, "element": AreaStrike.Element.ELECTRIC, "at": base,
					"delay": 1.2 + i * 1.3, "speed": 26.0, "reach": edge, "push": 9.0})
		Attack.LANCE:
			field.strike({"shape": AreaStrike.Shape.BAND, "element": AreaStrike.Element.BLAST,
				"at": base + toward * RADIUS, "to": base + toward * (edge - 2.0), "width": 14.0, "delay": 1.4,
				"push": 12.0})
		Attack.CARPET:
			var path := going.normalized() if going.length() > 1.0 else toward.cross(Vector3.UP)
			for i in 7:
				field.launch(Missile.Kind.MORTAR, _mouth(i), _inside(here + path * (i - 2) * 11.0), 1.8 + i * 0.4)
		Attack.WALL:
			field.strike({"shape": AreaStrike.Shape.WAVE_BAND, "element": AreaStrike.Element.FIRE,
				"at": base - toward * (edge - 4.0), "way": toward, "length": edge * 2.0, "delay": 1.5, "speed": 34.0,
				"reach": edge * 2.0 - 8.0, "push": 10.0})


## LA LLUVIA (ver arriba).
func _rain(here: Vector3, going: Vector3) -> void:
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
		field.launch(Missile.Kind.MORTAR, _mouth(i), _inside(spots[i]), FLIGHT)


## Adentro del redondel.
func _inside(spot: Vector3) -> Vector3:
	var flat := spot - global_position
	flat.y = 0.0
	return Vector3(global_position.x, spot.y, global_position.z) + flat.limit_length(DodgeArenaArchetype.RADIUS - 6.0)


## La boca del tubo `index` (de seis).
func _mouth(index: int) -> Vector3:
	var angle := TAU * (index % 6) / 6.0
	return global_transform * Vector3(cos(angle) * 3.2, HEIGHT + 3.3, sin(angle) * 3.2)


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
