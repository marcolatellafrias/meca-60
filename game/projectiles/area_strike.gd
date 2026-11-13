class_name AreaStrike
extends Node3D

## UNA ZONA QUE PEGA (13/11/2026) — TRABAJO EN CURSO: lo básico para probar cómo se mueve la meca, a reformular cuando
## se piensen de verdad los ataques de los jefes. El usuario: «prefiero que hagas lo básico y después se lo reformula…
## que quede marcado como work in progress».
##
## Separa LA FORMA (lo que dice cómo moverse) de LO QUE PASA ADENTRO (el elemento: explosión, fuego, eléctrico, balas…).
## Hoy el elemento es sólo cómo se ve y todas empujan igual: lo que le haga cada uno a la meca se decide cuando estén la
## energía y las roturas.
##
## Como un Missile, es UNA DESCRIPCIÓN QUE SE CUMPLE SOLA CON EL TIEMPO (`spec`, un Dictionary que viaja por la red; ver
## ProjectileField.strike): cada máquina la dibuja igual y SÓLO EL HOST EMPUJA.
##   · QUIETAS (CIRCLE, RING, BAND): su marca en el piso desde que aparecen; adentro, lo que va a pegar crece hasta
##     llenarla justo al cumplirse el aviso (`delay`). Ahí estalla todo lo de adentro a la vez.
##   · QUE AVANZAN (WAVE_RING, una onda que se abre desde `at`; WAVE_BAND, una pared que cruza hacia `way`): después del
##     aviso salen, a `speed`, y PEGAN SÓLO A LO QUE PISA EL PISO: se saltan. Una meca en el aire pasa por arriba.
##   · ALTAS (13/11/2026; `low` > 0, una onda o una pared que va a esa altura del piso, como una sierra tirada): pegan
##     sólo a lo que llega a esa franja; AGACHÁNDOSE se pasa por abajo.
##   · EL BARRIDO (SWEEP, el láser del ojo de una meca enemiga): una línea al ras del piso que gira alrededor de `at`, de
##     `yaw_from` a `yaw_to`, a `speed` (radianes por segundo), hasta `reach`. Se salta, como las ondas.
##
## Lo que dice `spec` (lo que no aplica a su forma, se ignora):
##   shape, element · at (el centro, o donde empieza) · radius, inner (la dona: el hueco) · to, width (la franja: de `at`
##   a `to`, con su ancho) · way, length (la pared que cruza: hacia dónde y cuán larga es de punta a punta) · reach (hasta
##   dónde llega lo que avanza) · speed · delay · push (cuánto le cambia la velocidad a lo que agarra, m/s) · low (lo que
##   avanza, a qué altura va) · yaw_from, yaw_to (el barrido) · team (el bando que no recibe: ver `spares`).

enum Shape { CIRCLE, RING, BAND, WAVE_RING, WAVE_BAND, SWEEP }
enum Element { BLAST, FIRE, ELECTRIC }

const NAMES := ["círculo", "dona", "franja", "onda", "pared que cruza", "barrido"]
## Los colores de cada elemento: la marca, lo que crece y el borde.
const COLORS := {
	Element.BLAST: Color(0.8, 0.32, 0.18),
	Element.FIRE: Color(0.9, 0.5, 0.12),
	Element.ELECTRIC: Color(0.35, 0.6, 0.95),
}
## Lo que avanza: su alto (m; lo que tiene que pasar por arriba la meca para no tocarla) y su grosor.
const WAVE_HEIGHT := 3.0
const WAVE_THICK := 3.0
## Después de estallar, cuánto se queda (s) antes de borrarse: lo que duran las partículas.
const LINGER := 2.5
## Cuántos estallidos se reparten por la forma, como mucho.
const BURSTS := 9

var spec := {}

var _age := 0.0
var _fired := false
var _mark: Node3D = null
var _fill: MeshInstance3D = null
var _wave: MeshInstance3D = null
var _struck := {}


func _ready() -> void:
	top_level = true
	global_transform = Transform3D()
	_mark = Node3D.new()
	add_child(_mark)
	_build_mark()


func shape() -> Shape:
	return int(spec.get("shape", Shape.CIRCLE)) as Shape


func _physics_process(delta: float) -> void:
	_age += delta
	var delay: float = spec.get("delay", 2.0)
	var share := clampf(_age / maxf(delay, 0.01), 0.0, 1.0)
	if _moving():
		_advance_wave(delta)
		return
	if not _fired:
		_grow(share)
		if _age >= delay:
			_fire()
	elif _age > delay + LINGER:
		queue_free()


func _moving() -> bool:
	return shape() == Shape.WAVE_RING or shape() == Shape.WAVE_BAND or shape() == Shape.SWEEP


## ── LAS QUIETAS ─────────────────────────────────────────────────────────────────────────────────────────────────

## LO QUE VA A PEGAR CRECE adentro de la marca: el círculo desde el centro, la dona de afuera hacia adentro, la franja
## desde donde sale.
func _grow(share: float) -> void:
	if _fill == null:
		return
	var at: Vector3 = spec["at"]
	match shape():
		Shape.CIRCLE:
			_fill.scale = Vector3(maxf(share, 0.001), 1.0, maxf(share, 0.001))
		Shape.RING:
			(_fill.material_override as StandardMaterial3D).albedo_color.a = lerpf(0.05, 0.5, share)
		Shape.BAND:
			var to: Vector3 = spec["to"]
			_fill.scale = Vector3(1.0, 1.0, maxf(share, 0.001))
			_fill.global_position = at.lerp(to, share * 0.5) + Vector3.UP * 0.08


## ESTALLA: se borra la marca, estallidos repartidos por la forma y, en el host, el empujón.
func _fire() -> void:
	_fired = true
	_mark.visible = false
	for point in _scatter():
		_burst(point)
	if not ProjectileField.is_client(self):
		_blast_static()


## Puntos repartidos por la forma, para los estallidos.
func _scatter() -> Array[Vector3]:
	var at: Vector3 = spec["at"]
	var out: Array[Vector3] = []
	if shape() != Shape.RING:
		out.append(at)
	var count := BURSTS
	for i in count:
		var share := (i + 0.5) / count
		match shape():
			Shape.CIRCLE:
				var radius: float = spec["radius"]
				out.append(at + Vector3(cos(i * 2.4), 0.0, sin(i * 2.4)) * radius * sqrt(share) * 0.85)
			Shape.RING:
				var radius: float = spec["radius"]
				var inner: float = spec["inner"]
				out.append(at + Vector3(cos(TAU * share), 0.0, sin(TAU * share)) * (inner + radius) * 0.5)
			Shape.BAND:
				out.append(at.lerp(spec["to"], share))
	return out


func _burst(point: Vector3) -> void:
	var element := int(spec.get("element", Element.BLAST)) as Element
	var makers: Array[Callable] = [ParticleSystems.explosion_flash, ParticleSystems.impact_dust]
	if element == Element.ELECTRIC:
		makers = [ParticleSystems.zap, ParticleSystems.impact_dust]
	elif element == Element.FIRE:
		makers = [ParticleSystems.explosion_flash, ParticleSystems.explosion_sparks]
	for make in makers:
		var kind := ParticleMeshes.Kind.LINE if make == ParticleSystems.explosion_sparks or make == ParticleSystems.zap \
			else ParticleMeshes.Kind.SPHERE
		var burst: GPUParticles3D = make.call(kind, Missile.BLAST_SIZE)
		burst.transform = Transform3D(Basis(Vector3.RIGHT, PI * 0.5), point + Vector3.UP * 0.5)
		add_child(burst)
		burst.restart()
	# El fuego se queda un rato ardiendo.
	if element == Element.FIRE:
		var flame := ParticleSystems.fire(ParticleMeshes.Kind.SPHERE, 4.0)
		flame.transform = Transform3D(Basis(Vector3.RIGHT, -PI * 0.5), point)
		add_child(flame)
		flame.emitting = true
		get_tree().create_timer(LINGER - 0.8).timeout.connect(func() -> void:
			if is_instance_valid(flame):
				flame.emitting = false)


## EL EMPUJÓN DE LAS QUIETAS: a lo suelto adentro de la forma, en una columna de 30 m (una meca está alta).
func _blast_static() -> void:
	for body in _bodies_near(spec["at"], _extent()):
		var strength := _inside(body.global_position)
		if strength < 0.0:
			continue
		_push(body, _away(body.global_position), strength)


## ── LAS QUE AVANZAN ─────────────────────────────────────────────────────────────────────────────────────────────

func _advance_wave(_delta: float) -> void:
	var delay: float = spec.get("delay", 1.0)
	var speed: float = spec.get("speed", 20.0)
	var reach: float = spec.get("reach", 90.0)
	var gone := maxf(_age - delay, 0.0) * speed
	if _age < delay:
		_grow_warning(_age / maxf(delay, 0.01))
		return
	_mark.visible = false
	if shape() == Shape.SWEEP:
		_advance_sweep(_age - delay)
		return
	if gone > reach:
		queue_free()
		return
	var at: Vector3 = spec["at"]
	if shape() == Shape.WAVE_RING:
		_wave.scale = Vector3(maxf(gone, 0.01), 1.0, maxf(gone, 0.01))
		_wave.global_position = at
	else:
		var way: Vector3 = spec["way"]
		_wave.global_position = at + way * gone + Vector3.UP * _low()
	if not ProjectileField.is_client(self):
		_blast_wave(gone)


## EL BARRIDO (ver arriba): la línea, donde va ahora; y en el host, a lo que pisa el piso entre donde estaba y donde está.
func _advance_sweep(seconds: float) -> void:
	var from: float = spec.get("yaw_from", 0.0)
	var to: float = spec.get("yaw_to", 1.0)
	var total := absf(angle_difference(from, to))
	var turned := minf(seconds * float(spec.get("speed", 1.0)), total)
	if turned >= total and seconds > total / float(spec.get("speed", 1.0)) + 0.3:
		queue_free()
		return
	var sign := signf(angle_difference(from, to))
	var now := from + sign * turned
	var at: Vector3 = spec["at"]
	var reach: float = spec.get("reach", 70.0)
	_wave.global_transform = Transform3D(Basis(Vector3.UP, now), at + Basis(Vector3.UP, now) * Vector3(0.0,
		WAVE_HEIGHT * 0.5, -reach * 0.5))
	if ProjectileField.is_client(self):
		return
	var before := from + sign * maxf(turned - float(spec.get("speed", 1.0)) * get_physics_process_delta_time(), 0.0)
	for body in _bodies_near(at, reach):
		if _struck.has(body.get_instance_id()) or not _on_floor(body):
			continue
		var flat := Vector3(body.global_position.x - at.x, 0.0, body.global_position.z - at.z)
		var far := flat.length()
		if far > reach + _half_width(body) or far < 0.5:
			continue
		var heading := atan2(-flat.x, -flat.z)
		var room := atan(_half_width(body) / far)
		var lo := minf(before, now) - room
		var hi := maxf(before, now) + room
		var middle := (lo + hi) * 0.5
		if absf(angle_difference(middle, heading)) <= (hi - lo) * 0.5:
			_struck[body.get_instance_id()] = true
			_push(body, Basis(Vector3.UP, now) * Vector3(-sign, 0.0, 0.0), 1.0)


## El aviso de lo que avanza: su línea de salida, cada vez más fuerte.
func _grow_warning(share: float) -> void:
	if _fill != null:
		(_fill.material_override as StandardMaterial3D).albedo_color.a = lerpf(0.15, 0.9, share)


## EL EMPUJÓN DE LO QUE AVANZA: a lo que pisa el piso, donde está la onda ahora, una vez; hacia donde va.
func _blast_wave(gone: float) -> void:
	var at: Vector3 = spec["at"]
	var centre := at
	if shape() == Shape.WAVE_BAND:
		centre = at + (spec["way"] as Vector3) * gone
	var span := gone + WAVE_THICK if shape() == Shape.WAVE_RING else float(spec.get("length", 60.0)) * 0.5
	for body in _bodies_near(centre, span):
		if _struck.has(body.get_instance_id()) or not _on_floor(body):
			continue
		var flat := body.global_position - at
		flat.y = 0.0
		var hit := false
		var way := Vector3.ZERO
		if shape() == Shape.WAVE_RING:
			hit = absf(flat.length() - gone) < WAVE_THICK * 0.5 + _half_width(body)
			way = flat.normalized() if flat.length_squared() > 0.01 else Vector3.FORWARD
		else:
			way = spec["way"]
			var along := flat.dot(way)
			var across := absf(flat.dot(way.cross(Vector3.UP)))
			hit = absf(along - gone) < WAVE_THICK * 0.5 + _half_width(body) and across < float(spec.get("length", 60.0)) * 0.5
		if hit:
			_struck[body.get_instance_id()] = true
			_push(body, way, 1.0)


## SI LA AGARRA LO QUE AVANZA: al ras (`low` 0), una meca apoyada (no en el aire) y lo demás a menos de la altura de la
## onda; alta, lo que llega a su franja (una meca, por su caja: agachada, pasa por abajo).
func _on_floor(body: RigidBody3D) -> bool:
	var balance := body as BalanceBody
	var at: Vector3 = spec["at"]
	var low := _low()
	if low > 0.0:
		var half := balance.size.y * 0.5 if balance != null else 0.5
		return body.global_position.y + half > at.y + low and body.global_position.y - half < at.y + low + WAVE_HEIGHT
	if balance != null:
		return not balance.airborne
	return body.global_position.y - at.y < WAVE_HEIGHT


func _low() -> float:
	return float(spec.get("low", 0.0))


func _half_width(body: RigidBody3D) -> float:
	var balance := body as BalanceBody
	return balance.size.x * 0.5 if balance != null else 0.5


## ── LO COMÚN ────────────────────────────────────────────────────────────────────────────────────────────────────

## Cuán adentro está `point` de la forma quieta: 1 en el medio, 0 en el borde, negativo afuera.
func _inside(point: Vector3) -> float:
	var at: Vector3 = spec["at"]
	var flat := Vector3(point.x - at.x, 0.0, point.z - at.z)
	match shape():
		Shape.CIRCLE:
			var radius: float = spec["radius"]
			return 1.0 - flat.length() / radius if flat.length() <= radius else -1.0
		Shape.RING:
			var radius: float = spec["radius"]
			var inner: float = spec["inner"]
			var far := flat.length()
			return 1.0 if far >= inner and far <= radius else -1.0
		Shape.BAND:
			var to: Vector3 = spec["to"]
			var line := Vector3(to.x - at.x, 0.0, to.z - at.z)
			var along := clampf(flat.dot(line) / maxf(line.length_squared(), 0.01), 0.0, 1.0)
			var across := (flat - line * along).length()
			var half: float = float(spec["width"]) * 0.5
			return 1.0 - across / half if across <= half else -1.0
	return -1.0


## Hacia dónde empuja la quieta: afuera del centro, o de costado de la franja.
func _away(point: Vector3) -> Vector3:
	var at: Vector3 = spec["at"]
	var flat := Vector3(point.x - at.x, 0.0, point.z - at.z)
	if shape() == Shape.BAND:
		var to: Vector3 = spec["to"]
		var line := Vector3(to.x - at.x, 0.0, to.z - at.z).normalized()
		flat -= line * flat.dot(line)
	return flat.normalized() if flat.length_squared() > 0.01 else Vector3.FORWARD


func _extent() -> float:
	if shape() == Shape.BAND:
		return (spec["at"] as Vector3).distance_to(spec["to"]) + float(spec["width"])
	return float(spec.get("radius", 10.0))


## Lo suelto cerca de `centre`, en una columna de `radius` y 30 m de alto, menos los de su bando.
func _bodies_near(centre: Vector3, radius: float) -> Array[RigidBody3D]:
	var column := CylinderShape3D.new()
	column.radius = maxf(radius, 0.5)
	column.height = Missile.COLUMN
	var out: Array[RigidBody3D] = []
	for body in AreaStrike.loose_in(get_world_3d().direct_space_state, column, Transform3D(Basis(),
			centre + Vector3.UP * Missile.COLUMN * 0.5)):
		if not AreaStrike.spares(body, str(spec.get("team", ""))):
			out.append(body)
	return out


## SI LO DE UN BANDO NO LE PEGA A `body`: es de su bando (13/11/2026; el jefe se empujaba solo con la onda de su
## propio salto, que nace debajo de él). Sin bando, le pega a todo.
static func spares(body: RigidBody3D, team: String) -> bool:
	var balance := body as BalanceBody
	return not team.is_empty() and balance != null and balance.team == team


## TODO LO SUELTO que toca `shape` en `where`, sin tope: una consulta devuelve una cantidad fija de choques y lo fijo
## (los tramos del muro, las piezas de la cabina) llenaba el cupo antes de llegar a la meca; acá lo ya visto se excluye
## y se vuelve a preguntar hasta que no aparece nada nuevo.
static func loose_in(space: PhysicsDirectSpaceState3D, shape: Shape3D, where: Transform3D) -> Array[RigidBody3D]:
	const BATCH := 32
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = where
	var out: Array[RigidBody3D] = []
	var seen: Array[RID] = []
	while true:
		query.exclude = seen
		var hits := space.intersect_shape(query, BATCH)
		for hit: Dictionary in hits:
			seen.append(hit["rid"])
			var body := hit["collider"] as RigidBody3D
			if body != null and not body.freeze and not out.has(body):
				out.append(body)
		if hits.size() < BATCH:
			break
	return out


func _push(body: RigidBody3D, way: Vector3, strength: float) -> void:
	var push: float = spec.get("push", 10.0)
	var up := 0.15
	var direction := (way * (1.0 - up) + Vector3.UP * up).normalized()
	body.apply_central_impulse(direction * push * clampf(strength, 0.25, 1.0) * body.mass)


## LA MARCA: el fondo, lo que crece (`_fill`) y, en lo que avanza, la pared misma (`_wave`).
func _build_mark() -> void:
	var color: Color = COLORS[int(spec.get("element", Element.BLAST))]
	var at: Vector3 = spec["at"]
	var lift := Vector3.UP * 0.06
	match shape():
		Shape.CIRCLE:
			var radius: float = spec["radius"]
			_mark.add_child(_part(AreaStrike._disc(radius), color, 0.18, at + lift))
			_fill = _part(AreaStrike._disc(radius), color, 0.4, at + lift + Vector3.UP * 0.02)
			_mark.add_child(_part(AreaStrike._annulus(radius - Missile.EDGE, radius), color, 0.85, at + lift + Vector3.UP * 0.04))
		Shape.RING:
			var radius: float = spec["radius"]
			var inner: float = spec["inner"]
			_mark.add_child(_part(AreaStrike._annulus(inner, radius), color, 0.12, at + lift))
			_fill = _part(AreaStrike._annulus(inner, radius), color, 0.05, at + lift + Vector3.UP * 0.02)
			_mark.add_child(_part(AreaStrike._annulus(inner, inner + Missile.EDGE), color, 0.85, at + lift + Vector3.UP * 0.04))
			_mark.add_child(_part(AreaStrike._annulus(radius - Missile.EDGE, radius), color, 0.85, at + lift + Vector3.UP * 0.04))
		Shape.BAND:
			var to: Vector3 = spec["to"]
			var width: float = spec["width"]
			var length := Vector2(to.x - at.x, to.z - at.z).length()
			var turn := Basis.looking_at(Vector3(to.x - at.x, 0.0, to.z - at.z).normalized(), Vector3.UP)
			var flat := BoxMesh.new()
			flat.size = Vector3(width, 0.02, length)
			var back := _part(flat, color, 0.18, at.lerp(to, 0.5) + lift)
			back.basis = turn
			_mark.add_child(back)
			_fill = _part(flat, color, 0.4, at + lift + Vector3.UP * 0.02)
			_fill.basis = turn
			_mark.add_child(_fill)
		Shape.WAVE_RING:
			_fill = _part(AreaStrike._annulus(0.0, WAVE_THICK * 2.0), color, 0.15, at + lift)
			_mark.add_child(_fill)
			var wall := CylinderMesh.new()
			wall.top_radius = 1.0
			wall.bottom_radius = 1.0
			wall.height = WAVE_HEIGHT
			wall.radial_segments = 48
			wall.cap_top = false
			wall.cap_bottom = false
			_wave = _part(wall, color, 0.55, at + Vector3.UP * (WAVE_HEIGHT * 0.5 + _low()))
			add_child(_wave)
		Shape.WAVE_BAND:
			var way: Vector3 = spec["way"]
			var length: float = spec.get("length", 60.0)
			var turn := Basis.looking_at(way, Vector3.UP)
			var line := BoxMesh.new()
			line.size = Vector3(length, 0.02, WAVE_THICK)
			_fill = _part(line, color, 0.15, at + lift)
			_fill.basis = turn
			_mark.add_child(_fill)
			var wall := BoxMesh.new()
			wall.size = Vector3(length, WAVE_HEIGHT, WAVE_THICK)
			_wave = _part(wall, color, 0.55, at + Vector3.UP * (WAVE_HEIGHT * 0.5 + _low()))
			_wave.basis = turn
			add_child(_wave)
		Shape.SWEEP:
			var reach: float = spec.get("reach", 70.0)
			var from: float = spec.get("yaw_from", 0.0)
			var to: float = spec.get("yaw_to", 1.0)
			_mark.add_child(_part(AreaStrike._fan(reach, from, to), color, 0.12, at + lift))
			var line := BoxMesh.new()
			line.size = Vector3(1.6, 0.02, reach)
			_fill = _part(line, color, 0.15, at + lift + Basis(Vector3.UP, from) * Vector3(0.0, 0.02, -reach * 0.5))
			_fill.basis = Basis(Vector3.UP, from)
			_mark.add_child(_fill)
			var beam := BoxMesh.new()
			beam.size = Vector3(1.6, WAVE_HEIGHT, reach)
			_wave = _part(beam, color, 0.65, at)
			_wave.transform = Transform3D(Basis(Vector3.UP, from), at + Basis(Vector3.UP, from) * Vector3(0.0,
				WAVE_HEIGHT * 0.5, -reach * 0.5))
			add_child(_wave)


func _part(mesh: Mesh, color: Color, alpha: float, at: Vector3) -> MeshInstance3D:
	var part := Missile.flat_part(mesh, Color(color, alpha), 0.0)
	part.top_level = true
	(part.material_override as StandardMaterial3D).cull_mode = BaseMaterial3D.CULL_DISABLED
	part.position = at
	return part


static func _disc(radius: float) -> Mesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = 0.02
	mesh.radial_segments = 48
	return mesh


## Un abanico plano, de `from` a `to` (giros, como los de un Basis), hasta `reach`.
static func _fan(reach: float, from: float, to: float) -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var span := angle_difference(from, to)
	var sides := maxi(int(absf(span) / 0.05), 2)
	for i in sides:
		var a := from + span * i / sides
		var b := from + span * (i + 1) / sides
		for p: Vector3 in [Vector3.ZERO, Basis(Vector3.UP, a) * Vector3(0, 0, -reach), Basis(Vector3.UP, b) * Vector3(0, 0, -reach)]:
			tool.add_vertex(p)
	return tool.commit()


## Un anillo plano, de `inner` a `outer`.
static func _annulus(inner: float, outer: float) -> Mesh:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 64
	for i in sides:
		var a := TAU * i / sides
		var b := TAU * (i + 1) / sides
		var p0 := Vector3(cos(a) * inner, 0.0, sin(a) * inner)
		var p1 := Vector3(cos(a) * outer, 0.0, sin(a) * outer)
		var p2 := Vector3(cos(b) * outer, 0.0, sin(b) * outer)
		var p3 := Vector3(cos(b) * inner, 0.0, sin(b) * inner)
		for p in [p0, p1, p2, p0, p2, p3]:
			tool.add_vertex(p)
	return tool.commit()
