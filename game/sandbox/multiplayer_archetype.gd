class_name MultiplayerArchetype
extends SeededArchetype

## LA FILA MULTIJUGADOR: la red del juego, entera, en una parcela del sandbox (lo pidió el usuario, 06/11/2026:
## «quisiera mantenerla… que se sincronice solamente en esa zona»). Es lo mismo que usaba la partida —SessionManager,
## CharacterSpawner, CharacterNetSync, NetSpawner, NetBody—, sin copias: esta parcela sólo pone las teclas y el lugar.
## Quien maneja la sesión es SandboxSession.
##
## QUÉ SE COMPARTE: los personajes de todos, en todo el sandbox; y lo de esta parcela —cajas, paquetes y una silla—, que
## crea el anfitrión (NetSpawner). Lo de las otras filas es de cada uno (las mecas también, todavía).
##
## TRAÍDA DE CHARACTER-PARAMETRIC el 11/11/2026, sin la nave ni el tablero de allá.

const SIZE := Vector2(30.0, 34.0)
## Dónde aparecen los jugadores, en el marco de la parcela.
const START := Vector3(0.0, 0.5, 12.0)
## Lo que crea el anfitrión al abrir la sesión: tipo de NetSpawner y lugar en el marco de la parcela.
const OBJECTS := [
	["box_light_square", Vector3(-9.0, 0.6, 6.0)],
	["box_heavy_square", Vector3(-6.0, 0.6, 6.0)],
	["package:battery", Vector3(-3.0, 0.6, 6.0)],
	["package:crate_missiles", Vector3(0.0, 0.6, 6.0)],
	["package:component", Vector3(3.0, 0.6, 6.0)],
	["seat", Vector3(-9.0, 0.0, 11.0)],
]


func _init() -> void:
	display_name = "Multijugador"


func max_footprint() -> Vector2:
	return SIZE


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Multijugador"
	parent.add_child(root)
	var sign := Label3D.new()
	sign.text = "MULTIJUGADOR\nH: abrir sesión en esta compu (otra instancia se une con J)\nG: abrir sesión por Steam (código)\nL: salir de la sesión"
	sign.font_size = 64
	sign.pixel_size = 0.006
	sign.modulate = Color(0.25, 0.24, 0.22)
	sign.outline_size = 0
	sign.billboard = BaseMaterial3D.BILLBOARD_FIXED_Y
	sign.position = Vector3(0.0, 2.6, 15.5)
	root.add_child(sign)
	return root


func describe(_seed_value: int) -> PackedStringArray:
	return PackedStringArray([
		"la red del juego: personajes, objetos y una silla compartidos",
		"lo de las otras filas es de cada uno; los personajes se ven en todo el sandbox",
		SandboxSession.status_line()])


func keys() -> Array[SandboxKey]:
	return [
		SandboxKey.action(KEY_H, SandboxKey.Weight.MAIN, "abrir sesión en esta compu (ENet)",
			func(_parcel: SandboxParcel) -> void: SessionManager.host_local()),
		SandboxKey.action(KEY_J, SandboxKey.Weight.MAIN, "unirse a la sesión de esta compu",
			func(_parcel: SandboxParcel) -> void: SessionManager.join_local()),
		SandboxKey.action(KEY_G, SandboxKey.Weight.NORMAL, func() -> String:
				return "abrir sesión por Steam" + (" (código %s)" % SessionManager.lobby_code
					if not SessionManager.lobby_code.is_empty() else ""),
			func(_parcel: SandboxParcel) -> void: SessionManager.host()),
		SandboxKey.action(KEY_K, SandboxKey.Weight.NORMAL, "ir al menú de inicio (unirse por código de Steam)",
			func(_parcel: SandboxParcel) -> void: SessionManager.return_to_menu()),
		SandboxKey.action(KEY_L, SandboxKey.Weight.NORMAL, "salir de la sesión",
			func(parcel: SandboxParcel) -> void:
				var session := SandboxSession.find(parcel.get_tree())
				if session != null:
					session.leave()),
	]
