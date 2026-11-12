class_name PackageArchetype
extends SeededArchetype

## UN TIPO DE OBJETO AGARRABLE —un televisor, un sillón, una caja fuerte— como arquetipo: QUÉ es (su
## tamaño en celdas y su peso) y CÓMO SE VE (un bosquejo de primitivas). De acá sale el cuerpo real del
## juego: un `RigidBody3D` con su masa, su collider cúbico y un `GrabbableInteractable` que le genera
## los puntos de agarre y de mano desde las celdas. Nada de esto es código del sandbox: la fila
## "Paquetes" y el lote de prueba de la sucursal construyen el MISMO cuerpo que va a cargar un jugador
## (ver conceptual/objects.md y technical/design-sandbox.md).
##
## ── EL TAMAÑO SE DECLARA EN CELDAS, NO EN METROS ─────────────────────────────────────────────────
## Y es la decisión que manda sobre todo lo demás: de las celdas salen los metros
## (`GrabbableInteractable.CELL_SIZE`), de las celdas sale CUÁNTOS PUNTOS DE AGARRE tiene
## (`GRAB_DENSITY`, uno cada tres celdas) y por lo tanto cuán fino es el agarre —el agarre se suelta
## cuando se va del cono el PUNTO, no el objeto entero—, y contra la caja de celdas se ajusta el
## bosquejo. Cambiarle las celdas a un paquete le cambia el tamaño, el agarre y la cantidad de puntos
## de una sola vez, que es como tiene que ser.
##
## ── EL PESO ES EL ÚNICO NÚMERO QUE SE SIENTE ─────────────────────────────────────────────────────
## La rigidez del agarre escala con la masa, así que todo objeto responde igual de rápido: lo que hace
## que el peso SE SIENTA es el techo de fuerza del agarrador (`FORCE_PER_STRENGTH`, newtons por unidad
## de `strength`), que nunca baja del peso: todo se levanta, también solo, y lo que pasa la fuerza de uno
## sube despacio y se lleva lento (ver GrabbableInteractable.LIFT_MARGIN). Por eso el panel imprime A QUÉ
## VELOCIDAD lo lleva solo cada uno en vez del kilaje pelado (ver `_lifters`).
##
## ── EL BOSQUEJO SE DISEÑA EN FRACCIONES, PERO LO REDONDO EN METROS ──────────────────────────────
## Las cajas se declaran como fracciones de la caja de celdas, así el dibujo sigue al tamaño; lo que
## tiene que ser REDONDO (la pantalla del televisor, el disco de la caja fuerte) se calcula en metros,
## porque un cilindro escalado por una caja de 2,00 × 0,84 × 0,84 sale elipse. Es la misma lección que
## los controles (ver ControlArchetype).
##
## ── Y EL RELIEVE DEL FRENTE VA ADELANTE DEL CUERPO ──────────────────────────────────────────────
## Que es la trampa de todo esto, y me la comí en dos de los tres: el collider ES la caja de celdas, así
## que nada puede asomar de ella — y entonces un detalle "sobre la cara de adelante" dibujado A la cara
## queda ADENTRO del cuerpo, invisible, si el cuerpo ocupa todo el fondo. La manivela y el disco de la
## caja fuerte, y el frente entero del televisor —aro, pantalla, perillas, chapita— nacieron así,
## enterrados en un bloque macizo. Y el test no lo vio, porque medir "no me paso de la caja" no dice
## absolutamente nada de lo que está hundido (ahora sí lo ve: ver `tests/packages.tscn`).
##
## La regla, una sola para los tres y para el que venga: el CUERPO arranca a `FRONT_RELIEF` de la cara de
## adelante, y el relieve vive en ese espacio. Así cada pieza del frente declara DÓNDE ESTÁ SU CARA y
## cuánto mide de fondo (`_front_slab`, `_disc`, `_ring`), sobresale del cuerpo, y sigue adentro del
## collider.
##
## El frente de un paquete es su −Z, igual que el frente del proyecto: es de donde se llega a la parcela.

const CELL := GrabbableInteractable.CELL_SIZE

## Cuánto más grande que el objeto es su parcela del sandbox, en metros y por eje: lo que hace falta
## para darle la vuelta al bosquejo sin salirse del marco.
const PARCEL_MARGIN := Vector2(0.9, 0.9)

## CUÁNTO DE LA CAJA SE RESERVA ADELANTE para el relieve del frente, en metros (ver el bloque de arriba).
## 3,5 cm alcanza para un aro con su vidrio hundido y para un disco con la manija por delante, y es poco
## contra el fondo de cualquier paquete — el cuerpo pierde eso y nada más.
const FRONT_RELIEF := 0.035

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


## ── La paleta de los bosquejos ───────────────────────────────────────────────────────────────────
## Nuevos Aires 1900–1920: nogal, latón, hierro y tapicería oscura. Son bosquejos, así que lo único que
## tienen que hacer los colores es separar una pieza de la de al lado.
const WALNUT     := Color(0.29, 0.18, 0.11)
const WOOD_DARK  := Color(0.18, 0.11, 0.07)
const BRASS      := Color(0.74, 0.57, 0.24)
const GLASS      := Color(0.11, 0.15, 0.14)
const UPHOLSTERY := Color(0.27, 0.35, 0.29)
const UPHOL_DARK := Color(0.18, 0.25, 0.21)
const IRON       := Color(0.25, 0.28, 0.27)
const IRON_LIGHT := Color(0.34, 0.37, 0.36)
## El barro cocido de la vasija, y el de sus franjas pintadas.
const TERRACOTTA := Color(0.62, 0.35, 0.22)
const TERRA_DARK := Color(0.40, 0.21, 0.13)
## El radio del tubo de los aros de la vasija, en metros: lo que asoman de la panza, y lo que su caja visual crece a
## los costados.
const VASE_HOOP := 0.012
## Lo de adentro de una boca, que se lee como hueco y no como tapa: casi negro.
const HOLLOW     := Color(0.07, 0.05, 0.04)

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

## EL ÁREA DE LOS MODELOS DE LOS PAQUETES: son de tamaño fijo —su caja de celdas— y se modelan en Blender
## (ver ModelBox). Mientras un paquete no tenga su `assets/models/packages/<key>.glb`, se dibuja su boceto.
const MODEL_AREA := "packages"

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
## LA CAJA VISUAL, en metros y en los ejes del objeto (ver ModelBox.visual_box): lo que se dibuja y no choca ni se
## agarra —los aros de la vasija—. Vacía, es la de celdas; la colisión, el agarre y las celdas siguen con `cells`.
var visual := AABB()


func _init(p_key := "box", p_name := "Caja", p_cells := Vector3i(4, 4, 4), p_weight := 10.0,
		p_fragility := 1.0, p_material: StringName = &"madera") -> void:
	key = p_key
	display_name = p_name
	cells = p_cells
	weight = p_weight
	fragility = p_fragility
	material = p_material


## LOS OBJETOS QUE HAY, que es también de donde sortea el lote (LoopBatch, y el de prueba de la sucursal del
## sandbox): un solo catálogo, así que un objeto nuevo aparece en todos lados sin que ninguno lo sepa.
##
## Cada uno está para ocupar una esquina distinta de los TRES EJES que hacen a un paquete —cuánto pesa,
## qué forma tiene y cuánto le duele un golpe—, no para llenar un catálogo:
##
##   · el TELEVISOR es compacto y liviano — lo lleva cualquiera, incluso el pibe — y frágil: tiene una
##     pantalla de vidrio y se rompe en dos caídas;
##   · el SILLÓN pesa parecido a lo que uno aguanta pero mide DOS METROS DE LARGO: lo difícil no es el
##     peso sino la orientación (con una sola mano el objeto queda apuntando hacia uno, ver
##     GrabbableInteractable), y es tapizado, así que los golpes casi no le hacen nada;
##   · la CAJA FUERTE es chica, no la levanta casi nadie solo —es el objeto de "vení a ayudarme"— y es lo
##     más cerca de indestructible que hay;
##   · el ARMARIO es el largo del sillón puesto PARADO: casi dos metros de alto, y lo que estorba ahí es
##     otra cosa —pasa por la puerta de frente y no de costado—, lo que lo hace la contraparte exacta del
##     sillón y no otro mueble grande;
##   · la VASIJA es el extremo del eje de la fragilidad: UNA CAÍDA y se rompió. Redonda y panzona, con la
##     panza del ancho de su caja y la boca ancha: llena su caja todo lo que puede algo redondo. Está en el
##     lugar del espejo, que salió por casi plano y por reflejar (ver conceptual/objects.md, Package standards);
##   · el HORNO es pesado y macizo sin ser el caso imposible: lo levantan tres de los seis arquetipos, que
##     es el escalón que faltaba entre "cualquiera" y "casi nadie";
##   · el CAJÓN DE BOTELLAS es el otro tipo de durabilidad: no le duelen los golpes sino lo que se le CAE.
##     Es un CONTENEDOR (ver `is_container`): su vida es cuántas botellas quedan adentro, así que lo que
##     hay que cuidar no es soltarlo sino inclinarlo;
##   · el BAÚL DE VIAJE es el paquete común, la esquina que faltaba: liviano para lo que mide, con una
##     manija en cada punta y casi indestructible. Es el que se lleva sin pensar, se puede tirar y rellena
##     el lote — hasta ahora todo lo liviano era frágil (la vasija, el televisor) o largo (el sillón).
##
## Peso y fragilidad son ejes INDEPENDIENTES, y ahí está la mitad del interés: el liviano es el que hay
## que cuidar y el pesadísimo se puede tirar por la escalera.
static func catalogue() -> Array[SeededArchetype]:
	var out: Array[SeededArchetype] = []
	out.append(PackageArchetype.new("television", "Televisor", Vector3i(6, 5, 4), 24.0, 1.0, &"vidrio"))
	out.append(PackageArchetype.new("couch", "Sillón largo", Vector3i(19, 8, 8), 42.0, 0.25, &"tela"))
	out.append(PackageArchetype.new("safe", "Caja fuerte", Vector3i(5, 5, 4), 150.0, 0.08, &"metal"))
	out.append(PackageArchetype.new("wardrobe", "Armario", Vector3i(10, 18, 6), 70.0, 0.30, &"madera"))
	# 2.0: una caída, y con margen. La caída de referencia la golpea a 7,2 m/s y con 6 ya se rompe, así que el
	# impulso que reporta el solver en el cuadro del golpe —un 3 % por debajo del m·v ideal— no la pasa a dos.
	var vase := PackageArchetype.new("vase", "Vasija", Vector3i(5, 7, 5), 18.0, 2.0, &"ceramica")
	# Los aros asoman de la panza por los costados: sólo se ven (ver `visual`).
	var vase_size := vase.size_m()
	var hoop := Vector3(VASE_HOOP, 0.0, VASE_HOOP)
	vase.visual = AABB(-vase_size * 0.5 - hoop, vase_size + hoop * 2.0)
	out.append(vase)
	out.append(PackageArchetype.new("stove", "Horno", Vector3i(8, 10, 6), 110.0, 0.12, &"metal"))
	# El cuerpo lo arma BottleCrate, el mismo que spawnea el juego (ver `build_body`); acá van sus números
	# para el panel y el lote. El peso es el cajón MÁS las botellas: son cuerpos aparte, pero apoyan en él
	# y el agarre los carga. Fragilidad 0: a este no lo rompen los golpes (ver `is_container`).
	out.append(PackageArchetype.new("crate_bottles", "Cajón de botellas", BottleCrate.CELLS,
		BottleCrate.CRATE_MASS + BottleCrate.BOTTLE_MASS * BottleCrate.COLS * BottleCrate.ROWS, 0.0, &"vidrio"))
	# 0.06: un poco más duro que la caja fuerte (26 caídas contra 20), que es lo que pidió el mapa del catálogo
	# para el común —que golpearlo no preocupe—, sin llegar a 0, que sería no tener daño.
	out.append(PackageArchetype.new("trunk", "Baúl de viaje", Vector3i(8, 5, 5), 30.0, 0.06, &"madera"))
	return out


## UN CONTENEDOR: su durabilidad no es el daño de los golpes (`PackageDamage`) sino cuántos ítems le quedan
## adentro (`PackageContents`, ver conceptual/objects.md). No tiene bosquejo propio ni `PackageDamage`: el
## cuerpo lo arma quien sabe armar ese contenedor, el mismo que usa el juego.
func is_container() -> bool:
	return key == "crate_bottles"


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
	# EL CAJÓN NO SE REESCRIBE ACÁ: lo arma BottleCrate, que es lo que spawnea el juego (NetSpawner), así
	# que la fila y los lotes muestran el mismo cajón y no una copia que se vaya separando.
	if key == "crate_bottles":
		var crate := BottleCrate.build()
		crate.name = key
		return crate

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

	# EL MODELO SI EXISTE, Y SI NO EL BOCETO: los dos van en el mismo nodo y con el mismo material, así el daño y
	# las teclas de la fila los tratan igual (ver ModelBox).
	var sketch := Node3D.new()
	sketch.name = SKETCH_NODE
	body.add_child(sketch)
	if ModelBox.load_into(sketch, MODEL_AREA, key, size, PackageArchetype.sketch_material, visual).is_empty():
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


## Su modelo de Blender (ver SeededArchetype.model_refs). El cajón de botellas tiene dos, el cajón y la botella, y
## sus cajas las escribe BottleCrate, que es quien lo arma.
func model_refs(_seed_value: int) -> Array[Dictionary]:
	if is_container():
		return [
			{"area": BottleCrate.MODEL_AREA, "key": BottleCrate.CRATE_KEY, "title": display_name,
				"write": func() -> String: return BottleCrate.write_crate_box()},
			{"area": BottleCrate.MODEL_AREA, "key": BottleCrate.BOTTLE_KEY, "title": "Botella",
				"write": func() -> String: return BottleCrate.write_bottle_box()},
		]
	return [{"area": MODEL_AREA, "key": key, "title": display_name, "write": write_box}]


## ESCRIBE LA CAJA de este paquete para modelarlo en Blender (ver ModelBox.write_box): su caja de celdas, la
## celda de la grilla y el boceto de hoy como referencia. Los puntos de agarre no van: los genera el agarrable
## desde las celdas. Devuelve dónde la escribió.
func write_box() -> String:
	var reference := Node3D.new()
	_build_sketch(reference, size_m())
	var path := ModelBox.write_box(MODEL_AREA, key, display_name, size_m(), CELL, {}, reference, visual)
	reference.free()
	return path


## La caja visual en concreto: `visual` si la tiene, y si no, la de celdas.
func visual_box() -> AABB:
	return ModelBox.visual_box(size_m(), visual)


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
	if is_container():
		out.append("durabilidad: %d botellas adentro · se pierde cada una que sale del cajón"
			% (BottleCrate.COLS * BottleCrate.ROWS))
	else:
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


# ── Teclas de la fila ────────────────────────────────────────────────────────────────────────────

## Las dos cosas que se mira de un paquete: CÓMO ESTÁ ARMADO (los gizmos) y CÓMO SE VE (el bosquejo).
## Ninguna reconstruye nada — prender esferas y cambiar una transparencia es gratis.
func category_options() -> Array[Dictionary]:
	return [
		{
			"key": KEY_K,
			"label": func() -> String:
				return "gizmos de creación: %s" % ("sí" if options.get("gizmos", GIZMOS_DEFAULT) else "no"),
			"apply": func(parcels: Array) -> void:
				options["gizmos"] = not bool(options.get("gizmos", GIZMOS_DEFAULT))
				for p: SandboxParcel in parcels:
					PackageArchetype.set_gizmos(p, options["gizmos"]),
		},
		{
			"key": KEY_M,
			"label": func() -> String:
				return "bosquejo: %s" % SKETCH_NAMES[int(options.get("bosquejo", SKETCH_DEFAULT))],
			"apply": func(parcels: Array) -> void:
				options["bosquejo"] = (int(options.get("bosquejo", SKETCH_DEFAULT)) + 1) \
					% SKETCH_NAMES.size()
				for p: SandboxParcel in parcels:
					PackageArchetype.set_sketch(p, options["bosquejo"]),
		},
	]


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

## EL BOCETO de este paquete, de primitivas: lo que se ve mientras no tenga un modelo (ver `build_body`).
func _build_sketch(parent: Node3D, size: Vector3) -> void:
	match key:
		"television": _build_television(parent, size)
		"couch":      _build_couch(parent, size)
		"safe":       _build_safe(parent, size)
		"wardrobe":   _build_wardrobe(parent, size)
		"vase":       _build_vase(parent, size)
		"stove":      _build_stove(parent, size)
		"trunk":      _build_trunk(parent, size)
		_:            _slab(parent, size, Vector3.ZERO, Vector3.ONE, IRON)


## Dónde empieza el CUERPO de un bosquejo con relieve al frente, como fracciones de la caja: devuelve
## (centro, fondo) en Z, dejando libre el `FRONT_RELIEF` de adelante. Ver el bloque de arriba.
func _body_z(size: Vector3) -> Vector2:
	var depth := (size.z - FRONT_RELIEF) / size.z
	return Vector2(0.5 - depth * 0.5, depth)


## EL TELEVISOR: un mueble de nogal sobre cuatro patas, con el aro de latón y la pantalla hundida en él,
## dos perillas que sobresalen y una chapita. La pantalla es chica contra el mueble y es correcto: un
## televisor de 1920 es casi todo gabinete.
func _build_television(parent: Node3D, size: Vector3) -> void:
	var body := _body_z(size)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(parent, size, Vector3(sx * 0.40, -0.40, body.x + sz * 0.33 * body.y),
				Vector3(0.08, 0.20, 0.08), WOOD_DARK)
	_slab(parent, size, Vector3(0.0, 0.08, body.x), Vector3(1.0, 0.76, body.y), WALNUT)
	_slab(parent, size, Vector3(0.0, 0.48, body.x), Vector3(1.0, 0.04, body.y), WOOD_DARK)

	# El relieve, cada pieza declarando dónde está SU CARA. La del frente de la caja es `face`.
	var face := -size.z * 0.5
	var screen_y := size.y * 0.12
	# EL ARO TIENE QUE CABER EN EL MUEBLE, y el borde que manda es el de arriba: el aro no puede pasar
	# la tapa. Un radio sacado de `min(ancho, alto)` sin esta cuenta se salía por arriba un centímetro.
	var ring_outer: float = minf(size.x * 0.45, size.y * 0.46 - screen_y)
	var ring_inner := ring_outer - 0.045
	_ring(parent, Vector3(0.0, screen_y, face), ring_inner, ring_outer, BRASS)
	# El vidrio, hundido en el aro: su cara va 14 mm detrás de la del aro, que es lo que lo hace leerse
	# como un marco con algo adentro y no como una tapa.
	_disc(parent, Vector3(0.0, screen_y, face + 0.014), ring_inner + 0.004, 0.022, GLASS)
	for sx in [-1.0, 1.0]:
		_disc(parent, Vector3(sx * (size.x * 0.5 - 0.055), -size.y * 0.16, face), 0.028, 0.050, BRASS)
	_front_slab(parent, size, Vector2(0.0, -0.26), Vector2(0.22, 0.05), face, 0.020, BRASS)


## EL SILLÓN LARGO: zócalo, asiento con tres almohadones, respaldo con otros tres y dos brazos. Dos
## metros de largo en una caja de 84 cm de alto y de fondo — lo que hay que mirar acá no es cuánto pesa
## sino cuánto estorba. Es el único de los tres sin relieve al frente: un sillón no tiene cara, llena la
## caja entera y nada queda enterrado.
func _build_couch(parent: Node3D, size: Vector3) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(parent, size, Vector3(sx * 0.455, -0.44, sz * 0.32),
				Vector3(0.025, 0.12, 0.14), WOOD_DARK)
	_slab(parent, size, Vector3(0.0, -0.24, 0.0), Vector3(1.0, 0.28, 1.0), UPHOL_DARK)
	_slab(parent, size, Vector3(0.0, 0.20, 0.37), Vector3(1.0, 0.60, 0.26), UPHOL_DARK)
	for sx in [-1.0, 1.0]:
		_slab(parent, size, Vector3(sx * 0.465, -0.07, 0.0), Vector3(0.07, 0.62, 1.0), UPHOL_DARK)
	for fx in [-0.30, 0.0, 0.30]:
		_slab(parent, size, Vector3(fx, -0.05, -0.10), Vector3(0.26, 0.10, 0.68), UPHOLSTERY)
		_slab(parent, size, Vector3(fx, 0.17, 0.19), Vector3(0.26, 0.42, 0.10), UPHOLSTERY)


## LA CAJA FUERTE: un bloque de hierro con la puerta HUNDIDA en un marco, el disco de latón asomando del
## marco y la manija en cruz por delante del disco. Chica y pesadísima, que es todo lo que tiene que
## comunicar.
##
## El marco se queda 8 mm detrás de la cara de la caja a propósito: es lo que deja a las bisagras, al
## disco y a la manija SOBRESALIR de algo. Hundidos a ras del marco no se ven, y es exactamente así como
## estaban.
func _build_safe(parent: Node3D, size: Vector3) -> void:
	var body := _body_z(size)
	_slab(parent, size, Vector3(0.0, 0.0, body.x), Vector3(1.0, 1.0, body.y), IRON)

	var face := -size.z * 0.5
	var rim_face := face + 0.008
	var rim_depth := FRONT_RELIEF - 0.008
	# El marco: cuatro listones que dejan el hueco de la puerta en el medio.
	for sy in [-1.0, 1.0]:
		_front_slab(parent, size, Vector2(0.0, sy * 0.465), Vector2(1.0, 0.07),
			rim_face, rim_depth, IRON)
	for sx in [-1.0, 1.0]:
		_front_slab(parent, size, Vector2(sx * 0.465, 0.0), Vector2(0.07, 0.86),
			rim_face, rim_depth, IRON)
	# La puerta, al fondo del hueco, apoyada contra el cuerpo.
	_front_slab(parent, size, Vector2.ZERO, Vector2(0.86, 0.86), face + FRONT_RELIEF - 0.010,
		0.010, IRON_LIGHT)
	for sy in [-1.0, 1.0]:
		_front_slab(parent, size, Vector2(0.455, sy * 0.33), Vector2(0.06, 0.14), face, 0.030, BRASS)

	var dial_r: float = minf(size.x, size.y) * 0.22
	_disc(parent, Vector3(0.0, 0.0, face + 0.004), dial_r, 0.030, BRASS)
	# LA MANIJA SON DOS LISTONES CRUZADOS y no cuatro rayos rotados: para una cruz de cuatro da lo
	# mismo, y dos cajas sin rotación no pueden salir torcidas. Su cara va en la de la caja, 4 mm por
	# delante del disco, que es lo que la hace una manija y no un dibujo sobre el disco.
	var reach: float = minf(size.x, size.y) * 0.42
	for bar_size in [Vector3(0.022, reach * 2.0, 0.018), Vector3(reach * 2.0, 0.022, 0.018)]:
		var bar := _box_mesh(bar_size, BRASS)
		bar.position = Vector3(0.0, 0.0, face + bar_size.z * 0.5)
		parent.add_child(bar)


## EL ARMARIO: zócalo, cuerpo, cornisa y dos puertas con sus manijas. Las puertas se hunden 14 mm para
## que las manijas sobresalgan de ELLAS y no solo del cuerpo — si estuvieran a ras de la cara de la caja,
## las manijas no tendrían de dónde salir sin asomar del collider.
func _build_wardrobe(parent: Node3D, size: Vector3) -> void:
	var body := _body_z(size)
	_slab(parent, size, Vector3(0.0, -0.47, body.x), Vector3(1.0, 0.06, body.y), WOOD_DARK)
	_slab(parent, size, Vector3(0.0, 0.0, body.x), Vector3(1.0, 0.86, body.y), WALNUT)
	_slab(parent, size, Vector3(0.0, 0.465, body.x), Vector3(1.0, 0.07, body.y), WOOD_DARK)

	var face := -size.z * 0.5
	for sx in [-1.0, 1.0]:
		# Las dos hojas, con 2 cm de junta en el medio: es lo que hace que se lean dos y no una.
		_front_slab(parent, size, Vector2(sx * 0.245, 0.0), Vector2(0.47, 0.84),
			face + 0.014, FRONT_RELIEF - 0.014, WALNUT)
		_front_slab(parent, size, Vector2(sx * 0.035, 0.0), Vector2(0.018, 0.22),
			face, 0.018, BRASS)


## LA VASIJA: de barro cocido, redonda y panzona —el pie, la panza, el hombro, un cuello corto y ancho y el labio
## enrollado—, con una franja pintada en el hombro y la boca abierta, oscura por dentro.
##
## Es una SILUETA DE REVOLUCIÓN en tramos: cada fila de `profile` es un cono truncado (`_lathe`), con el alto en
## fracciones de la caja y el radio en fracciones de su medio ancho, pero armado en metros, porque lo redondo escalado
## por la caja sale elipse. La panza toca las cuatro caras de la caja y el labio la de arriba: el estándar de que la
## forma llene su caja, en algo redondo (conceptual/objects.md, Package standards).
##
## La regla del relieve, acá, es la de los tramos apilados: cada uno ocupa su franja de alto, así que ninguno queda
## adentro de otro. Lo único que va adentro es el hueco de la boca —un disco oscuro apoyado en la punta del cuello—, y
## se ve por el agujero del labio.
func _build_vase(parent: Node3D, size: Vector3) -> void:
	var half: float = minf(size.x, size.z) * 0.5
	var bottom := -size.y * 0.5
	var lip := 0.03  # el grosor del labio, que es su alto: lo de arriba de la caja
	var neck_top := 1.0 - lip * 0.5 / size.y
	var neck := 0.64  # el radio de la punta del cuello, donde apoya el labio
	# [desde, radio, hasta, radio, color]: el alto de 0 (el piso) a 1 (el techo de la caja).
	var profile := [
		[0.000, 0.60, 0.045, 0.54, TERRA_DARK],    # el pie
		[0.045, 0.66, 0.160, 0.85, TERRACOTTA],
		[0.160, 0.85, 0.300, 0.965, TERRACOTTA],
		[0.300, 0.965, 0.420, 1.00, TERRACOTTA],   # la panza
		[0.420, 1.00, 0.560, 0.96, TERRACOTTA],
		[0.560, 0.96, 0.700, 0.84, TERRACOTTA],
		[0.700, 0.84, 0.740, 0.79, TERRA_DARK],    # la franja del hombro
		[0.740, 0.79, 0.840, 0.66, TERRACOTTA],
		[0.840, 0.66, neck_top, neck, TERRACOTTA], # el cuello
	]
	for row: Array in profile:
		_lathe(parent, bottom + float(row[0]) * size.y, float(row[1]) * half,
			bottom + float(row[2]) * size.y, float(row[3]) * half, row[4] as Color)

	# LOS AROS, en las juntas de la panza: un toro por junta, con el centro del tubo en la junta, así que asoman
	# VASE_HOOP —el de la panza, de la caja de celdas: por eso la vasija tiene caja visual—.
	for row: Array in profile.slice(2, 6):
		var ring := TorusMesh.new()
		ring.inner_radius = float(row[1]) * half - VASE_HOOP
		ring.outer_radius = float(row[1]) * half + VASE_HOOP
		ring.rings = 32
		ring.ring_segments = 8
		var hoop := _piece(ring, TERRA_DARK)
		hoop.position = Vector3(0.0, bottom + float(row[0]) * size.y, 0.0)
		parent.add_child(hoop)

	# EL LABIO, un toro con el eje vertical: el centro de su tubo sobre el borde del cuello, y su tope en el de la caja.
	var rim := TorusMesh.new()
	rim.inner_radius = neck * half - lip * 0.5
	rim.outer_radius = neck * half + lip * 0.5
	rim.rings = 32
	rim.ring_segments = 8
	var piece := _piece(rim, TERRACOTTA)
	piece.position = Vector3(0.0, size.y * 0.5 - lip * 0.5, 0.0)
	parent.add_child(piece)
	# La boca: el disco oscuro sobre la punta del cuello, con el borde metido 4 mm en el tubo del labio para que no
	# quede una rendija.
	_lathe(parent, size.y * 0.5 - lip * 0.5, rim.inner_radius + 0.004,
		size.y * 0.5 - lip * 0.5 + 0.003, rim.inner_radius + 0.004, HOLLOW)


## EL HORNO: cuatro patas, el cuerpo de hierro, la chapa de arriba con sus cuatro hornallas y la puerta
## del horno con su manija.
##
## ⚠ LAS HORNALLAS OBLIGAN A RESERVAR ARRIBA LO MISMO QUE EL FRENTE, y es la misma trampa: una hornalla
## dibujada A la cara de arriba de un cuerpo que llena todo el alto queda ADENTRO del cuerpo. Así que la
## chapa termina antes del techo de la caja y las hornallas ocupan ese último tramo. El relieve no es una
## regla del frente: es una regla de cualquier cara que tenga algo encima.
func _build_stove(parent: Node3D, size: Vector3) -> void:
	var body := _body_z(size)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(parent, size, Vector3(sx * 0.42, -0.40, body.x + sz * 0.30 * body.y),
				Vector3(0.10, 0.20, 0.12), IRON)
	_slab(parent, size, Vector3(0.0, 0.05, body.x), Vector3(1.0, 0.70, body.y), IRON)
	_slab(parent, size, Vector3(0.0, 0.4275, body.x), Vector3(1.0, 0.055, body.y), IRON_LIGHT)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_slab(parent, size, Vector3(sx * 0.23, 0.4775, body.x + sz * 0.24 * body.y),
				Vector3(0.34, 0.045, 0.40), WOOD_DARK)

	var face := -size.z * 0.5
	_front_slab(parent, size, Vector2(0.0, -0.02), Vector2(0.80, 0.44), face + 0.014,
		FRONT_RELIEF - 0.014, IRON_LIGHT)
	_front_slab(parent, size, Vector2(0.0, 0.26), Vector2(0.86, 0.045), face, 0.022, BRASS)


## EL BAÚL DE VIAJE: el cuerpo de madera, dos listones que lo rodean, los ocho esquineros, la tira de hierro
## donde cierra la tapa, el cierre al frente y una manija de cuero en cada punta.
##
## Es la misma regla del relieve, en CINCO caras y no en una: los listones, los esquineros y la tira dan la
## vuelta al baúl, así que el cuerpo deja `skin` libre arriba, abajo, adelante y atrás, y las manijas salen
## de las puntas, así que deja `side` en X. Todo se declara entre dos esquinas en metros (`_span`): son
## piezas que se tocan con la cara de la caja, y en fracciones cada una sería una cuenta.
func _build_trunk(parent: Node3D, size: Vector3) -> void:
	var h := size * 0.5
	var skin := 0.012
	var side := 0.025
	var inner := Vector3(h.x - side, h.y - skin, h.z - skin)
	_span(parent, -inner, inner, WALNUT)

	# Los listones: de la base a la tapa y de adelante atrás, sobresaliendo `skin` en las cuatro caras.
	for sx in [-1.0, 1.0]:
		var x: float = sx * h.x * 0.52
		_span(parent, Vector3(x - 0.03, -h.y, -h.z), Vector3(x + 0.03, h.y, h.z), WOOD_DARK)

	# Los esquineros: un cubo en cada esquina, contra la caja. En las puntas sobresalen `side`, como las manijas.
	var corner := 0.07
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var tip := Vector3(sx * h.x, sy * h.y, sz * h.z)
				var back := tip - Vector3(sx, sy, sz) * corner
				_span(parent, tip.min(back), tip.max(back), IRON_LIGHT)

	# La tapa es el tercio de arriba: la tira de hierro donde cierra, dando toda la vuelta. Sobresale 4 mm menos que los
	# listones y el cierre —a la misma cara, donde se cruzan titilarían— y lo mismo en las puntas: terminada a ras del
	# cuerpo, su cara y la de él titilaban.
	var lid := h.y * 0.40
	var band := Vector3(inner.x + skin - 0.004, 0.006, h.z - 0.004)
	_span(parent, Vector3(-band.x, lid - band.y, -band.z), Vector3(band.x, lid + band.y, band.z), IRON)
	# El cierre, en el medio del frente y montado sobre la tira.
	_span(parent, Vector3(-0.04, lid - 0.045, -h.z), Vector3(0.04, lid + 0.025, -inner.z + 0.004), IRON_LIGHT)

	# Las manijas: una tira de cuero en cada punta con sus dos anclajes de hierro, metidos 4 mm en el cuerpo.
	var grip := 0.06
	for sx in [-1.0, 1.0]:
		var face: float = sx * h.x
		var root: float = sx * (inner.x - 0.004)
		_span(parent, Vector3(minf(face, root), grip - 0.015, -0.08), Vector3(maxf(face, root), grip + 0.015, 0.08),
			WOOD_DARK)
		var mount: float = sx * (inner.x + 0.010)
		for sz in [-1.0, 1.0]:
			_span(parent, Vector3(minf(mount, root), grip - 0.03, sz * 0.095 - 0.015),
				Vector3(maxf(mount, root), grip + 0.03, sz * 0.095 + 0.015), IRON)


# ── Primitivas ───────────────────────────────────────────────────────────────────────────────────

## Una caja entre dos esquinas, en METROS: para las piezas que se definen por dónde tocan la caja y no por
## qué fracción ocupan de ella (ver el baúl).
func _span(parent: Node3D, from: Vector3, to: Vector3, color: Color) -> void:
	var piece := _box_mesh(to - from, color)
	piece.position = (from + to) * 0.5
	parent.add_child(piece)


## Una caja declarada en FRACCIONES de la caja de celdas: así el bosquejo sigue al tamaño del objeto y
## no se puede salir del collider, porque todas las fracciones están dentro de (−0.5, 0.5).
func _slab(parent: Node3D, size: Vector3, centre: Vector3, extent: Vector3, color: Color) -> void:
	var piece := _box_mesh(size * extent, color)
	piece.position = size * centre
	parent.add_child(piece)


## UNA PIEZA DEL RELIEVE DEL FRENTE: ancho y alto en fracciones de la caja, pero en Z declara DÓNDE ESTÁ
## SU CARA (`front`, en metros) y cuánto mide de fondo. Es la forma de que una pieza del frente no se
## entierre: la cara se mide contra la cara de la caja, no contra el centro.
func _front_slab(parent: Node3D, size: Vector3, centre: Vector2, extent: Vector2, front: float,
		depth: float, color: Color) -> void:
	var piece := _box_mesh(Vector3(size.x * extent.x, size.y * extent.y, depth), color)
	piece.position = Vector3(size.x * centre.x, size.y * centre.y, front + depth * 0.5)
	parent.add_child(piece)


## Un disco con el eje en Z, en METROS —lo redondo no se escala con la caja— y con `at.z` siendo SU CARA,
## igual que `_front_slab`.
func _disc(parent: Node3D, at: Vector3, radius: float, depth: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = depth
	mesh.radial_segments = 24
	mesh.rings = 1
	var piece := _piece(mesh, color)
	piece.position = at + Vector3(0.0, 0.0, depth * 0.5)
	piece.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	parent.add_child(piece)


## UN TRAMO DE UNA SILUETA REDONDA, con el eje vertical: un cono truncado de radio `r0` abajo, en `y0`, a `r1`
## arriba, en `y1`, todo en METROS (ver la vasija).
func _lathe(parent: Node3D, y0: float, r0: float, y1: float, r1: float, color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.bottom_radius = r0
	mesh.top_radius = r1
	mesh.height = y1 - y0
	mesh.radial_segments = 32
	mesh.rings = 1
	var piece := _piece(mesh, color)
	piece.position = Vector3(0.0, (y0 + y1) * 0.5, 0.0)
	parent.add_child(piece)


## Un aro con el eje en Z, en metros y con `at.z` siendo su cara. Es un toro y no dos cilindros porque lo
## que tiene que leerse es el marco de la pantalla, con el vidrio asomando por el agujero; su fondo es el
## grosor del tubo, o sea `outer - inner`.
func _ring(parent: Node3D, at: Vector3, inner: float, outer: float, color: Color) -> void:
	var mesh := TorusMesh.new()
	mesh.inner_radius = inner
	mesh.outer_radius = outer
	mesh.rings = 8
	mesh.ring_segments = 24
	var piece := _piece(mesh, color)
	piece.position = at + Vector3(0.0, 0.0, (outer - inner) * 0.5)
	piece.rotation = Vector3(PI * 0.5, 0.0, 0.0)
	parent.add_child(piece)


func _box_mesh(size: Vector3, color: Color) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _piece(mesh, color)


## Las piezas van CON LUZ, al contrario de los gizmos: son el objeto y no un indicador, y sin sombreado
## un block out de cajas del mismo tono es una silueta plana.
##
## Y van con el SHADER DEL DAÑO y no con un `StandardMaterial3D`, para que oscurecerlas sea escribir un
## uniforme (ver arriba). Sanas se ven exactamente igual que con el material de antes.
func _piece(mesh: Mesh, color: Color) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	piece.mesh = mesh
	piece.material_override = sketch_material(color)
	return piece


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
