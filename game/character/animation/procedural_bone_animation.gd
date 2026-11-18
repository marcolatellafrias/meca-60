class_name ProceduralBoneAnimator

## LA TABLA DE ANIMACIÓN PROCEDURAL: cada entrada es (qué mueve, en qué eje, qué señal o fórmula, peso, escala, curva),
## y en cada pasada todo vuelve a su reposo y se le suma lo suyo. COMÚN (18/11/2026, módulo Jefes, con aviso a
## Personajes): mueve cualquier Node3D (los huesos de un personaje, las piezas de una meca o de un jefe) y lee las
## señales de cualquier cuerpo (MotionSignals). Quién mueve qué lo dice cada cuerpo (en los personajes, animations.gd).

enum SignalType {
	STEP_PROGRESS, STEP_LENGTH, STEP_DRIVEN,
	H_VEL_X, H_VEL_Z, V_VEL,
	FOOT_SPREAD_X, FOOT_SPREAD_Z,
	LEFT_FOOT_X, LEFT_FOOT_Z,
	RIGHT_FOOT_X, RIGHT_FOOT_Z,
	FOOT_SPREAD_UNIFIED_X,
	FOOT_SPREAD_UNIFIED_Z
}
enum Axis {
	ROT_X, ROT_Y, ROT_Z, POS_Y, POS_Z
}

var is_seated:            bool       = false
var _seated_locked_bone:  Node3D = null

class BoneAnimEntry:
	var bone: Node3D
	var axis: ProceduralBoneAnimator.Axis
	var driver: Callable
	## La señal que la mueve, si es una (`register`); −1 si es una fórmula. Ver `update`.
	var signal_type: int = -1
	var weight: float
	## Una escala que se lee cada cuadro (ver WalkStyle): el estilo de caminar cambia en vivo sin registrar de nuevo.
	var scale: Callable
	var curve: Curve
	var rest_local_position: Vector3
	var rest_signal_value: float = 0.0
	var rest_local_basis: Basis

class NodeAnimEntry:
	var node: Node3D
	var direction: Vector3
	var driver: Callable
	## Como en BoneAnimEntry.
	var signal_type: int = -1
	var weight: float
	var curve: Curve
	var rest_local_position: Vector3
	var rest_signal_value: float = 0.0

var locomotion_signals: MotionSignals
var _entries: Array = []
var _node_entries: Array = []

## LO QUE ESCRIBE UNA PASADA, AGRUPADO (ver `update`): por hueso, [el hueso, la entrada de la que sale su reposo —la
## última que se registró, que era la que ganaba— y los índices de sus entradas en orden]; lo mismo por nodo. Se
## rearma cuando se registra o se saca algo.
var _groups_dirty := true
var _bone_groups: Array = []
var _node_groups: Array = []
## Por pasada: cada señal leída una vez, y lo que da cada entrada (si se aplica, y cuánto).
var _signals := PackedFloat64Array()
var _values := PackedFloat64Array()
var _applies := PackedByteArray()
var _node_values := PackedFloat64Array()

static func create(signals: MotionSignals) -> ProceduralBoneAnimator:
	var a := ProceduralBoneAnimator.new()
	a.locomotion_signals = signals
	return a

func register(bone: Node3D, axis: Axis, driver: SignalType, weight: float, curve: Curve = null,
		scale := Callable()) -> void:
	_register_internal(bone, axis, func(): return _get_signal_value(driver), weight, curve)
	(_entries.back() as BoneAnimEntry).signal_type = driver
	(_entries.back() as BoneAnimEntry).scale = scale

func register_formula(bone: Node3D, axis: Axis, formula: Callable, weight: float = 1.0, curve: Curve = null) -> void:
	_register_internal(bone, axis, formula, weight, curve)

func register_node_formula(node: Node3D, direction: Vector3, formula: Callable, weight: float = 1.0, curve: Curve = null) -> void:
	_register_node_internal(node, direction, formula, weight, curve)

func _register_internal(bone: Node3D, axis: Axis, driver_fn: Callable, weight: float, curve: Curve) -> void:
	var entry := BoneAnimEntry.new()
	entry.bone = bone
	entry.axis = axis
	entry.driver = driver_fn
	entry.weight = weight
	entry.curve = curve
	entry.rest_local_position = bone.position
	entry.rest_signal_value = driver_fn.call()
	entry.rest_local_basis = bone.transform.basis
	_entries.append(entry)
	_groups_dirty = true

func _register_node_internal(node: Node3D, direction: Vector3, driver_fn: Callable, weight: float, curve: Curve) -> void:
	var entry := NodeAnimEntry.new()
	entry.node = node
	entry.direction = direction
	entry.driver = driver_fn
	entry.weight = weight
	entry.curve = curve
	entry.rest_local_position = node.position
	entry.rest_signal_value = driver_fn.call()
	_node_entries.append(entry)
	_groups_dirty = true

## LA PASADA: cada hueso y cada nodo registrado vuelve a su reposo y se le suma lo de sus entradas.
##
## Sale la misma pose, bit a bit, que cuando se escribía entrada por entrada; lo que cambia es cuánto cuesta (el
## estudio de optimización medía la mitad del solve acá). Antes, cada entrada escribía `position.y`, `position.z` y
## la base de su hueso por separado para volver al reposo, y otra vez para aplicarse, y cada escritura propaga la
## transformada a todo lo que cuelga del hueso; y cada señal se leía por una lambda, una vez por entrada. Ahora:
## 1. las señales se leen una vez;
## 2. los valores de las entradas se calculan en el orden de registro, como antes (una fórmula puede tener estado,
##    así que se la llama las mismas veces y en el mismo orden), con el mismo salto del hueso trabado al sentarse;
## 3. cada hueso y cada nodo se arma en una variable, con sus entradas en el orden de registro y la misma aritmética,
##    y se escribe una sola vez. Juntarlos así sirve porque ninguna fórmula lee un hueso o un nodo que esta pasada
##    escribe: leen señales y la cámara.
func update() -> void:
	if _groups_dirty:
		_rebuild_groups()
	for s in _signals.size():
		_signals[s] = _get_signal_value(s as SignalType)

	for i in _entries.size():
		var entry: BoneAnimEntry = _entries[i]
		if is_seated and entry.bone == _seated_locked_bone \
				and (entry.axis == Axis.POS_Y or entry.axis == Axis.POS_Z):
			_applies[i] = 0
			continue
		var raw:    float = (_signals[entry.signal_type] if entry.signal_type >= 0 else entry.driver.call()) \
				- entry.rest_signal_value
		var shaped: float = entry.curve.sample_baked(clamp(raw, 0.0, 1.0)) if entry.curve else raw
		_values[i] = shaped * entry.weight * (float(entry.scale.call()) if entry.scale.is_valid() else 1.0)
		_applies[i] = 1
	for i in _node_entries.size():
		var entry: NodeAnimEntry = _node_entries[i]
		var raw:    float = (_signals[entry.signal_type] if entry.signal_type >= 0 else entry.driver.call()) \
				- entry.rest_signal_value
		_node_values[i] = entry.curve.sample_baked(clamp(raw, 0.0, 1.0)) if entry.curve else raw

	for group: Array in _bone_groups:
		var rest: BoneAnimEntry = group[1]
		var t: Transform3D = (group[0] as Node3D).transform
		t.origin.y = rest.rest_local_position.y
		t.origin.z = rest.rest_local_position.z
		t.basis = rest.rest_local_basis
		for i: int in group[2]:
			if _applies[i] == 0:
				continue
			var value := _values[i]
			match (_entries[i] as BoneAnimEntry).axis:
				Axis.ROT_X:
					t.basis = t.basis * Basis(Vector3.RIGHT, value)
				Axis.ROT_Y:
					t.basis = t.basis * Basis(Vector3.UP, value)
				Axis.ROT_Z:
					t.basis = t.basis * Basis(Vector3.FORWARD, value)
				Axis.POS_Y:
					t.origin.y += value
				Axis.POS_Z:
					t.origin.z += value
		(group[0] as Node3D).transform = t
	for group: Array in _node_groups:
		var p: Vector3 = (group[1] as NodeAnimEntry).rest_local_position
		for i: int in group[2]:
			var entry: NodeAnimEntry = _node_entries[i]
			# Tal cual se sumaba: la dirección por el valor y después por el peso, que redondea distinto que juntos.
			p += entry.direction * _node_values[i] * entry.weight
		(group[0] as Node3D).position = p


## Rearma los grupos de `update` y el tamaño de lo que se llena por pasada.
func _rebuild_groups() -> void:
	_groups_dirty = false
	_bone_groups = _group_by(_entries, func(e: BoneAnimEntry) -> Node3D: return e.bone)
	_node_groups = _group_by(_node_entries, func(e: NodeAnimEntry) -> Node3D: return e.node)
	_signals.resize(SignalType.size())
	_values.resize(_entries.size())
	_applies.resize(_entries.size())
	_node_values.resize(_node_entries.size())


## [el nodo, su última entrada, los índices de sus entradas], en el orden en que aparece cada nodo por primera vez.
static func _group_by(entries: Array, target_of: Callable) -> Array:
	var groups: Array = []
	var index_of := {}
	for i in entries.size():
		var target: Node3D = target_of.call(entries[i])
		if not index_of.has(target):
			index_of[target] = groups.size()
			groups.append([target, null, PackedInt32Array()])
		var group: Array = groups[index_of[target]]
		group[1] = entries[i]
		var indices: PackedInt32Array = group[2]
		indices.append(i)
		group[2] = indices  # un PackedInt32Array dentro de un Array es una copia: se vuelve a guardar
	return groups

func _get_signal_value(driver: SignalType) -> float:
	match driver:
		SignalType.STEP_PROGRESS:
			return locomotion_signals.step_progress
		SignalType.STEP_LENGTH:
			return locomotion_signals.step_length_norm
		SignalType.STEP_DRIVEN:
			return locomotion_signals.step_progress * locomotion_signals.step_length_norm
		SignalType.H_VEL_X:
			return locomotion_signals.horizontal_velocity_smooth.x
		SignalType.H_VEL_Z:
			return locomotion_signals.horizontal_velocity_smooth.y
		SignalType.V_VEL:
			return locomotion_signals.vertical_velocity()
		SignalType.FOOT_SPREAD_X:
			return locomotion_signals.foot_spread_norm.x
		SignalType.FOOT_SPREAD_Z:
			return locomotion_signals.foot_spread_norm.y
		SignalType.LEFT_FOOT_X:
			return locomotion_signals.left_foot_local_norm.x
		SignalType.LEFT_FOOT_Z:
			return locomotion_signals.left_foot_local_norm.y
		SignalType.RIGHT_FOOT_X:
			return locomotion_signals.right_foot_local_norm.x
		SignalType.RIGHT_FOOT_Z:
			return locomotion_signals.right_foot_local_norm.y
		SignalType.FOOT_SPREAD_UNIFIED_X:
			return locomotion_signals.foot_spread_unified.x
		SignalType.FOOT_SPREAD_UNIFIED_Z:
			return locomotion_signals.foot_spread_unified.y
	return 0.0

func unregister_bone(bone: Node3D) -> void:
	_entries = _entries.filter(func(e): return e.bone != bone)
	_groups_dirty = true
