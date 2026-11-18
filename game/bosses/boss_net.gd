class_name BossNet
extends NetFollow

## ── UN JEFE POR LA RED (18/11/2026; módulo Jefes; plan de la partida en red, paso 8) ────────────────────────────────
## Lo simula EL HOST: su cabeza (BrawlerBrain) piensa sólo ahí, decide los ataques y los golpes, y la vida la decide el
## host (Health). Las demás máquinas no lo simulan: ponen su cuerpo donde dice el host (lo común de NetFollow) y arman
## con eso su esqueleto, sus capas y su caja de golpe, igual que en el host. Viaja lo físico y lo que se ve del cuerpo:
## dónde está, el rumbo de las orugas y de la cintura, la pose, el trompo, el horno y la ira, si vuela, a cuánto va y el
## resorte. *Falta: lo que se ve de sus ataques (las zonas en el piso, la piedra, el fuego, la onda, el gancho): hoy
## sólo en el host.*

var boss: Brawler = null


func _state_now() -> Array:
	return [boss.global_position, boss.hull_yaw, boss.waist_yaw, int(boss.pose), boss.spin, boss.furnace, boss.rage,
		boss.aloft(), boss.speed, boss.body_spring.y, boss.body_spring.xz]


func _apply(from: Array, to: Array, share: float, _ahead: float, _delta: float) -> void:
	boss.follow_net(from, to, share)
