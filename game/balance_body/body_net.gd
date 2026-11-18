class_name BodyNet
extends NetFollow

## ── UN CUERPO CON EQUILIBRIO POR LA RED (18/11/2026; módulo Jefes, el sistema común de movimiento) ──────────────────
## La regla acordada con el usuario (docs/technical/movimiento-comun.md, «Qué viaja por la red»): VIAJA LO QUE LA OTRA
## MÁQUINA NO PUEDE DEDUCIR. Lo físico viaja (el motor: dónde está, el rumbo, la velocidad, lo agachada, el estado y la
## caída, si levita o recoge las piernas, y las dos salidas del resorte); el esqueleto, las piernas, los pies, el
## caminar y el polvo se calculan en cada máquina con eso, igual que en la del dueño. Lo de seguir (el dueño, mandar,
## el buffer y la mezcla) es lo común de NetFollow.
##   · EL DUEÑO: por defecto el host; quien la posee con la O desde su máquina la toma (`take_control`, ver
##     MechKeys.begin). Manejada desde adentro, los controles ya viajan (los tableros: ControllableInteractable) y le
##     llegan al dueño.
##   · LOS GOLPES DE UN JEFE (los decide el host, que es quien lo simula): la reacción se hace en la máquina del dueño
##     (`relay_hit`: lo que se ve en todas, el empujón y la caída en la del dueño). AGARRADA, la toma el host mientras la
##     lleva y la revolea (`borrow`), y se la devuelve al que la manejaba cuando vuelve a estar parada (`give_back`).
## *Falta: las piñas, el cañón y el escudo poseyéndola con el teclado (los hace Armas, con este mismo dueño) y la
## energía.*

var body: BalanceBody = null
## A quién devolvérsela después de agarrarla (0: a nadie).
var _lent_by := 0


func _state_now() -> Array:
	return body.mover.net_state()


func _apply(from: Array, to: Array, share: float, ahead: float, delta: float) -> void:
	body.mover.follow(from, to, share, ahead, delta)


## La simula esta máquina otra vez: el motor deja lo que le decía el dueño de antes.
func _owner_changed() -> void:
	if not remote():
		body.mover.stop_following()


## UN GOLPE QUE DECIDIÓ EL HOST, en las demás máquinas: la reacción entera (en la del dueño, también el empujón).
@rpc("any_peer", "call_remote", "reliable")
func relay_hit(kind: int, away: Vector3, distance: float, at: Vector3) -> void:
	HitReaction.of(body).react(kind as HitReaction.Kind, away, distance, at)


## LA AGARRARON (el host): mientras la lleva, la simula el host.
func borrow() -> void:
	if not networked() or not multiplayer.is_server() or authority == multiplayer.get_unique_id():
		return
	_lent_by = authority
	hand_to(multiplayer.get_unique_id())


## Ya parada otra vez: vuelve a quien la manejaba.
func give_back() -> void:
	if _lent_by == 0:
		return
	var to := _lent_by
	_lent_by = 0
	hand_to(to)


func lent() -> bool:
	return _lent_by != 0
