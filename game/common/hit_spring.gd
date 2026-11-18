class_name HitSpring
extends RefCounted

## ── EL RESORTE DE LOS GOLPES, PARA CUALQUIER CUERPO (18/11/2026) ───────────────────────────────────────────────────
## Lo pidió el usuario: los dos resortes de los personajes —el de costado (los golpes) y el vertical (el aterrizaje)—
## como una sola pieza para los personajes, la meca propia y los jefes («para recibir más feedback de los hits»; «un solo
## sistema que sea robusto, así no tenemos que mantener dos codebases»). Es sólo la cuenta: no mueve nada. Quien lo
## tiene le pasa los golpes en SUS ejes y lee las salidas para inclinar lo suyo (el personaje, la base de la columna:
## ver animations.gd; una meca o un jefe, su torso o su pelvis).
##
## DE COSTADO (`xz`, de 0 a 1 por eje; 1, tirado): la suma de DOS resortes iguales, el de los GOLPES (`hit_xz`, de
## reposo cero) y el de lo CONTINUO (`lean_xz`, que va hacia `lean_target`: la inercia de lo que lo lleva). Se separan
## porque la cámara sigue sólo a los golpes. Un golpe `dv` (m/s, ejes propios) inclina `dv × lean_per_ms / firmeza`; si
## UN SOLO golpe pasa `threshold`, `hit` devuelve verdadero: tumba (lo hace quien lo tiene). Lo que se junta de a poco
## sólo inclina, hasta el borde.
## VERTICAL (`y`, de −1 a 1): el aterrizaje. Un golpe vertical de más de `land_threshold` m/s lo hunde, del todo a
## `land_full_speed`, y el resorte vertical lo devuelve.
##
## Uso: `hit(dv_propio_xz, firmeza, puede_caer)`, `land(dv_y)`, `update(delta)` en cada paso, y leer `xz`, `hit_xz`, `y`.
## *Hasta el 18/11/2026 vivía adentro de la cápsula de los personajes (CharacterRigidBody3D).*

## De costado: qué tan duro se endereza (1/s²), cuánto frena el rebote (1/s), cuánto inclina cada m/s, dónde tumba y lo
## que no llega a ser un golpe (m/s).
const LEAN_PER_MS := 0.3
var stiffness := 25.0
var damping := 6.0
var lean_per_ms := LEAN_PER_MS
var threshold := 0.85
var noise := 0.3
## Vertical: desde cuánto se hunde (m/s), a qué velocidad del todo (m/s), y su resorte.
var land_threshold := 2.0
var land_full_speed := 10.0
var land_stiffness := 25.0
var land_damping := 6.0
## EL QUIEBRE COMO EMPUJÓN (las mecas; 18/11/2026, el usuario: «el peso se siente en el quiebre inicial nada más… la
## vuelta… nunca sluggish»): en vez de quedar hundido de una, sale hacia abajo con la velocidad justa para llegar a lo
## mismo en un instante (1/√rigidez s) y el resorte lo devuelve. Apagado, como los personajes: hundido de una.
var land_push := false

## Lo continuo va hacia acá (la inercia de lo que lo lleva, en la unidad de `xz`): lo escribe quien lo tiene.
var lean_target := Vector2.ZERO

var hit_xz := Vector2.ZERO
var lean_xz := Vector2.ZERO
var y := 0.0
var _hit_vel := Vector2.ZERO
var _lean_vel := Vector2.ZERO
var _y_vel := 0.0


## LO QUE INCLINA AHORA, de costado: los golpes más lo continuo.
var xz: Vector2:
	get:
		return hit_xz + lean_xz


## LO QUE MANDA OTRO (la red): la inclinación entera, ya calculada en su máquina.
func set_xz(value: Vector2) -> void:
	hit_xz = value
	lean_xz = Vector2.ZERO


## UN GOLPE DE COSTADO de `dv` (m/s, en los ejes de quien lo tiene; x de costado, y adelante y atrás). Verdadero si
## tumba: un solo golpe que pasa el umbral, con `can_fall`. Si no, inclina, sin pasar del borde.
func hit(dv: Vector2, firmness := 1.0, can_fall := true) -> bool:
	if dv.length() <= noise:
		return false
	var push := dv * lean_per_ms / maxf(firmness, 0.05)
	hit_xz = (hit_xz + push).limit_length(1.0)
	_hit_vel = Vector2.ZERO
	if can_fall and push.length() >= threshold:
		return true
	if xz.length() >= threshold:
		hit_xz = xz.limit_length(threshold * 0.95) - lean_xz
	return false


## UN GOLPE VERTICAL de `dv_y` (m/s; positivo, el piso lo frenó al caer): lo hunde, si pasa `land_threshold`.
func land(dv_y: float) -> void:
	if absf(dv_y) <= land_threshold:
		return
	var depth := clampf(dv_y / land_full_speed, -1.0, 1.0)
	if land_push:
		# Un resorte casi crítico empujado con v llega a ~v / (ω·e) en 1/ω.
		_y_vel += depth * sqrt(land_stiffness) * exp(1.0)
		return
	y = clampf(y + depth, -1.0, 1.0)
	_y_vel = 0.0


func update(delta: float) -> void:
	var lean_acc := -(lean_xz - lean_target) * stiffness - _lean_vel * damping
	_lean_vel += lean_acc * delta
	lean_xz += _lean_vel * delta
	var hit_acc := -hit_xz * stiffness - _hit_vel * damping
	_hit_vel += hit_acc * delta
	hit_xz += _hit_vel * delta
	var y_acc := -y * land_stiffness - _y_vel * land_damping
	_y_vel += y_acc * delta
	y += _y_vel * delta


## LA INCLINACIÓN DE LOS GOLPES EN GRADOS, para un cuerpo que la dibuja girando (una meca, un jefe): x adelante y
## atrás (positivo, para atrás), y de costado (positivo, a la derecha); `TILT_DEGREES` en el borde.
const TILT_DEGREES := 20.0


func tilt_degrees() -> Vector2:
	return Vector2(hit_xz.y, hit_xz.x) * TILT_DEGREES


## DE COSTADO, A CERO (al tumbar: tirado no se inclina).
func reset_xz() -> void:
	hit_xz = Vector2.ZERO
	lean_xz = Vector2.ZERO
	_hit_vel = Vector2.ZERO
	_lean_vel = Vector2.ZERO


func reset() -> void:
	reset_xz()
	y = 0.0
	_y_vel = 0.0
