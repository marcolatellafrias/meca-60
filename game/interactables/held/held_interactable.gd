class_name HeldInteractable
extends Interactable

## UN OBJETO QUE SE SOSTIENE: el manual. (Vino con el teléfono de la nave de character-parametric; en la meca queda el
## manual, que va a tener uso.)
##
## ⚠ NO ES FINAL (el usuario, 13/11/2026: «el sistema mediante el cual los personajes agarran esas cosas… hay que
## revisarlo porque la pose la había dejado medio a medias»): LA POSE con que el personaje sostiene la pieza —cómo llegan
## las manos, dónde queda frente a la cara— quedó sin terminar. Revisarla antes de construir algo encima.
##
## Vive en un lugar fijo —este nodo es su BASE— y tiene una PIEZA que, con un clic, se va con quien la toma: el
## libro a las dos manos. Otro clic la devuelve. Tenerla NO impide moverse, pero más allá del
## ALCANCE de quien la tiene, medido desde su base, se le escapa de la mano y vuelve sola a su lugar: eso es lo que la
## ata a su tablero, y lo que hace que la información del manual sea de uno solo. Era un metro fijo, y desde la silla
## de una consola el libro y el mapa quedaban más lejos que eso: no se podían agarrar (lo decidió el usuario,
## 11/10/2026: que salga del alcance de cada uno).
##
## Las manos llegan por IK a los handle points de la PIEZA (los arma cada objeto como hijos de ella), con el
## mismo ArmsController que maneja un control; como la pieza viaja con la cámara, las manos la siguen solas.
##
## SUENA (ver SoundEntity) con eventos y estados que pone esta base, así cada objeto sólo declara su `SOUNDS`: TAKE al
## alzarla, DROP al soltarla —en el punto del viaje de vuelta que elija su clave en el panel, del clic a la llegada
## (ver SoundEntity, EL MOMENTO); si no se tocó, al llegar—, y los estados RESTING (en su
## lugar), HELD (en la mano) y RETURNING (volviendo), para los loops que suenan mientras (`while`). Todo suena en la
## pieza (`sound_anchor`), que es lo que va y viene.
##
## ⚠ FALTA LA RED: quién la tiene pasa por un ExclusiveClaim (uno solo a la vez, arbitrado por el host), pero en
## las otras máquinas la pieza no se mueve de su lugar.

## SOLTAR es un pedido y un viaje: suena en el punto del viaje que elija su clave (ver SoundEntity, EL MOMENTO).
const SOUND_MOMENTS := [DROP]

## Qué tan rápido viaja la pieza entre su lugar y la mano (fracción por segundo, como un lerp).
const TRAVEL_SPEED := 10.0
## Debajo de esta distancia, de vuelta en su lugar, la pieza se suelta del viaje y se queda quieta.
const SETTLE_DISTANCE := 0.004


## La parte que viaja. La arma cada objeto en `_build_piece`.
var piece: Node3D = null

var _rest: Transform3D = Transform3D()
var _holder_cam: Node3D = null  # el ojo de quien la tiene (ver InteractionController.player_camera)
## DE QUÉ LADO SE LA TIENE: +1 a la derecha, −1 a la izquierda de quien la toma, el lado de donde estaba cuando la tomó
## (el teléfono a la izquierda va a la mano y a la oreja izquierdas). Lo usa `_hold_transform`.
var hold_side := 1.0
var _returning: bool = false
var _claim: ExclusiveClaim = null
## Cuánto tenía que viajar la pieza de vuelta al soltarla: el avance de la transición de DROP sale de lo que le falta.
var _drop_span := 0.0
## DÓNDE ESTÁ LA PIEZA RESPECTO DE LA BASE mientras viaja (ver `_process`): se guarda de un cuadro al otro, así la pieza
## —que va suelta del árbol, `top_level`— se mueve con la base aunque la base se mueva.
var _piece_local := Transform3D()

## Se la llevó alguien (en la máquina de quien la tomó).
signal taken()
## Volvió a soltarse —por un clic, por irse de rango o porque el host se la dio a otro—. El InteractionController
## escucha esto y no otra cosa para dejar de sostenerla: una sola salida para todos los casos.
signal dropped()


func _ready() -> void:
	piece = _build_piece()
	piece.name = "Piece"
	add_child(piece)
	_rest = piece.transform
	var extent := _rest_box()
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = extent.size
	shape.shape = box
	shape.position = extent.get_center()
	body.add_child(shape)
	add_child(body)
	_claim = ExclusiveClaim.new()
	_claim.name = "Claim"  # nombre estable → mismo path en todas las máquinas
	add_child(_claim)
	_claim.revoked.connect(release)
	set_sound_state(RESTING)


## Suena en la pieza, que es lo que va a la mano.
func sound_anchor(_event: StringName) -> Node3D:
	return piece if is_instance_valid(piece) else self


# ── Lo que pone cada objeto ───────────────────────────────────────────────────

## La pieza, armada en su pose de reposo (relativa a la base) y con sus handle points ya agregados.
func _build_piece() -> Node3D:
	return Node3D.new()

## La caja que se apunta para tomarla, en el espacio de la base.
func _rest_box() -> AABB:
	return AABB(Vector3(-0.1, 0.0, -0.1), Vector3(0.2, 0.1, 0.2))

## Dónde va la pieza mientras se la tiene, relativo a la cámara (−Z adelante, +X a la derecha).
func _hold_transform() -> Transform3D:
	return Transform3D(Basis(), Vector3(0.0, -0.15, -0.4))

## DÓNDE VA LA PIEZA en la mano, relativo a la cámara. (Las poses de sostener, HoldPose, se borraron el 29/10/2026 con
## la animación vieja de las manos: vuelven con su categoría.)
func held_transform() -> Transform3D:
	return _hold_transform()

## La rueda del mouse mientras se la tiene.
func handle_scroll(_dir: float) -> void:
	pass

## El clic derecho mientras se la tiene, apretado o suelto (el mapa acerca mientras está apretado; ver MapInteractable).
func handle_zoom(_pressed: bool) -> void:
	pass

## EL MOUSE, MIENTRAS SE LA TIENE, en píxeles: la pieza puede usarlo (el mapa acercado corre el papel con él; ver
## MapInteractable) y devuelve cuánto de él le queda a la vista para girar, de 0 a 1. De entrada, todo: se camina y se
## mira con ella en la mano.
func handle_look(_relative: Vector2) -> float:
	return 1.0

## Cuánto gira la vista el mouse mientras se la tiene: 1, lo de siempre (el mapa acercado moviendo la cabeza lo baja, ver
## MapInteractable.slide_paper).
func look_scale() -> float:
	return 1.0

## ADÓNDE VA LA PIEZA mientras se la tiene, respecto de la base: de entrada, a la mano, delante de la cámara (el mapa con
## zoom del ojo, acercado, se queda quieto donde estaba; ver MapInteractable).
func _held_target(base: Transform3D) -> Transform3D:
	return base.affine_inverse() * _holder_cam.global_transform * held_transform()

func _on_taken() -> void:
	pass

func _on_dropped() -> void:
	pass


# ── Tomar y soltar ─────────────────────────────────────────────────────────────

func can_interact() -> bool:
	return not is_held() and (_claim == null or _claim.is_free())

## Tomada, donde va a estar en la mano (el libro delante de los ojos, el tubo en la oreja): con eso se elige la mano.
func grip_center() -> Vector3:
	if is_instance_valid(_holder_cam):
		return _holder_cam.global_transform * held_transform().origin
	return global_position


func is_held() -> bool:
	return is_instance_valid(_holder_cam)

## La toma quien mira por `cam`. Falso si no se puede.
func take(cam: Node3D) -> bool:
	if not can_interact() or not is_instance_valid(cam):
		return false
	_claim.request()
	_holder_cam = cam
	var from_cam := cam.global_transform.affine_inverse() * global_position
	hold_side = -1.0 if from_cam.x < 0.0 else 1.0
	if _returning:
		cancel_sound_transition(DROP)  # la agarraron de nuevo a mitad de camino
	if not _returning:
		_piece_local = piece.transform
	_returning = false
	piece.top_level = true
	set_sound_state(HELD)
	play_sound(TAKE)
	_on_taken()
	taken.emit()
	return true

## La suelta y la manda de vuelta a su lugar.
func release() -> void:
	if not is_held():
		return
	_holder_cam = null
	_returning = true
	if _claim.is_mine():
		_claim.release()
	set_sound_state(RETURNING)
	_drop_span = _piece_local.origin.distance_to(_rest.origin)
	begin_sound_transition(DROP)
	_on_dropped()
	dropped.emit()

## Si quien la tiene, parado en `origin` y con alcance `reach`, ya se fue más lejos de la base que su alcance.
func is_out_of_range(origin: Vector3, reach: float) -> bool:
	return origin.distance_to(global_position) > reach


# ── El viaje de la pieza ──────────────────────────────────────────────────────

## EL VIAJE SE CUENTA DESDE LA BASE, no en el mundo: la base va con lo que la lleva —la meca—, así que si la meca vuela la
## pieza no se queda atrás (el usuario, 31/10/2026: «cuando me meto a bordo de la nave con la U… el mapa o el
## manual quedan desfasados»; contado en el mundo, a 24 m/s la pieza iba unos 2 m detrás de la mano, y de costado en las
## curvas). La pieza guarda dónde está respecto de la base (`_piece_local`) y viaja desde ahí: sacarlo de su lugar en el
## mundo arrastraba el atraso. Con la base quieta es lo mismo que antes, y el suavizado al girar la cabeza sigue igual.
func _process(delta: float) -> void:
	var k: float = clampf(delta * TRAVEL_SPEED, 0.0, 1.0)
	var base := global_transform
	if is_held():
		_piece_local = _piece_local.interpolate_with(_held_target(base), k)
		piece.global_transform = base * _piece_local
	elif _returning:
		_piece_local = _piece_local.interpolate_with(_rest, k)
		piece.global_transform = base * _piece_local
		var left := _piece_local.origin.distance_to(_rest.origin)
		if _drop_span > 0.0:
			sound_transition(DROP, 1.0 - left / _drop_span)
		if left < SETTLE_DISTANCE:
			piece.top_level = false
			piece.transform = _rest
			_returning = false
			set_sound_state(RESTING)
			end_sound_transition(DROP)
