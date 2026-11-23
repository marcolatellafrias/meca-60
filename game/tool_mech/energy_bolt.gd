class_name EnergyBolt
extends Node3D

## UN TIRO DEL CAÑÓN DE ENERGÍA: una bola de luz que va derecho a `speed`, y lo primero suelto que toca recibe UN
## IMPULSO (`push`, en kg·m/s) hacia donde iba; a una meca, por su puerta (BalanceBody.hit). Lo fijo la apaga. Se
## dibuja estirada a lo largo de su camino, y al pegar deja un destello.
## *Sólo local: todavía no va por la red (los proyectiles de verdad, ProjectileField).*

const MASK := 1
## Cuánto vive como mucho (s).
const LIFE := 1.6

var speed := 140.0
var push := 60000.0
var radius := 0.3
var color := Color(1.0, 0.55, 0.15)
## Cuánto de la ficha del cañón lleva (lo cargado, ver HitCard).
var power := 1.0
## Lo que no toca (la meca que tira).
var exclude: Array[RID] = []
## SÓLO SE VE (las habilidades pegan con su zona, MechSkills): se apaga en lo fijo o al llegar a `reach` (m).
var harmless := false
var reach := -1.0
var _flown := 0.0

var _life := 0.0
## Cuántos salieron en esta máquina (para las pruebas).
static var made := 0


func _ready() -> void:
	made += 1
	top_level = true
	var glow := MeshInstance3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = maxf(radius * 2.0, speed * 0.03)
	glow.mesh = mesh
	glow.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	glow.material_override = shine(color)
	add_child(glow)


func _physics_process(delta: float) -> void:
	_life += delta
	var from := global_position
	var to := from - global_basis.z * speed * delta
	if harmless:
		_fly_only(from, to)
		return
	var query := PhysicsRayQueryParameters3D.create(from, to, MASK, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	# LOS BLANCOS SE TOCAN EN EL PISO, CON EL ANCHO QUE SE VE (ver HitTarget): antes de lo que encuentre el rayo.
	var target := HitTarget.first_on_line(get_tree(), from, to, radius)
	if target != null:
		var at := target.surface(from)
		if hit.is_empty() or Vector2(at.x - from.x, at.z - from.z).length() <= \
				Vector2(hit["position"].x - from.x, hit["position"].z - from.z).length() + target.flat_radius():
			target.strike("cañón", power, push, at, -global_basis.z)
			flash(get_parent(), at, radius * 3.0, color)
			MechSounds.loose(MechSounds.CANNON_HIT, at, get_tree(), clampf(0.6 / radius, 0.5, 1.6), clampf(radius * 1.5, 0.4, 1.0))
			queue_free()
			return
	if not hit.is_empty():
		var body := struck(hit["collider"])
		if body != null:
			lands(body, -global_basis.z * push, hit["position"], "cañón", power)
		flash(get_parent(), hit["position"], radius * 3.0, color)
		MechSounds.loose(MechSounds.CANNON_HIT, hit["position"], get_tree(), clampf(0.6 / radius, 0.5, 1.6),
			clampf(radius * 1.5, 0.4, 1.0))
		queue_free()
		return
	global_position = to
	if _life > LIFE:
		queue_free()


## EL TIRO QUE SÓLO SE VE: hasta el final de su línea o lo primero que toque. SÓLO SI TOCÓ ALGO deja el destello (22/11/2026;
## el usuario: «si no colisionan con nada, no hacer partículas»).
func _fly_only(from: Vector3, to: Vector3) -> void:
	var step := from.distance_to(to)
	var arrives := reach >= 0.0 and _flown + step >= reach
	var end := from.move_toward(to, reach - _flown) if arrives else to
	var query := PhysicsRayQueryParameters3D.create(from, end, PhysicsLayers.FIXED, exclude)
	var hit := get_world_3d().direct_space_state.intersect_ray(query)
	var target := HitTarget.first_on_line(get_tree(), from, end, radius)
	if target != null:
		flash(get_parent(), target.surface(from), radius * 2.0, color)
		queue_free()
		return
	if not hit.is_empty():
		flash(get_parent(), hit["position"], radius * 2.0, color)
		queue_free()
		return
	if arrives or _life > LIFE:
		queue_free()
		return
	_flown += step
	global_position = end


## A QUIÉN LE PEGA lo que toca un tiro: si es una pieza de una meca (un pie, una tobera), a la meca; si no, a lo que
## sea suelto. Lo fijo, a nadie.
static func struck(collider: Object) -> RigidBody3D:
	var node := collider as Node
	while node != null:
		if node is BalanceBody:
			return node as RigidBody3D
		node = node.get_parent()
	return collider as RigidBody3D


## UN GOLPE DE LA MECA DE TRES LLEGA A `body`: el empujón (BalanceBody.hit) y, SI LO QUE RECIBE TIENE
## `take_hit(strength, at, source)`, se lo dice: cuánto empujó (kg·m/s), dónde (mundo) y con qué ("cañón", "rayo",
## "taladro"). Es la costura con lo que lleva vida (un jefe, ver game/bosses/): lo decide quien recibe, no el arma.
## POR LA RED, SÓLO EN EL HOST: cada máquina tira sus tiros y barre sus piñas (ver MechArmsNet), y sólo los del host le
## pegan de verdad; así un golpe cuenta una vez.
## SI LO QUE RECIBE ES UN BLANCO (HitTarget: la bolsa, un jefe), el golpe va por su ficha (`power` la escala) y el impulso
## no lo mueve.
static func lands(body: RigidBody3D, impulse: Vector3, at: Vector3, source: String, power := 1.0) -> void:
	if ProjectileField.is_client(body):
		return
	var target := HitTarget.of_body(body)
	if target != null:
		target.strike(source, power, impulse.length(), at, impulse.normalized())
		return
	BalanceBody.hit(body, impulse, at - body.global_position)
	var owner_of := struck(body)
	if owner_of != null and owner_of.has_method("take_hit"):
		owner_of.call("take_hit", impulse.length(), at, source)


## Un material que brilla, sin sombra.
static func shine(tint: Color) -> StandardMaterial3D:
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.albedo_color = tint
	paint.emission_enabled = true
	paint.emission = tint
	return paint


## UN DESTELLO en `at` que se agranda y se apaga en un instante.
static func flash(parent: Node, at: Vector3, size: float, tint: Color) -> void:
	if parent == null:
		return
	var spark := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = size
	ball.height = size * 2.0
	spark.mesh = ball
	var paint := shine(tint)
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	spark.material_override = paint
	parent.add_child(spark)
	spark.global_position = at
	var fade := spark.create_tween()
	fade.set_parallel(true)
	fade.tween_property(spark, "scale", Vector3.ONE * 2.0, 0.25)
	fade.tween_property(paint, "albedo_color:a", 0.0, 0.25)
	fade.chain().tween_callback(spark.queue_free)
