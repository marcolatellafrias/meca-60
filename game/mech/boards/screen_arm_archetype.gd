class_name ScreenArmArchetype
extends PanelArchetype

## UNA PANTALLITA EN UN BRAZO FIJO (17/11/2026, el usuario: «tener un indicador en alguna de las pantallas de arriba de
## la energía… y en otra el tiempo de carga, como una barrita»; «no plegable, porque van a estar en posición fija, pero en
## una posición que me permita ver su información mientras estoy manejando los brazos y mirando el frente»). Una pieza de
## la grilla (su base, FaceMount) con la rótula, dos tramos y en la punta la pantalla: un marco, el título y UNA BARRA que
## se llena con lo que diga `source` (0 a 1). Dónde queda la pantalla lo pone quien la monta (`reach_to`, como el brazo
## plegable): mirando a los ojos de quien la lee.

const CELLS := Vector2i(3, 3)
const ROD := 0.016
## La pantalla: ancho, alto y fondo (m).
const SCREEN := Vector3(0.2, 0.09, 0.025)
const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.2, 0.21, 0.23)
const GLASS := Color(0.08, 0.12, 0.1)

## El título de la pantalla y el color de su barra.
var title := ""
var color := Color(0.4, 0.9, 0.5)


func _init(p_title := "", p_color := Color(0.4, 0.9, 0.5)) -> void:
	title = p_title
	color = p_color
	display_name = "Pantalla %s" % title


func cells(_seed_value: int) -> Vector2i:
	return CELLS


## La pantalla de una montada (la raíz que devuelve `mount`).
static func screen_of(root: Node) -> BarScreen:
	return root.get_node_or_null("Pantalla") as BarScreen


func _build_on(_seed_value: int, root: Node3D, area: Vector2) -> void:
	Clay.cylinder(root, minf(area.x, area.y) * 0.3, 0.03, Vector3(0.0, 0.0, 0.015), METAL, Vector3(90.0, 0.0, 0.0))
	var screen := BarScreen.new()
	screen.name = "Pantalla"
	screen.piece = root
	screen.title = title
	screen.color = color
	root.add_child(screen)


## ── LA PANTALLA EN LA PUNTA, con sus dos tramos ──────────────────────────────────────────────────────────────────

class BarScreen extends Node3D:
	## Lo que muestra la barra (0 a 1): lo pone quien la monta.
	var source := Callable()
	var piece: Node3D = null
	var title := ""
	var color := Color.WHITE
	var _fill: MeshInstance3D = null
	var _rods: Array[Node3D] = []
	var _elbow: Node3D = null
	var _face: Node3D = null

	func _ready() -> void:
		_face = Node3D.new()
		add_child(_face)
		Clay.box(_face, ScreenArmArchetype.SCREEN, Vector3.ZERO, ScreenArmArchetype.DARK)
		Clay.box(_face, Vector3(ScreenArmArchetype.SCREEN.x * 0.9, ScreenArmArchetype.SCREEN.y * 0.8, 0.004),
			Vector3(0.0, 0.0, ScreenArmArchetype.SCREEN.z * 0.5), ScreenArmArchetype.GLASS)
		_fill = Clay.box(_face, Vector3(1.0, ScreenArmArchetype.SCREEN.y * 0.3, 0.004), Vector3.ZERO, color)
		var label := Label3D.new()
		label.text = title
		label.font_size = 24
		label.pixel_size = 0.0012
		label.outline_size = 0
		label.modulate = Color(0.85, 0.9, 0.85)
		label.position = Vector3(0.0, ScreenArmArchetype.SCREEN.y * 0.24, ScreenArmArchetype.SCREEN.z * 0.5 + 0.004)
		_face.add_child(label)
		for i in 2:
			_rods.append(Clay.limb(piece, ScreenArmArchetype.ROD, 1.0, Vector3.ZERO, ScreenArmArchetype.METAL))
		_elbow = Clay.sphere(piece, 0.025, Vector3.ZERO, ScreenArmArchetype.DARK)

	## LA PANTALLA EN `tip` mirando a `eye`, los dos en el espacio de `space` (un antecesor de la pieza): dos tramos desde
	## la rótula, con el codo hacia arriba.
	func reach_to(tip: Vector3, eye: Vector3, space: Node3D) -> void:
		var to_piece := FoldingArm._relative(piece, space).affine_inverse()
		var at := to_piece * tip
		var look := to_piece * eye
		var hub := Vector3(0.0, 0.0, 0.04)
		var reach := hub.distance_to(at)
		var lengths := Vector2(reach * 0.56, reach * 0.56)
		var up := (to_piece.basis * Vector3.UP).normalized()
		var elbow := FoldingArm.elbow_of(hub, at, lengths, up)
		FoldingArm._rod(_rods[0], hub, elbow)
		FoldingArm._rod(_rods[1], elbow, at)
		_elbow.position = elbow
		# La cara de la pantalla (su +Z) mira a los ojos, derecha.
		var facing := (look - at).normalized()
		var side := up.cross(facing).normalized()
		position = Vector3.ZERO
		_face.transform = Transform3D(Basis(side, facing.cross(side), facing), at)

	func _process(_delta: float) -> void:
		var value := clampf(float(source.call()), 0.0, 1.0) if source.is_valid() else 0.0
		var wide := ScreenArmArchetype.SCREEN.x * 0.84
		_fill.scale.x = maxf(value * wide, 0.001)
		_fill.position = Vector3(-wide * 0.5 + value * wide * 0.5, -ScreenArmArchetype.SCREEN.y * 0.12,
			ScreenArmArchetype.SCREEN.z * 0.5 + 0.003)
