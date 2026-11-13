class_name PackageArchetype
extends SeededArchetype

## UN TIPO DE OBJETO AGARRABLE como arquetipo: QUÉ es (su tamaño en celdas, su peso, su fragilidad) y CÓMO SE VE. De
## acá sale el cuerpo real del juego: un `RigidBody3D` con su masa, su collider cúbico, un `GrabbableInteractable` que
## le genera los puntos de agarre desde las celdas, y su daño (`PackageDamage`).
##
## EN LA MECA SON SUS RECURSOS (13/11/2026; ver docs/recursos.md): todos UN CUBO DE 63 cm, y su dibujo lo hace
## SupplyLook. *Vino de character-parametric con los paquetes de una ciudad —un televisor, un sillón de dos metros, un
## cajón de botellas— de varios tamaños, cada uno con su bosquejo de primitivas y su ida y vuelta a Blender; se borraron
## el 13/11/2026.*
##
## ── EL TAMAÑO SE DECLARA EN CELDAS, NO EN METROS ────────────────────────────
## De las celdas salen los metros (`GrabbableInteractable.CELL_SIZE`) y los puntos de agarre.
##
## ── EL PESO ES EL ÚNICO NÚMERO QUE SE SIENTE ─────────────────────────────
## La rigidez del agarre escala con la masa, así que todo objeto responde igual de rápido: lo que hace que el peso SE
## SIENTA es el techo de fuerza del agarrador (`FORCE_PER_STRENGTH`, newtons por unidad de `strength`), que nunca baja
## del peso: todo se levanta, también solo, y lo que pasa la fuerza de uno sube despacio y se lleva lento (ver
## GrabbableInteractable.LIFT_MARGIN). Por eso el panel imprime A QUÉ VELOCIDAD lo lleva solo cada uno (ver `_lifters`).

const CELL := GrabbableInteractable.CELL_SIZE

## Cuánto más grande que el objeto es su parcela del sandbox, en metros y por eje: lo que hace falta
## para darle la vuelta al bosquejo sin salirse del marco.
const PARCEL_MARGIN := Vector2(0.9, 0.9)

## ── EL SHADER DEL DAÑO, Y POR QUÉ SON DOS ──────────────────────────────────────────────────────
## Toda pieza de un bosquejo se dibuja con esto en vez de un `StandardMaterial3D`, porque el daño se
## tiene que VER y por ahora se ve de la manera más simple que hay: el objeto se oscurece. El color de la
## pieza entra como uniforme (`tint`) y `damage` —0 entero, 1 destruido— lo apaga hasta `DARKEST`. Lo
## escribe `PackageDamage`; en un objeto sano el shader hace exactamente lo que hacía el material de
## antes.
##
## El shader se compila UNA SOLA VEZ para todas las piezas de todos los paquetes: lo que cambia de una a
## otra son los uniformes, que viven en su material. Es el mismo criterio que las lentes que titilan del
## tablero (ver ProceduralDashboard.BLINK_SHADER).
##
## ⚠ SON DOS SHADERS Y NO UNO CON UN `fade`, y es a propósito: en Godot nombrar ALPHA es una decisión del
## SHADER ENTERO, no de la rama que la usa — manda todo lo que lo use a la cola de transparencias, con su
## ordenamiento y sin prepaso de profundidad. La translucidez la necesita UNA tecla del sandbox (la M de
## la fila) y no la necesita el juego, así que vive en un shader aparte al que `set_sketch` cambia; el
## opaco, que es el que corre siempre, no paga nada por ella. Los uniformes se llaman igual en los dos,
## así que cambiar de shader no pierde ni el color ni el daño.
const SHADER_CODE := """shader_type spatial;
uniform vec4 tint : source_color;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float darkest = 0.3;
void fragment() {
	ALBEDO = tint.rgb * mix(1.0, darkest, damage);
}"""
const GHOST_SHADER_CODE := """shader_type spatial;
render_mode blend_mix;
uniform vec4 tint : source_color;
uniform float damage : hint_range(0.0, 1.0) = 0.0;
uniform float darkest = 0.3;
uniform float fade = 1.0;
void fragment() {
	ALBEDO = tint.rgb * mix(1.0, darkest, damage);
	ALPHA = fade;
}"""
## Cuánto queda del color con el daño al máximo. El mismo número que `PackageDamage.DARKEST`, puesto acá
## como uniforme del shader; quien manda es el daño.
const DARKEST := 0.3

static var _shader: Shader = null
static var _ghost_shader: Shader = null


## El shader de las piezas, compilado una vez. `ghost` da el de la vista translúcida del sandbox.
static func shader(ghost := false) -> Shader:
	if ghost:
		if _ghost_shader == null:
			_ghost_shader = Shader.new()
			_ghost_shader.code = GHOST_SHADER_CODE
		return _ghost_shader
	if _shader == null:
		_shader = Shader.new()
		_shader.code = SHADER_CODE
	return _shader


## Los tres estados del bosquejo que cicla la tecla M de la fila. Arranca SÓLIDO, y los gizmos apagados:
## lo primero que la fila tiene que mostrar es EL OBJETO, y los gizmos y la transparencia son con lo que
## se le mira la construcción cuando uno fue a eso. Al revés —abriendo con 111 esferas y el bosquejo a
## medias— la fila no muestra ni una cosa ni la otra.
enum Sketch {SOLID, TRANSLUCENT, HIDDEN}
const SKETCH_NAMES := ["sólido", "traslúcido", "oculto"]
const SKETCH_DEFAULT := Sketch.SOLID
const GIZMOS_DEFAULT := false
const SKETCH_FADE := 0.6

## Los nombres de los nodos que buscan las teclas de la fila para prender y apagar sin reconstruir.
const SKETCH_NODE := "bosquejo"
const GRID_NODE := "grilla"

const GRID_COLOR := Color(0.96, 0.96, 0.96, 0.45)

## Por qué nombre se lo pide, y con qué bosquejo se dibuja (ver `build_body`).
var key := "box"
## Ancho × alto × fondo EN CELDAS, en los mismos ejes que `GrabbableInteractable.setup_from_cells`.
var cells := Vector3i(4, 4, 4)
## Kilos. Ver el bloque de arriba: es el único número que se siente.
var weight := 10.0
## CUÁNTO LE DUELE CADA GOLPE, en múltiplos (ver PackageDamage): 1.0 es frágil —dos caídas de 3 m y se
## rompe— y 0.1 es casi indestructible. Es independiente del peso a propósito: un televisor es liviano y
## frágil, una caja fuerte es pesadísima y no le pasa nada, y eso es justamente lo que las distingue al
## cargarlas.
var fragility := 1.0
## DE QUÉ ES, para cómo suena al golpear (ver PackageDamage.MATERIALS).
var material: StringName = &"madera"


func _init(p_key := "box", p_name := "Caja", p_cells := Vector3i(4, 4, 4), p_weight := 10.0,
		p_fragility := 1.0, p_material: StringName = &"madera") -> void:
	key = p_key
	display_name = p_name
	cells = p_cells
	weight = p_weight
	fragility = p_fragility
	material = p_material


## LOS OBJETOS QUE HAY: un solo catálogo, así que uno nuevo aparece en todos lados (el lote del sandbox, la red).
static func catalogue() -> Array[SeededArchetype]:
	# EN LA MECA, LOS PAQUETES SON SUS RECURSOS (13/11/2026): todos UN CUBO DE 63 cm —seis celdas por lado, un módulo:
	# un punto de agarre en el centro de cada cara— que se agarra siempre igual (el usuario: «no vamos a tener paquetes
	# dobles ni más largos… una celda de tamaño único»). Su dibujo, en SupplyLook.
	var out: Array[SeededArchetype] = []
	var cube := Vector3i(6, 6, 6)
	out.append(PackageArchetype.new("battery", "Batería", cube, 45.0, 0.3, &"metal"))
	out.append(PackageArchetype.new("component", "Componente eléctrico", cube, 30.0, 0.6, &"metal"))
	out.append(PackageArchetype.new("crate_missiles", "Caja de misiles", cube, 40.0, 0.1, &"madera"))
	out.append(PackageArchetype.new("crate_bullets", "Caja de balas", cube, 40.0, 0.1, &"madera"))
	out.append(PackageArchetype.new("bomb", "Bomba", cube, 25.0, 0.2, &"madera"))
	return out


## El tamaño del objeto en metros, que es el de su collider.
func size_m() -> Vector3:
	return Vector3(cells.x, cells.y, cells.z) * CELL


## A qué altura va el origen del cuerpo para que el objeto apoye en el piso: el cuerpo nace CENTRADO en
## su caja.
func rest_height() -> float:
	return size_m().y * 0.5


func max_footprint() -> Vector2:
	var size := size_m()
	return Vector2(size.x, size.z) + PARCEL_MARGIN


# ── El cuerpo del juego ──────────────────────────────────────────────────────────────────────────

## EL OBJETO REAL, tal como va a existir en el juego: el cuerpo con su masa, el collider cúbico de la
## caja de celdas, el bosquejo adentro, la grilla de celdas y el agarrable que genera sus puntos. Lo
## usan la parcela del sandbox, el lote de la jornada (NetSpawner) y el de prueba de la sucursal (BranchLot):
## acá no hay nada que sea de debug.
func build_body() -> RigidBody3D:
	var size := size_m()

	var body := RigidBody3D.new()
	body.name = key
	body.mass = weight
	# Dormido al nacer: un objeto apoyado que simula desde el primer frame se asienta con un salto que
	# se ve, y no hay nada que simular hasta que alguien lo toca.
	body.sleeping = true

	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collider.shape = box
	body.add_child(collider)

	# EL DIBUJO, en su nodo: es el que buscan el daño y las teclas de la fila.
	var sketch := Node3D.new()
	sketch.name = SKETCH_NODE
	body.add_child(sketch)
	_build_sketch(sketch, size)

	_build_cell_grid(body, size)

	var grabbable := GrabbableInteractable.new()
	grabbable.name = "Grabbable"  # nombre estable, igual que en el personaje: por ahí rutea el grab sync
	body.add_child(grabbable)
	grabbable.setup_from_cells(cells.x, cells.y, cells.z)

	# EL DAÑO ES PARTE DEL OBJETO, no de dónde está: el mismo cuerpo lo lleva en la parcela (donde va
	# congelado y nunca recibe un golpe, así que el nodo no hace nada) y en los lotes, el del juego y el de
	# la sucursal. Quien quiera mostrar la vida o decidir qué pasa al romperse se engancha a sus señales.
	var damage := PackageDamage.new()
	damage.name = "Damage"
	damage.fragility = fragility
	damage.material = material
	body.add_child(damage)
	return body


## El individuo de la parcela: el cuerpo real apoyado en el piso, con los gizmos que la fila tenga
## elegidos. La semilla todavía no cambia nada (ver `describe`).
##
## ACÁ EL CUERPO VA CONGELADO, y es la misma decisión que la nave de su fila: una parcela muestra UN
## diseño y tiene que seguir mostrándolo: suelto, el paquete se lo lleva cualquiera que lo roce y la fila
## queda desarmada hasta que alguien aprieta R. Kinemático y no estático porque sigue siendo un cuerpo
## con el que se choca, no decorado.
##
## Y con el cuerpo congelado NO SE OFRECE EL AGARRE (`offers_grab`): el solver mueve el cuerpo con
## fuerzas y a un `freeze` las fuerzas no le hacen nada, así que resaltarlo y ofrecer "[LMB] to grab"
## sería mentir. Agarrarlo de verdad es en el lote de prueba de la sucursal (BranchLot), que lo construye suelto.
func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "paquete"
	parent.add_child(root)

	var body := build_body()
	body.freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	body.freeze = true
	for node in body.find_children("*", "GrabbableInteractable", false, false):
		(node as GrabbableInteractable).offers_grab = false
	# La posición ANTES de entrar al árbol: el contenido de un contenedor se ubica respecto del cuerpo en
	# cuanto entra (ver PackageContents._ready), y la parcela lo mide en ese mismo cuadro.
	body.position = Vector3(0.0, rest_height(), 0.0)
	root.add_child(body)

	set_gizmos(body, bool(options.get("gizmos", GIZMOS_DEFAULT)))
	set_sketch(body, int(options.get("bosquejo", SKETCH_DEFAULT)))
	return root


# ── El panel ─────────────────────────────────────────────────────────────────────────────────────

func describe(_seed_value: int) -> PackedStringArray:
	var size := size_m()
	# Los puntos se CUENTAN preguntándole al agarrable del juego, no con la cuenta de `GRAB_DENSITY`
	# repetida acá: el panel tiene que decir cuántos hay, no cuántos debería haber.
	var grabbable := GrabbableInteractable.new()
	grabbable.setup_from_cells(cells.x, cells.y, cells.z)
	var grabs := grabbable.grab_points.size()
	var handles := grabbable.handle_points.size()
	grabbable.free()

	var out := PackedStringArray()
	out.append("%d × %d × %d celdas · %.2f × %.2f × %.2f m"
		% [cells.x, cells.y, cells.z, size.x, size.y, size.z])
	out.append("%.0f kg · %.0f N para sostenerlo" % [weight, weight * 9.8])
	out.append("solo, a qué velocidad: %s" % _lifters())
	out.append("%d puntos de agarre · %d de mano" % [grabs, handles])
	out.append("fragilidad %.2f · %s" % [fragility, _breaks()])
	out.append("congelado acá; se agarra y se rompe en el lote de la sucursal")
	return out


## A QUÉ VELOCIDAD LO LLEVA SOLO CADA UNO, el más lento primero. Todo paquete se levanta, también solo (ver
## GrabbableInteractable.LIFT_MARGIN): el peso se siente en la lentitud. Derivado con las dos cuentas del agarrador
## —la carga (`load_of`) y lo que queda de la velocidad (`carry_speed_factor`)—, así no se desfasa de cómo se juega.
## Los que lo llevan a paso normal no se nombran uno por uno.
func _lifters() -> String:
	var slow: Array = []
	for i in EntityArchetype.Archetype.size():
		var arch := EntityArchetype.create(i as EntityArchetype.Archetype)
		var speed := GrabbableInteractable.carry_speed_factor(GrabbableInteractable.load_of(weight, arch.strength))
		if speed < 0.995:
			slow.append([speed, String(EntityArchetype.Archetype.keys()[i]).to_lower()])
	if slow.is_empty():
		return "cualquiera, a paso normal"
	slow.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var parts := PackedStringArray()
	for entry: Array in slow:
		parts.append("%s %.0f %%" % [entry[1], float(entry[0]) * 100.0])
	if slow.size() < EntityArchetype.Archetype.size():
		parts.append("el resto, normal")
	return ", ".join(parts)


## CUÁNTAS CAÍDAS DE `FALL_REFERENCE_M` AGUANTA, que es la lectura útil de la fragilidad igual que "quién
## a qué velocidad lo llevan" es la del peso: "fragilidad 0.08" no dice nada, "diecinueve caídas de 3 m" dice qué
## objeto es. Sale de los mismos números con los que `PackageDamage` cuenta el golpe, así que no puede
## desfasarse de él — y es UNA SOLA cuenta, que usan el panel y el test (tests/packages.tscn), porque
## dos cuentas que se prometen lo mismo se separan.
##
## ⚠ LO QUE CAE ES LA BASE Y NO EL ORIGEN, y esa media altura importa: suelto desde 3 m, un objeto de
## 84 cm de alto golpea habiendo caído 2,58 y llega a 7,11 m/s en vez de 7,67. Con la cuenta ingenua el
## panel prometía 18 caídas para la caja fuerte y el test medía 20; con la media altura promete 19 y el
## televisor y el sillón salen exactos.
func falls_to_break() -> int:
	var fall: float = maxf(PackageDamage.FALL_REFERENCE_M - size_m().y * 0.5, 0.0)
	var hit := sqrt(2.0 * 9.8 * fall)
	var per_fall := fragility * (hit - PackageDamage.IMPACT_THRESHOLD) / PackageDamage.DAMAGE_SCALE
	return ceili(1.0 / per_fall) if per_fall > 0.0 else 0


## La misma cuenta, escrita para el panel. 0 = la caída de referencia no le hace nada.
func _breaks() -> String:
	var falls := falls_to_break()
	if falls <= 0:
		return "no se rompe cayendo de %.0f m" % PackageDamage.FALL_REFERENCE_M
	return "se rompe en %d caída%s de %.0f m" % [falls, "" if falls == 1 else "s",
		PackageDamage.FALL_REFERENCE_M]


## TODOS LOS GIZMOS DE CREACIÓN de los paquetes que cuelguen de `root`: los puntos de agarre (cian) y
## de mano (amarillos), que no se escriben acá —los genera el agarrable del juego desde las celdas—, y
## la grilla de celdas sobre la caja, que es contra lo que se ajusta un bosquejo.
static func set_gizmos(root: Node, on: bool) -> void:
	for node in root.find_children("*", "GrabbableInteractable", true, false):
		(node as GrabbableInteractable).set_debug_points(on)
	for node in root.find_children(GRID_NODE, "MeshInstance3D", true, false):
		(node as MeshInstance3D).visible = on


## Cómo se dibuja el bosquejo: sólido, traslúcido —para ver los puntos que caen adentro del volumen— u
## oculto, para mirar la caja de celdas y los puntos solos.
##
## El traslúcido CAMBIA DE SHADER (ver el bloque del shader arriba): el opaco no nombra ALPHA y por eso
## no paga la cola de transparencias, que es lo que el juego usa siempre. `GeometryInstance3D
## .transparency` no servía — está atado a `BaseMaterial3D` y estas piezas tienen un ShaderMaterial.
static func set_sketch(root: Node, mode: int) -> void:
	for node in root.find_children(SKETCH_NODE, "Node3D", true, false):
		for child in node.find_children("*", "GeometryInstance3D", true, false):
			var piece := child as GeometryInstance3D
			piece.visible = mode != Sketch.HIDDEN
			var material := piece.material_override as ShaderMaterial
			if material == null:
				continue
			var ghost := mode == Sketch.TRANSLUCENT
			material.shader = shader(ghost)
			if ghost:
				material.set_shader_parameter("fade", 1.0 - SKETCH_FADE)


## CUÁNTO DAÑO SE LE VE, 0 sano y 1 destruido: el uniforme `damage` de cada pieza del bosquejo. Lo llama
## `PackageDamage` cada vez que el objeto recibe un golpe, y es toda la lectura visual del daño por
## ahora. No toca mallas ni crea materiales: escribe un número en los que ya existen.
static func set_damage(root: Node, value: float) -> void:
	for node in root.find_children(SKETCH_NODE, "Node3D", true, false):
		for child in node.find_children("*", "GeometryInstance3D", true, false):
			var material := (child as GeometryInstance3D).material_override as ShaderMaterial
			if material != null:
				material.set_shader_parameter("damage", clampf(value, 0.0, 1.0))


# ── Los bosquejos ────────────────────────────────────────────────────────────────────────────────

## EL DIBUJO de este paquete: el de su recurso (ver SupplyLook) o, si no es uno, una caja lisa de su tamaño.
func _build_sketch(parent: Node3D, size: Vector3) -> void:
	if not SupplyLook.carried(parent, key):
		Clay.box(parent, size, Vector3.ZERO, Color(0.25, 0.28, 0.27))


## El material de una pieza, de boceto o de modelo: el shader del daño con su color.
static func sketch_material(color: Color) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = shader()
	material.set_shader_parameter("tint", color)
	material.set_shader_parameter("damage", 0.0)
	material.set_shader_parameter("darkest", DARKEST)
	return material


## LA GRILLA DE CELDAS, dibujada sobre las seis caras de la caja: es contra lo que se ajusta un
## bosquejo, y es lo que hace ver de un vistazo que un objeto mide 19 celdas de largo.
##
## Va en las CARAS y no en el volumen: la retícula entera de una caja de 19 × 8 × 8 son miles de
## segmentos y no se lee ninguno. Un solo `ImmediateMesh` para las seis caras.
func _build_cell_grid(parent: Node3D, size: Vector3) -> void:
	var half := size * 0.5
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	# Por cada par de caras: el eje normal y los dos ejes que la recorren, con su conteo de celdas.
	for face in [[0, 1, 2, cells.y, cells.z], [1, 2, 0, cells.z, cells.x], [2, 0, 1, cells.x, cells.y]]:
		var n: int = face[0]
		var a: int = face[1]
		var b: int = face[2]
		for s in [-1.0, 1.0]:
			for i in int(face[3]) + 1:
				var t: float = -half[a] + size[a] * float(i) / float(face[3])
				mesh.surface_add_vertex(_at(n, s * half[n], a, t, b, -half[b]))
				mesh.surface_add_vertex(_at(n, s * half[n], a, t, b, half[b]))
			for i in int(face[4]) + 1:
				var t: float = -half[b] + size[b] * float(i) / float(face[4])
				mesh.surface_add_vertex(_at(n, s * half[n], b, t, a, -half[a]))
				mesh.surface_add_vertex(_at(n, s * half[n], b, t, a, half[a]))
	mesh.surface_end()

	var grid := MeshInstance3D.new()
	grid.name = GRID_NODE
	grid.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = GRID_COLOR
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.no_depth_test = true  # se lee aunque el bosquejo esté sólido
	grid.material_override = material
	grid.set_meta("no_outline", true)  # nunca contornear un gizmo
	# Escondida: es un gizmo de creación, y en el juego se veía a través de todo (lo encontró el playtest). La prende
	# la fila del sandbox con sus gizmos (ver `set_gizmos`).
	grid.visible = false
	parent.add_child(grid)


## Un punto con sus tres coordenadas puestas por ÍNDICE de eje, para que la grilla de las seis caras se
## escriba una vez y no seis.
static func _at(ia: int, va: float, ib: int, vb: float, ic: int, vc: float) -> Vector3:
	var out := Vector3.ZERO
	out[ia] = va
	out[ib] = vb
	out[ic] = vc
	return out
