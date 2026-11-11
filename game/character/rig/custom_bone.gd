class_name CustomBone
extends Node3D

## Un hueso del rig LÓGICO. Es solo un Node3D con un largo: no dibuja nada.
##
## Lo visible es el cuerpo que sigue a estos huesos (ver CharacterBodyVisual: las cápsulas o las partes
## generadas). Antes cada hueso instanciaba su propio `bone.glb` deformado por blend shapes —
## veinte mallas por personaje que hoy estarían siempre ocultas. Ver technical/character-history.md.
##
## `capsule_dimensions` sobrevive con x/z = radio, y = largo: el largo lo lee todo el sistema de
## animación, y los radios ya solo dan forma a las cápsulas de colisión del ragdoll.

var capsule_dimensions: Vector3
## Rotación de reposo GLOBAL. La provee ReferenceRig desde el modelo de Blender; `create` la convierte
## a local contra el padre. También es la referencia de torsión que usa `pose_from_rest_to`.
var rest_rotation: Vector3

## EL REPOSO EN EL QUE NACIÓ ESTE HUESO: su transform LOCAL al construirse, y su largo. La animación no
## los toca nunca.
##
## ⚠ EXISTEN PORQUE HORNEAR UNA MALLA NO PUEDE DEPENDER DE CUÁNDO SE HORNEA. El cuerpo generado se cuece
## una vez, leyendo el rig (ver ProceduralBodyUtil._mirror_bones), y leía `transform` — la pose VIVA. En el
## primer build el brazo ya venía posado por la capa de brazos (codo a −0.28 rad) y en una reconstrucción
## no (codo recto, hombro girado 177°), así que la MISMA semilla daba dos mallas distintas: 922 vértices
## contra 919, la caja del brazo de 0.31×0.73 a 0.74×0.27, y 46 caras mirando para adentro — un agujero en
## el pliegue del codo. Y como cualquier cambio del panel reconstruye, pasaba con cualquier slider.
##
## El largo va por la misma razón: `set_length` lo cambia mientras se agarra algo, así que reconstruir con
## algo en la mano horneaba un brazo estirado.
var rest_transform: Transform3D = Transform3D()
var rest_length: float = 0.0

var length: float = capsule_dimensions.y:
	get:  return capsule_dimensions.y
	set(val): capsule_dimensions.y = val


## Un hueso nace en la PUNTA de su padre (o en su base, con `use_father_end` en false). Si hay que correrlo
## de ahí —el encaje del brazo es el único caso— se le pide después con `set_world_offset`, que habla en ejes
## del mundo; correrlo nunca es girarlo, porque girar para bajar le cambia el largo por la hipotenusa y lo
## que cuelga de él hereda el giro.
static func create(new_capsule_dimensions: Vector3, new_rest_rotation: Vector3,
		father_bone: CustomBone = null, use_father_end: bool = true) -> CustomBone:
	var bone := CustomBone.new()
	bone.capsule_dimensions = new_capsule_dimensions
	bone.rest_rotation = new_rest_rotation

	if father_bone:
		bone.position = father_bone.get_end_position() if use_father_end else Vector3.ZERO
		father_bone.add_child(bone)
		# rest_rotation es global: se la baja a local contra el reposo acumulado del padre. Contra el
		# REPOSO y no contra su pose viva: un hueso que se crea mientras la cadena está animada tiene que
		# nacer igual que uno que se crea con el personaje quieto.
		var parent_rest := _accumulated_rest(father_bone)
		bone.rotation = (parent_rest.inverse() * Basis.from_euler(new_rest_rotation)).get_euler()
	else:
		bone.rotation = new_rest_rotation
	bone.rest_transform = bone.transform
	bone.rest_length = bone.length
	return bone


## ── UNA POSTURA PERSISTENTE, QUE ES POSE Y NO REPOSO ────────────────────────────────────────────
## Lo que se le aplica a la pose de este hueso TODOS LOS FRAMES, encima de lo que la animación escriba (lo
## aplica AnimationModifiers, después de que la capa procedural reescribe los huesos desde su reposo).
##
## ⚠ TIENE QUE SER POSE Y NO REPOSO, y esa es la razón de que exista. La malla se hornea contra el reposo
## congelado y el `Skin` saca sus bind poses del MISMO reposo, así que un giro metido en el reposo mueve el
## hueso y el bind juntos: el cuerpo generado no cambia ni un milímetro — medido, la postura de hombros
## movía los brazos (que son otra pieza, horneada en la punta del hombro) y dejaba el torso intacto. En la
## capa de pose, el hueso se mueve contra un bind que se queda quieto, y eso es lo que deforma.
##
## Se guarda en el marco del PADRE (ver `set_world_posture`), que es donde vive la pose local del hueso.
var posture := Basis.IDENTITY


## Pide una postura dada en EJES DEL MUNDO y la guarda como corresponde al marco del padre. Es la misma
## conjugación que hace `create` para bajar un reposo global a local: `padre⁻¹ · R · padre`.
func set_world_posture(rotation: Basis) -> void:
	var parent := get_parent() as CustomBone
	if parent == null:
		posture = rotation
		return
	var parent_rest := _accumulated_rest(parent)
	posture = parent_rest.inverse() * rotation * parent_rest


## Pide un CORRIMIENTO dado en EJES DEL MUNDO y lo guarda en el marco del padre, que es donde vive la
## posición local del hueso. Es la misma conjugación que `set_world_posture`, pero para un vector.
##
## Existe para el encaje del brazo: "más abajo y más al frente" es una idea del MUNDO, y el hueso del que
## cuelga —el hombro— apunta de costado, así que su marco local tiene los ejes cambiados y espejados entre
## lados. Escrito a mano, el mismo número movía un brazo para abajo y el otro para atrás.
func set_world_offset(offset: Vector3) -> void:
	if offset.is_zero_approx():
		return
	var parent := get_parent() as CustomBone
	position += (_accumulated_rest(parent).inverse() * offset) if parent != null else offset
	rest_transform = transform


## Pide una postura dada en el EJE DEL PROPIO HUESO —doblar hacia adelante algo que apunta hacia arriba, como
## el pecho— y la guarda en el marco del padre, que es donde vive la pose local.
##
## Es la misma operación que el `pitch` del reposo (ver CustomBonesUtil._bone): post-multiplicar sobre la
## base del hueso en vez de pre-multiplicar sobre un eje del mundo. Expresada como pre-multiplicación, es
## `reposo · R · reposo⁻¹`.
func set_local_posture(rotation: Basis) -> void:
	var rest_basis := rest_transform.basis
	posture = rest_basis * rotation * rest_basis.inverse()


## QUE ESTE HUESO SE QUEDE MIRANDO A DONDE MIRABA, sin importar lo que sus padres tengan de postura. Se le
## pide una vez, al armar el rig, y se aplica como pose igual que cualquier otra (ver `posture`).
##
## Para qué: la CABEZA. La curva de la espalda es postura de pose en el pecho y en la lumbar, y la pose SÍ
## se hereda —es la jerarquía de nodos—, así que un personaje con la espalda curvada miraba al piso. El
## encorvado de cuello nunca tuvo el problema porque ahí la inclinación va en el REPOSO y el reposo de cada
## hueso es global: el cuello se tumba y la cabeza no hereda nada.
##
## ── LA CUENTA, QUE SALE DE UNA IGUALDAD Y NO DE UN SIGNO ADIVINADO ──────────────────────────────
## El aplicador por frame deja cada hueso en `postura · reposo`, así que lo que el mundo ve en este hueso es
## `A · P · R`, con `A` el acumulado VIVO de sus padres. Se quiere que eso valga lo mismo que el acumulado
## de REPOSO por el reposo propio, `A₀ · R`. Despejando: `P = A⁻¹ · A₀`. Nada de deducir el eje ni el signo
## de cada padre — dos cosas que en este rig vienen espejadas y con un yaw de 180° encima.
func keep_rest_facing() -> void:
	var parent := get_parent() as CustomBone
	if parent == null:
		return
	posture = _accumulated_posed(parent).inverse() * _accumulated_rest(parent)


func get_end_position() -> Vector3:
	return Vector3(0, capsule_dimensions.y, 0)


func set_length(new_y: float) -> void:
	capsule_dimensions.y = new_y


## Base que apunta el eje de reposo del hueso a lo largo de `dir`, resolviendo la torsión con `pole`.
## Es la primitiva que usa la IK.
##
## OJO con la degeneración: si `dir` viene de una cadena a extensión total, el codo/rodilla queda
## colineal, `pole` cae casi paralelo a `dir` y la torsión sale arbitraria. Por eso los targets de
## reposo se clampean (SkeletonSizesUtil.ARM_REST_EXTENSION).
func pose_from_rest_to(dir: Vector3, pole: Vector3) -> Basis:
	var rest_basis := Basis.from_euler(rest_rotation)
	var y := dir.normalized()
	var rest_y := rest_basis.y.normalized()
	var c := clampf(rest_y.dot(y), -1.0, 1.0)
	var align := Basis()
	if c > 0.999999:
		align = Basis()
	elif c < -0.999999:
		var axis := rest_y.cross(Vector3.RIGHT)
		if axis.length_squared() < 0.0001:
			axis = rest_y.cross(Vector3.UP)
		align = Basis(axis.normalized(), PI)
	else:
		align = Basis(rest_y.cross(y).normalized(), acos(c))

	var projected_pole := (pole - y * pole.dot(y)).normalized()
	if projected_pole.length() < 1e-6:
		projected_pole = IkUtil.get_orthogonal(y).normalized()
	var ref_axis := (align * rest_basis).z.normalized()
	var twist := Basis(y, atan2(ref_axis.cross(projected_pole).dot(y), ref_axis.dot(projected_pole)))
	return twist * align * rest_basis


## El acumulado VIVO de un hueso: como `_accumulated_rest`, pero contando la postura de cada uno, que es lo
## que el aplicador por frame le pone encima del reposo (ver `posture`).
static func _accumulated_posed(bone: CustomBone) -> Basis:
	var accumulated := bone.posture * bone.rest_transform.basis
	var current := bone.get_parent()
	while current != null and current is CustomBone:
		var up := current as CustomBone
		accumulated = (up.posture * up.rest_transform.basis) * accumulated
		current = up.get_parent()
	return accumulated


## El reposo acumulado de un hueso: el suyo por el de todos sus padres. Ver `rest_transform`.
static func _accumulated_rest(bone: CustomBone) -> Basis:
	var accumulated := bone.rest_transform.basis
	var current := bone.get_parent()
	while current != null and current is CustomBone:
		accumulated = (current as CustomBone).rest_transform.basis * accumulated
		current = current.get_parent()
	return accumulated


static func _get_accumulated_rotation(bone: CustomBone) -> Basis:
	var accumulated := Basis.from_euler(bone.rotation)
	var current := bone.get_parent()
	while current != null and current is CustomBone:
		accumulated = Basis.from_euler(current.rotation) * accumulated
		current = current.get_parent()
	return accumulated
