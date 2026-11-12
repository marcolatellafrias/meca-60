class_name ParticleArchetype
extends SeededArchetype

## UN SISTEMA DE PARTÍCULAS (ver ParticleSystems) andando en su parcela del design sandbox: una boquilla sobre un
## poste, a la altura de la cara, tirando hacia la derecha —de costado para el que lo mira, que es como se juzga
## una estela—. Los sistemas que son un evento y no un chorro (el destello, las chispas) se disparan solos cada
## `BURST_PERIOD`, para poder mirarlos muchas veces sin tocar nada. La semilla no cambia nada todavía.
##
## La fila tiene una tecla (`M`) que cambia la malla de todos los sistemas entre las tres estándar (línea, esfera,
## cuadrado): el mismo sistema con las tres, para comparar.

const STAND_HEIGHT := 1.2
const STAND_COLOR := Color(0.32, 0.33, 0.36)
## Hacia dónde tira en el sandbox: a la derecha del que mira (el sandbox mira hacia −Z).
const AIM := Vector3.RIGHT
## Cada cuánto se repite un sistema de ráfaga en el sandbox.
const BURST_PERIOD := 2.5

## Qué sistema es: una entrada de `ParticleSystems.catalogue`.
var system: Dictionary = {}


func _init(p_system: Dictionary = {}) -> void:
	system = p_system
	display_name = str(system.get("name", "sistema"))


## Uno por sistema del juego: agregar un sistema a `ParticleSystems.catalogue` lo pone en la fila.
static func catalogue() -> Array[ParticleArchetype]:
	var out: Array[ParticleArchetype] = []
	for entry in ParticleSystems.catalogue():
		out.append(ParticleArchetype.new(entry))
	return out


func max_footprint() -> Vector2:
	return Vector2(2.0, 2.0)


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "ParticleStand"
	parent.add_child(root)
	_post(root)
	var emitter := _make()
	# La boquilla y el emisor miran adonde tira el sistema: éste emite hacia su −Z (ver ParticleSystems).
	emitter.transform = Transform3D(Basis.looking_at(-AIM), Vector3(0.0, STAND_HEIGHT, 0.0))
	root.add_child(emitter)
	if emitter.one_shot:
		var timer := Timer.new()
		timer.wait_time = BURST_PERIOD
		timer.autostart = true
		timer.timeout.connect(emitter.restart)
		root.add_child(timer)
	emitter.emitting = true
	return root


func describe(_seed_value: int) -> PackedStringArray:
	var emitter := _make()
	var process := emitter.process_material as ParticleProcessMaterial
	var lines := PackedStringArray([
		"malla %s · %d partículas%s, %.1f s cada una" % [ParticleMeshes.NAMES[_kind()], emitter.amount,
			" de una vez, cada %.1f s" % BURST_PERIOD if emitter.one_shot else " vivas", emitter.lifetime],
		"tamaño %.2f–%.2f m al salir%s" % [process.scale_min, process.scale_max, _growth(process)],
		"color: un tono al azar por partícula" if process.color_initial_ramp != null else "color: cambia con la edad",
		"M cambia la malla de la fila; la semilla no cambia nada todavía"])
	emitter.free()
	return lines


## Qué le pasa al tamaño con la edad, leído de la curva del sistema.
func _growth(process: ParticleProcessMaterial) -> String:
	var texture := process.scale_curve as CurveTexture
	if texture == null or texture.curve == null:
		return ""
	var start := texture.curve.sample(0.0)
	var end := texture.curve.sample(1.0)
	if end > start * 1.05:
		return ", y crece ×%.1f con la edad" % (end / maxf(start, 0.001))
	return ", se infla y se desinfla"


func category_options() -> Array[Dictionary]:
	return [{"key": KEY_M, "label": _mesh_label, "apply": _cycle_mesh}]


## Con qué malla se está dibujando: la del sistema, o la que eligió la fila.
func _kind() -> ParticleMeshes.Kind:
	var kind: int = options.get("particle_mesh", system.get("kind", ParticleMeshes.Kind.SPHERE))
	return kind as ParticleMeshes.Kind


func _make() -> GPUParticles3D:
	var make: Callable = system.get("make", Callable())
	return make.call(_kind(), 1.0) if make.is_valid() else ParticleSystems.thruster_smoke(_kind())


func _mesh_label() -> String:
	return "malla: %s" % ParticleMeshes.NAMES[_kind()]


## La siguiente de las tres mallas, para toda la fila.
func _cycle_mesh(parcels: Array) -> void:
	var kinds: Array = ParticleMeshes.Kind.values()
	options["particle_mesh"] = kinds[(kinds.find(_kind()) + 1) % kinds.size()]
	for parcel in parcels:
		var p := parcel as SandboxParcel
		p.regenerate(p.seed_value, false)


## El poste con su boquilla, para que la estela tenga de dónde salir y con qué compararse.
func _post(root: Node3D) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = STAND_COLOR
	var post := MeshInstance3D.new()
	var shaft := CylinderMesh.new()
	shaft.top_radius = 0.05
	shaft.bottom_radius = 0.07
	shaft.height = STAND_HEIGHT
	post.mesh = shaft
	post.material_override = material
	post.position = Vector3(0.0, STAND_HEIGHT * 0.5, 0.0)
	root.add_child(post)

	var mouth := MeshInstance3D.new()
	var nozzle := CylinderMesh.new()
	nozzle.top_radius = 0.12
	nozzle.bottom_radius = 0.16
	nozzle.height = 0.3
	mouth.mesh = nozzle
	mouth.material_override = material
	# Acostada, apuntando adonde tira el sistema.
	mouth.transform = Transform3D(Basis.looking_at(AIM) * Basis(Vector3.RIGHT, PI * 0.5),
		Vector3(0.0, STAND_HEIGHT, 0.0) - AIM * 0.15)
	root.add_child(mouth)
