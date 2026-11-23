class_name BossBursts
extends RefCounted

## LAS RÁFAGAS DE PARTÍCULAS DE LA PELEA CON LOS JEFES (15/11/2026), a su escala (todo mide decenas de metros: las de
## ParticleSystems son de un paquete que se cae). Cuadraditos y bolas sin sombra, en el mundo, que salen todos juntos
## y se van solos. El usuario: «tirar más partículas».
##   · `sparks`: chispas blancas y naranjas (un golpe).
##   · `dirt`: tierra que salta (cascotes) y una nube de polvo (la piedra que se arranca o que cae).

const DIRT := Color(0.5, 0.42, 0.33)
const DUST := Color(0.72, 0.66, 0.58)


## CHISPAS en `at` (más, si es fuerte).
static func sparks(parent: Node, at: Vector3, heavy: bool) -> void:
	var ramp := Gradient.new()
	ramp.set_color(0, Color(1.0, 1.0, 0.9))
	ramp.set_color(1, Color(1.0, 0.45, 0.1))
	burst(parent, at, 70 if heavy else 40, 0.9 if heavy else 0.6, Vector2(14.0, 34.0 if heavy else 26.0), ramp,
		-40.0, 0.7)


## TIERRA en `at`, de tamaño `size` (1: un golpe de 10 m): cascotes que saltan y caen, y una nube de polvo que se
## infla, sube un poco y se va.
static func dirt(parent: Node, at: Vector3, size: float) -> void:
	var chunks := Gradient.new()
	chunks.set_color(0, DIRT.lightened(0.1))
	chunks.set_color(1, DIRT.darkened(0.35))
	burst(parent, at, int(50 * size), 1.4 * size, Vector2(10.0, 30.0) * size, chunks, -45.0, 1.4, 70.0)
	var cloud := Gradient.new()
	cloud.set_color(0, Color(DUST, 0.7))
	cloud.set_color(1, Color(DUST, 0.0))
	var puff := burst(parent, at, int(26 * size), 4.0 * size, Vector2(4.0, 12.0) * size, cloud, 2.0, 2.2, 90.0,
		true)
	if puff != null:
		puff.damping_min = 3.0
		puff.damping_max = 5.0
		puff.scale_amount_curve = _grow()


## UNA RÁFAGA: `amount` piezas de `size` m en `at`, saliendo a entre `speed.x` y `speed.y` m/s (para arriba, abiertas
## `spread` grados), con su color en la vida (`colors`), su gravedad (m/s², para arriba) y cuánto viven (s). Bolas o
## cuadraditos. Se va sola.
static func burst(parent: Node, at: Vector3, amount: int, size: float, speed: Vector2, colors: Gradient,
		gravity: float, lifetime: float, spread := 180.0, round := false) -> CPUParticles3D:
	var piece: PrimitiveMesh = SphereMesh.new() if round else BoxMesh.new()
	if round:
		(piece as SphereMesh).radius = size * 0.5
		(piece as SphereMesh).height = size
		(piece as SphereMesh).radial_segments = 8
		(piece as SphereMesh).rings = 4
	else:
		(piece as BoxMesh).size = Vector3.ONE * size
	var paint := StandardMaterial3D.new()
	paint.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	paint.vertex_color_use_as_albedo = true
	paint.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	piece.material = paint
	var made := CPUParticles3D.new()
	made.mesh = piece
	made.one_shot = true
	made.explosiveness = 1.0
	made.amount = maxi(amount, 1)
	made.lifetime = lifetime
	made.direction = Vector3.UP
	made.spread = spread
	made.initial_velocity_min = speed.x
	made.initial_velocity_max = speed.y
	made.gravity = Vector3(0.0, gravity, 0.0)
	made.scale_amount_min = 0.6
	made.scale_amount_max = 1.4
	made.color_ramp = colors
	made.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if parent == null or not parent.is_inside_tree():
		made.free()
		return null
	parent.add_child(made)
	made.global_position = at
	made.emitting = true
	parent.get_tree().create_timer(lifetime + 0.5).timeout.connect(made.queue_free)
	return made


## Crece en su vida (el polvo se infla).
static func _grow() -> Curve:
	var curve := Curve.new()
	curve.max_value = 2.0
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(1.0, 1.6))
	return curve
