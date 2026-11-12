class_name CustomBonesUtil

var lower_spine : CustomBone
var higher_spine : CustomBone
var chest : CustomBone
var left_hip : CustomBone
var right_hip : CustomBone
var left_higher_leg : CustomBone
var left_lower_leg : CustomBone
var right_higher_leg : CustomBone
var right_lower_leg : CustomBone
var right_foot : CustomBone
var left_foot : CustomBone
var neck : CustomBone
var head : CustomBone

## LOS HUESOS QUE LLEVAN UNA POSTURA PERSISTENTE (ver CustomBone.posture). Se arma una vez acá y la lee el
## aplicador por frame: recorrer los veintiún huesos preguntando sería trabajo de cada frame para encontrar
## siempre los mismos dos.
var postured: Array[CustomBone] = []
## Lo que el hueso de la cabeza arranca adentro de ella (ver SkeletonSizesUtil.head_drop): media cabeza es su medio
## más la mitad de esto (ver `rest_eye_above_pelvis`).
var head_drop := 0.0
var left_shoulder : CustomBone
var right_shoulder : CustomBone
var right_upper_arm : CustomBone
var right_lower_arm : CustomBone
var left_upper_arm : CustomBone
var left_lower_arm : CustomBone

## Todos los huesos, para lo que necesite recorrerlos enteros (visibilidad, debug). `neck` puede ser
## null si el arquetipo no tiene cuello, así que el que la use tiene que chequear validez.
func get_all_bones() -> Array[CustomBone]:
	return [
		lower_spine, higher_spine, chest,
		left_hip, right_hip,
		left_higher_leg, left_lower_leg, right_higher_leg, right_lower_leg,
		left_foot, right_foot,
		left_shoulder, right_shoulder,
		left_upper_arm, left_lower_arm, right_upper_arm, right_lower_arm,
		neck, head,
	]

## Arma la jerarquía. Las ROTACIONES DE REPOSO salen del modelo de Blender (ReferenceRig), no de
## convenciones hardcodeadas: antes había cinco helpers (`createFromToUp/Down/Left/Right/Forward`) que
## aproximaban a mano lo que el modelo ya dice exacto, y esa diferencia era la que hacía que el
## personaje se viera distinto en Blender y en el juego.
##
## Lo único que se le suma encima es la POSTURA del arquetipo — hoy solo `slouch`, y como offset
## relativo a lo que dice el modelo. Con `slouch = 0` el reposo es exactamente el esculpido.
static func create(sizes: SkeletonSizesUtil, inst: EntityInstantiation) -> CustomBonesUtil:
	var u := CustomBonesUtil.new()
	var stats := inst.arch_final

	# ── LA LUMBAR NACE EN EL NUDO DE LA CADERA, NO ARRIBA DE LA PELVIS ──────────────────────────
	# Es la base de todo el cuerpo: las caderas cuelgan de ACÁ, y de la lumbar para arriba va el torso. Mide
	# su parte del torso MÁS el alto del filete de la pelvis (ver SkeletonSizesUtil.pelvis_fall), así que su
	# base cae justo donde la malla arranca las piernas y las caderas pueden salir HORIZONTALES.
	#
	# Antes la base estaba en el nudo de la cadera del TRONCO y el hueso de la cadera se giraba hacia abajo
	# para llegar al filete. Costaba dos cosas: el largo del hueso pasaba a ser la hipotenusa, y —lo grave—
	# el pivote de la pelvis quedaba 5,8 cm ARRIBA del nacimiento del muslo, así que la pierna nunca podía
	# estirarse lo que el arquetipo pedía: con flexión 0 la rodilla medía 41,7° en vez de 12°.
	#
	# Y NO LLEVA SLOUCH: el encorvado es solo el cuello (ver abajo). Lo que sí puede llevar es la CURVA DE
	# LA ESPALDA, que es otra variable y va como postura de pose — ver más abajo, con el pecho.
	u.lower_spine  = _bone("lower_spine", sizes.lower_spine_size, null, true)
	# LA COLUMNA SON TRES HUESOS. Era cuatro; `middle.spine` se disolvió en Blender cuando el modelo
	# pasó a low poly — con esa densidad de malla, cuatro articulaciones de torso no tenían geometría
	# suficiente para deformar y solo agregaban costo.
	#
	# NINGUNA DE LAS TRES LLEVA SLOUCH EN EL REPOSO, y es el cambio de criterio: el encorvado pasó a ser un
	# efecto de CUELLO y nada más (ver SkeletonSizesUtil.slouchiness_neck).
	u.higher_spine = _bone("higher_spine", sizes.higher_spine_size, u.lower_spine, true)
	u.chest        = _bone("chest", sizes.chest_size, u.higher_spine, true)
	# LA CURVA DE LA ESPALDA, en cambio, va como POSTURA DE POSE: el pecho adelante y la lumbar atrás de
	# contrapeso (ver SkeletonSizesUtil.spine_bend_chest). En el reposo movería el hueso y su bind juntos y
	# no deformaría nada — en la pose, el torso se curva de verdad.
	#
	# Se pide en el eje del PROPIO hueso, que es lo anatómicamente correcto para doblar algo que apunta
	# hacia arriba, y es la misma operación que hacía el `pitch` del reposo.
	if not is_zero_approx(sizes.spine_bend_chest):
		u.chest.set_local_posture(Basis(Vector3.RIGHT, -sizes.spine_bend_chest))
	if not is_zero_approx(sizes.spine_bend_lower):
		u.lower_spine.set_local_posture(Basis(Vector3.RIGHT, sizes.spine_bend_lower))

	# Las caderas cuelgan de la BASE del lower_spine (use_parent_end = false) y SALEN DERECHO DE COSTADO: su
	# punta es donde nace el muslo, y esa base ya está a la altura donde la malla arranca la pierna (ver
	# arriba). Horizontal, el largo del hueso ES la estancia — sin hipotenusa que compensar.
	u.left_hip  = _bone("left_hip", sizes.hip_size, u.lower_spine, false)
	u.right_hip = _bone("right_hip", sizes.hip_size, u.lower_spine, false)

	u.left_higher_leg  = _bone("left_higher_leg", sizes.higher_leg_size, u.left_hip,         true)
	u.left_lower_leg   = _bone("left_lower_leg", sizes.lower_leg_size, u.left_higher_leg,  true)
	u.left_foot        = _bone("left_foot", sizes.foot_size, u.left_lower_leg,   true)
	u.right_higher_leg = _bone("right_higher_leg", sizes.higher_leg_size, u.right_hip,        true)
	u.right_lower_leg  = _bone("right_lower_leg", sizes.lower_leg_size, u.right_higher_leg, true)
	u.right_foot       = _bone("right_foot", sizes.foot_size, u.right_lower_leg,  true)

	# ── EL CUELLO NACE EN LA PUNTA DEL PECHO, Y LO ÚNICO SUYO ES EL LARGO Y LA INCLINACIÓN ──────
	# La punta del pecho es UN SOLO PUNTO del que salen dos cosas: el cuello y los dos hombros. Nada se
	# corre de ahí — eso es lo que hace que el esqueleto se lea.
	#
	# Y las dos perillas del cuello hacen exactamente dos cosas, cada una una sola:
	#
	#   · CUÁNTO SOBRESALE es su LARGO (ver SkeletonSizesUtil.neck_size): "metido en el torso" es un cuello
	#     corto, no un cuello corrido para abajo. Antes era un offset, y el hueso nacía adentro del pecho
	#     — en la vista de esqueleto se veía salir de la mitad del pecho y no de su punta.
	#   · CUÁNTO SE INCLINA es el encorvado, y es un giro suyo y de nadie más (el pecho y la lumbar tienen
	#     su propia variable, ver `spine_bend`). Con el cuello corto, inclinarlo solo a él ya lee como
	#     hombros encogidos y cabeza adelantada: el encorvado de dibujito, con un hueso.
	if stats.has_neck:
		# NACE EN LA PUNTA DEL PECHO Y LLEGA A LA CABEZA (22/10/2026, lo pidió el dios del juego: los huesos nunca se
		# desconectan). La cabeza sigue donde estaba —en la tapa (`neck_anchor`, ver SkeletonSizesUtil) y de ahí su largo,
		# inclinado por el encorvado—, y el cuello va derecho desde la punta del pecho hasta ahí (ver `_neck`). Nacía en la
		# tapa, corrido de la punta del pecho, y en la vista de esqueleto quedaba un hueco.
		u.neck = _neck(sizes, u.chest)
	u.head = _bone("head", sizes.head_size, u.neck if u.neck else u.chest, true)
	u.head_drop = sizes.head_drop
	# ── LA CABEZA SE QUEDA MIRANDO AL FRENTE ────────────────────────────────────────────────────
	# La curva de la espalda es pose, y la pose se hereda: sin esto, curvar la espalda le hacía mirar el
	# piso. Un personaje encorvado no hace eso — levanta la cabeza, que es justo lo que lee como encorvado.
	# Se cancela lo que HEREDA y no se la endereza a mano (ver CustomBone.keep_rest_facing), así que esto
	# sigue valiendo si mañana otro hueso de la columna lleva postura.
	#
	# Y es la POSE de reposo, no un tope: encima se le siguen componiendo el seguimiento de cámara y la
	# respiración, que son los que la mueven de verdad (ver Animations).
	u.head.keep_rest_facing()

	# Postura de hombro: adelantado y caído, cada uno con su knob de arquetipo — NO salen del slouch,
	# porque un hombro caído sirve igual para un tímido o para alguien cargando peso.
	# Dos cosas sobre los signos, las dos contraintuitivas:
	#
	# 1. Se ESPEJAN entre lados. Un mismo giro sobre la vertical lleva un hombro adelante y el otro
	#    atrás, porque apuntan a lados opuestos. Con signos opuestos los dos van al frente y el torso
	#    no queda rotado.
	# 2. El izquierdo lleva el signo NEGATIVO. En el .glb apunta a +X, pero el modelo está autorado
	#    mirando +Z y `ReferenceRig.MODEL_FORWARD_YAW` le mete 180° para llevarlo a la convención del
	#    proyecto (−Z al frente). Ese giro invierte X, así que en el rig lógico el hombro izquierdo
	#    apunta a −X. Con el signo "obvio" los hombros se van para atrás.
	# ── EL HOMBRO NACE EN LA PUNTA DEL PECHO Y SALE PERPENDICULAR ───────────────────────────────
	# Sin corrimiento y sin giro: la punta del pecho es el punto del que salen el cuello y los dos hombros,
	# y el hombro sale derecho de costado, así que su largo ES la envergadura que se pidió.
	#
	# EL ENCAJE DEL BRAZO NO VA ACÁ, va en el brazo (ver más abajo): corriendo el hombro, la punta del pecho
	# y el nacimiento del brazo dejaban de ser el mismo punto y el esqueleto se volvía ilegible.
	#
	# Y LA POSTURA (`shoulder_forward`, `shoulder_drop`) tampoco va en el reposo: es pose, porque tiene que
	# DEFORMAR el torso (ver CustomBone.set_world_posture). En el reposo movía el hueso y su bind juntos, o
	# sea movía los brazos y dejaba el torso intacto.
	u.left_shoulder   = _shoulder("left_shoulder", true, sizes, u.chest)
	u.right_shoulder  = _shoulder("right_shoulder", false, sizes, u.chest)
	# Los dos giros van ESPEJADOS entre lados (ver la nota de arriba: un mismo giro sobre la vertical lleva
	# un hombro adelante y el otro atrás) y el izquierdo lleva el signo invertido.
	u.left_shoulder.set_world_posture(shoulder_posture(true, sizes))
	u.right_shoulder.set_world_posture(shoulder_posture(false, sizes))
	# LOS QUE LLEVAN POSTURA, para que el aplicador por frame no tenga que buscarlos. La lumbar y el pecho
	# entran solo si su curva no es cero: una postura identidad es trabajo por frame para no mover nada.
	u.postured = [u.left_shoulder, u.right_shoulder] as Array[CustomBone]
	for bone: CustomBone in [u.lower_spine, u.chest, u.head]:
		if not bone.posture.is_equal_approx(Basis.IDENTITY):
			u.postured.append(bone)
	u.left_upper_arm  = _bone("left_upper_arm", sizes.upper_arm_size, u.left_shoulder,   true)
	u.left_lower_arm  = _bone("left_lower_arm", sizes.lower_arm_size, u.left_upper_arm,  true)
	u.right_upper_arm = _bone("right_upper_arm", sizes.upper_arm_size, u.right_shoulder,  true)
	u.right_lower_arm = _bone("right_lower_arm", sizes.lower_arm_size, u.right_upper_arm, true)
	# ── LOS HUESOS NUNCA SE DESCONECTAN ────────────────────────────────────────────────────────────
	# El brazo nace en la punta del hombro, siempre, y la punta del hombro es donde el brazo cuelga: el ENCAJE del brazo
	# (`arm_sink`, `arm_push`, ver TorsoShape) inclina y alarga el hombro (ver `_shoulder`). *Corría el hueso del brazo
	# fuera de la punta del hombro y el esqueleto se veía cortado (12/10/2026: «nunca quise que los huesos se
	# desconecten»); después corría sólo la malla, y el esqueleto quedaba afuera del cuerpo (22/10/2026).*

	return u

## CONGELA EL REPOSO DEL PERSONAJE: lo que el rig tenga puesto AHORA pasa a ser su reposo.
##
## Se construye en la pose del MODELO —los brazos en T, que es como está el rig en Blender— y después se lo
## lleva a la pose en la que este personaje se para: los brazos abajo, donde sus tamaños dicen (ver
## BoneInstantiator.initialize_skeleton). Esa segunda es la que vale como reposo, y es la que se congela.
##
## ⚠ Y HAY QUE CONGELARLA porque el cuerpo generado se HORNEA una vez leyendo el rig
## (ProceduralBodyUtil._mirror_bones): si leyera la pose viva, la misma semilla daría mallas distintas
## según qué estaba haciendo el personaje al reconstruirse — medido, el brazo pasaba de 922 vértices a 919,
## su caja de 0.31×0.73 a 0.74×0.27 y aparecían 46 caras mirando para adentro, o sea un agujero en el
## pliegue del codo. Y como cualquier cambio del panel de diseño reconstruye, pasaba con cualquier slider.
func freeze_rest() -> void:
	for bone in get_all_bones():
		if is_instance_valid(bone):
			bone.rest_transform = bone.transform
			bone.rest_length = bone.length


## Altura, EN REPOSO, del origen del rayo de interacción sobre la base del `lower_spine`: la columna
## hasta la base de la cabeza, más media cabeza, que es donde PlayerController pone la cámara. Sale de
## las rotaciones de reposo (globales, ver CustomBone.rest_rotation) y no de las animadas: no tiembla
## con la respiración ni con un agarre. La usa SeatInteractable para acomodar la silla a cada uno.
func rest_eye_above_pelvis() -> float:
	var y := 0.0
	for bone: CustomBone in [lower_spine, higher_spine, chest, neck]:
		if bone != null:
			y += (Basis.from_euler(bone.rest_rotation).y * bone.length).y
	return y + head.length * 0.5 + head_drop * 0.5

## LA MISMA ALTURA, CON LA POSTURA DE CADA UNO (el encorvado del viejo, el cuello adelante): la cadena de la columna a la
## cabeza tal como queda en reposo —cada hueso, su reposo con su postura encima (ver CustomBone.posture)—, en los ejes de
## la base de la columna. La usa la cámara (ver PlayerController, LA CÁMARA), que así no lee ninguna inclinación.
func posed_rest_eye_above_pelvis() -> float:
	var xf := Transform3D(lower_spine.posture * lower_spine.rest_transform.basis, Vector3.ZERO)
	for bone: CustomBone in [higher_spine, chest, neck, head]:
		if bone != null:
			xf = xf * Transform3D(bone.posture * bone.rest_transform.basis, bone.rest_transform.origin)
	return xf.origin.y + head.length * 0.5 + head_drop * 0.5


## LA POSTURA DE UN HOMBRO, EN EJES DEL MUNDO: `forward` barre sobre la vertical y `drop` sobre el eje
## frontal, en ese orden (el drop queda afuera). Vive acá y no en dos lugares porque la usan dos: el rig,
## para pedírsela al hueso como pose, y `SkeletonSizesUtil`, para girar con ella los targets de reposo del
## brazo — si no coincidieran, la IK tiraría la mano a un punto que el hombro ya no mira.
static func shoulder_posture(left: bool, sizes: SkeletonSizesUtil) -> Basis:
	var mirror := -1.0 if left else 1.0
	return Basis(Vector3.BACK, mirror * sizes.shoulder_drop) \
		* Basis(Vector3.UP, mirror * sizes.shoulder_forward)


## `pitch` es la inclinación de autoría del hueso, aplicada como rotación LOCAL sobre la base del modelo (no
## sumada al euler): así se dobla sobre el eje propio de la articulación, que es lo anatómicamente correcto y
## lo que hace que sea un offset relativo y no un valor absoluto. Sirve para inclinar hacia adelante algo que
## apunta hacia arriba — hoy el único que lo usa es el cuello, con el encorvado.
##
## Y es lo ÚNICO que se le puede pedir al reposo acá. Lo que un hueso tenga de postura va como pose (ver
## `shoulder_posture` y CustomBone.set_world_posture) porque tiene que deformar, y lo que tenga de
## corrimiento se le pide en ejes del mundo (ver CustomBone.set_world_offset).
## EL HUESO DEL CUELLO, de la punta del pecho hasta donde nace la cabeza: el punto de la tapa (`neck_anchor`) más su
## largo inclinado por el encorvado. El del modelo, girado para apuntar ahí y con ese largo.
static func _neck(sizes: SkeletonSizesUtil, parent: CustomBone) -> CustomBone:
	var basis := rest_basis("neck")
	basis = basis * Basis(Vector3.RIGHT, -sizes.slouchiness_neck)
	var along := basis.y.normalized()
	var reach: Vector3 = sizes.neck_anchor + along * sizes.neck_size.y
	if reach.length() > 1e-5 and along.cross(reach.normalized()).length() > 1e-6:
		basis = Basis(Quaternion(along, reach.normalized())) * basis
	var dims := sizes.neck_size
	dims.y = maxf(reach.length(), 0.001)
	var bone := CustomBone.create(dims, basis.get_euler(), parent, true)
	bone.name = "neck"
	return bone


## EL HUESO DEL HOMBRO, del tope del pecho hasta donde cuelga el brazo (ver SkeletonSizesUtil._shoulder_arm_local): el
## del modelo, girado para apuntar ahí y con ese largo.
static func _shoulder(field: String, left: bool, sizes: SkeletonSizesUtil,
		parent: CustomBone) -> CustomBone:
	var basis := rest_basis(field)
	var reach := SkeletonSizesUtil._shoulder_arm_local(left, sizes)
	var along := basis.y.normalized()
	if reach.length() > 1e-5 and along.cross(reach.normalized()).length() > 1e-6:
		basis = Basis(Quaternion(along, reach.normalized())) * basis
	var dims := sizes.shoulder_width
	dims.y = reach.length()
	var bone := CustomBone.create(dims, basis.get_euler(), parent, true)
	bone.name = field
	return bone


static func _bone(field: String, dims: Vector3,
		parent: CustomBone = null, use_parent_end: bool = true, pitch: float = 0.0) -> CustomBone:
	var basis := rest_basis(field)
	if not is_zero_approx(pitch):
		basis = basis * Basis(Vector3.RIGHT, pitch)
	var bone := CustomBone.create(dims, basis.get_euler(), parent, use_parent_end)
	# EL HUESO SE LLAMA COMO SU CAMPO, y hasta ahora no se llamaba de ninguna manera: un `CustomBone` es un
	# Node3D y Godot le ponía `@Node3D@54`. El nombre no lo usa el rig —acá se habla por campo— pero sí todo
	# lo que MUESTRA un hueso, y ahí un número autogenerado no dice nada (la vista de esqueleto imprimía
	# justamente eso al lado de cada línea).
	bone.name = field
	return bone


## ── EL REPOSO DE CADA HUESO, en ejes del personaje (−Z al frente) ───────────────────────────────────────────────────
## La columna, el cuello y la cabeza, derechos para arriba; los hombros, los brazos y las caderas, acostados hacia su
## lado (el izquierdo hacia −X); las piernas, para abajo con un grado de inclinación; el pie, hacia adelante. Son los
## ángulos de Euler que antes se leían del modelo de Blender (`ReferenceRig`, `character.glb`), copiados el 13/11/2026
## al borrarlo: con ellos el esqueleto queda igual.
const REST := {
	"lower_spine": Vector3.ZERO, "higher_spine": Vector3.ZERO, "chest": Vector3.ZERO, "neck": Vector3.ZERO,
	"head": Vector3.ZERO,
	"left_shoulder": Vector3(0.0, 0.0, PI * 0.5), "right_shoulder": Vector3(0.0, 0.0, -PI * 0.5),
	"left_upper_arm": Vector3(0.0, 0.0, PI * 0.5), "right_upper_arm": Vector3(0.0, 0.0, -PI * 0.5),
	"left_lower_arm": Vector3(0.0, 0.0, PI * 0.5), "right_lower_arm": Vector3(0.0, 0.0, -PI * 0.5),
	"left_hip": Vector3(0.0, 0.0, PI * 0.5), "right_hip": Vector3(0.0, 0.0, -PI * 0.5),
	"left_higher_leg": Vector3(-0.016851, -PI, PI), "right_higher_leg": Vector3(-0.016851, PI, -PI),
	"left_lower_leg": Vector3(-0.016851, -PI, PI), "right_lower_leg": Vector3(-0.016851, PI, -PI),
	"left_foot": Vector3(-1.553945, 0.0, 0.0), "right_foot": Vector3(-1.553945, 0.0, 0.0),
}


static func rest_basis(field: String) -> Basis:
	return Basis.from_euler(REST.get(field, Vector3.ZERO))
