class_name EntityArchetype

enum Archetype {fat_man, kid, lanky, buff, old, generic, fat_athletic}

# BASE STATS
var strength : float = 1.0
var weight : float = 60.0
## LA VELOCIDAD DE CAMINAR (× CharacterRigidBody3D.SPEED_SCALE, m/s): donde la animación pasa de caminar a correr.
var speed : float = 1.0
## LA VELOCIDAD MÁXIMA, en veces la de caminar: a la que llega manteniendo la tecla (ver CharacterRigidBody3D, EL
## MOVIMIENTO).
var sprint_multiplier : float = 2.2
## CUÁNTO TARDA EN LLEGAR A LA MÁXIMA desde quieto (s); 0, al instante. Frena al mismo ritmo.
var time_to_top : float = 3.0
## EL ATERRIZAJE FUERTE (m/s; 9 es caer de unos 4 m): al aterrizar frena según qué tan fuerte cayó contra esto (ver
## CharacterRigidBody3D._brake_on_landing). Desde el 17/11/2026 aterrizar no tumba.
var landing_tolerance : float = 9.0
## (Lo del cuerpo en el aire, la agachada del salto y el aterrizaje son de todos desde el 04 y el 05/11/2026: LocomotionCommon.)
var time_to_standup : float = 4.0

# REACH/ARMS
var throw_strength : float = 1.0

# JUMP
## Altura del apex a carga máxima, EN METROS (CharacterRigidBody3D.jump_to_height despeja el impulso).
## Un toque sin cargar sube el 30% de esto.
var jump_height : float = 0.8
var time_to_max_jump : float = 1.0

# AGE RANGE
var min_age : float = 1
var max_age : float = 99

# SPECIE PROBABILITIES
var robot_chance : float = 0.3
var alien_chance : float = 0.3
var human_chance : float = 1.0

# ANIMATIONS
## CUÁNTO SE MUEVE EL HOMBRO AL CAMINAR. **1.0 = el andar de referencia**, no el máximo: por debajo se
## apaga, por encima se exagera. Escala las seis registraciones de hombro de `animations.gd`.
##
## Los valores se re-escalaron ×2 cuando el knob pasó a manejar todo el hombro: antes 0.5 era el default
## y solo tocaba una registración menor, así que subirlo o bajarlo casi no hacía nada.
var shoulder_swing : float = 1.0
var arm_swing : float = 0.5
var root_bounciness : float = 1.0  # cuánto se hunde la pelvis al pisar, 1 la de referencia (ver PoseShape)
## ── EL ANDAR QUE ERA DE TODOS, DE CADA UNO (07/11/2026, el usuario: «cuando veo que dice un arquetipo arriba…
## supongo que estoy cambiando los sliders de ese arquetipo»; «me gusta tuitear todo independientemente») ─────────
## Lo que hasta entonces era una sola base para todos (WalkStyle): ahora cada arquetipo tiene el suyo, y cada personaje
## arma su estilo de caminar con esto (ver WalkStyle.for_archetype). Con `walk_` para no confundirse con los
## multiplicadores del estilo que usan los modificadores. Arrancan en lo que valía la base de todos.
var walk_twist : float = 1.0
var walk_spine_bow : float = 1.0
var walk_spine_roll : float = 1.0
var walk_lean : float = 0.03
var walk_posture_lean : float = 0.0
var walk_hip_sway : float = 1.0
var walk_bounce_up : float = 0.0
var walk_arm_open : float = 1.0
var walk_run_elbow : float = 0.3
var walk_stride_growth : float = 0.5
var walk_swing_share : float = 0.38
var walk_lead : float = 0.25
## ── UNA PERILLA, UN MOVIMIENTO (07/11/2026, el usuario: «hay bastante más limpieza… qué cosas hay duplicadas») ──
## `walk_hip_sway` mueve sólo la cadera (left_hip y right_hip de costado), `walk_twist` todo el giro de la columna contra
## las piernas, `walk_spine_bow` sólo el arco de costado, y `arm_swing` el braceo entero. *Hasta entonces `hip_swing`
## movía la cadera y también cuánto giraba la columna, `walk_hip_sway` multiplicaba la cadera y el arco, y
## `shoulder_swing` sumaba braceo; los números de cada arquetipo se convirtieron para que se vea igual.*
## Altura del arco del paso, en fracción del largo de pierna.
var step_height : float = 0.5
## ZANCADA — el único knob del andar, 0..1. No está en metros ni en fracción de pierna: es "cuánto
## de su alcance útil usa este personaje al caminar". 0 = pasitos cortos, 1 = zancada máxima.
##
## De acá sale TODO lo demás (SkeletonSizesUtil.create): la altura de pelvis que hace falta para que
## el pie llegue a esa zancada con la rodilla flexionada, y de ahí el alcance y la zancada en metros.
## Por eso `distance_from_ground_factor` ya no se escribe a mano — se deriva. Ver
## character-parametric:docs/technical/character-animation.md (el modelo de marcha).
## ── LA ZANCADA, DE 0 A 1 (05/11/2026, el usuario: «que sea un valor normalizado en base al largo de las piernas,
## y que si está en el máximo literalmente la pelvis toque el suelo… de esa manera voy a ver los límites») ──────────
## Qué tan lejos de la cadera llega el pie a toda velocidad, en largos de pierna: con 1 el pie llega a un largo de pierna
## entero, cosa que sólo se puede con la cadera en el piso; con 0, no se aleja. La pelvis baja lo que haga falta para que
## llegue (ver BoneInstantiator._update_pelvis_drop), y más despacio el paso se acorta como siempre (ver
## SkeletonSizesUtil._update_gait). *Hasta entonces `stride`, sin techo (llegaba a 3): el paso caminando en piernas × 0,8,
## y se podía pedir uno que la pierna no alcanzaba ni con la pelvis en el piso. Los valores de cada arquetipo son los que
## daban sus zancadas viejas, guardadas, a toda velocidad: el mismo paso.*
var stride_reach : float = 0.5
var stance_width: float = 1.0

# POSTURE
## ENCORVADO, 0..1, Y ES SOLO EL CUELLO: lo inclina hacia adelante y nada mas (ver
## SkeletonSizesUtil.slouchiness_neck).
##
## Era pecho adelante + lumbar atras de contrapeso + cuello adelante. Con el cuello CORTO a proposito (ver
## TorsoShape.neck_length), inclinarlo solo a el ya lee como hombros encogidos y cabeza adelantada: el
## encorvado entero, de dibujito, con un hueso en vez de tres que se compensan entre si.
var slouch : float = 0.0

## CURVA DE LA ESPALDA, 0..1, y NO es el encorvado: el pecho se va adelante y la lumbar atrás de contrapeso
## (ver SkeletonSizesUtil.spine_bend_chest). Es la vieja repartición de `slouch` entre tres huesos, con su
## propio nombre y su propia variable — y ahora va como postura de POSE, así que deforma el torso.
##
## Son dos ejes independientes a propósito: `slouch` da la cabeza adelantada de dibujito y esto da la
## espalda curva. Un viejo quiere las dos; un tímido, solo la primera.
var spine_bend : float = 0.0
## FLEXIÓN DE RODILLA EN REPOSO, 0..1. 0 = piernas casi rectas (~20° de rodilla), 1 = bien flexionadas
## (~52°). Es el equivalente de `arm_bentness` para la pierna.
##
## No es una pose que se escriba en un hueso: sale de **cuánto de su largo usa la pierna al estar
## parada**, o sea de la altura de pelvis. La geometría hace el resto — más flexión es la pelvis más
## abajo, y la IK acomoda rodilla y pie sola.
##
## Volvió a existir porque el modelo dejó de aportarla: antes la postura de reposo venía inclinada en el
## esqueleto y se leía de ahí; ahora está todo derecho y la flexión hay que pedirla.
var leg_bentness : float = 0.0

## EL TAMAÑO DE TODO EL CUERPO (07/11/2026, el usuario: «escala todo el fat man un 20 % (sus huesos, anchos,
## profundidad, etc)»): multiplica todo lo que mide en metros —huesos, anchos, fondos, cabeza, el paso, la cápsula—,
## con la misma palanca que la lupa del sandbox (ver SkeletonSizesUtil.size_scale). 1 = tal cual.
var body_scale : float = 1.0

var shoulders_forward : float = 0.0
var shoulders_drop : float = 0.0

## TEMBLOR EN REPOSO, 0..1. Manda las registraciones de `passive_animations.gd`.
##
## Es su propia variable y no se deduce de la edad a propósito: así el mismo efecto sirve después para
## un personaje herido, con frío o asustado, sin tocar nada.
var tremor : float = 0.0

## PROFUNDIDAD EXTRA DE LA RESPIRACIÓN, 0..1. **0 = normal**, no "sin respirar".
##
## Sube cuánto se abre el pecho SIN tocar el ritmo: el período sale solo de `exertion` en
## `PassiveState`, así que un gordo al que le cuesta respirar se lee por lo hondo, no por lo rápido.
##
## Normalizado como el resto de los knobs de cuerpo —0 neutro y el máximo declarado en un solo lugar,
## `PassiveState.BREATH_DEPTH_MAX`— y no como multiplicador crudo. Un multiplicador mezcla bien igual,
## pero el número no significa nada hasta que abrís el archivo que lo consume.
var breath_depth : float = 0.0

## FRECUENCIA EXTRA DE LA RESPIRACIÓN, 0..1. **0 = normal.** Acorta el período sin tocar la amplitud.
##
## Es el eje INDEPENDIENTE de `breath_depth`, y tenerlos separados es todo el punto: hondo y lento lee
## como "le cuesta respirar" (el gordo), rápido y normal lee como nervioso o hiperactivo (el buff). Con
## una sola perilla los dos personajes respirarían igual, más fuerte.
##
## Se compone con el esfuerzo en vez de reemplazarlo: `exertion` sigue acelerando desde acá, así que un
## personaje hiperactivo que además corrió jadea más rápido todavía. Techo en `PassiveState`.
var breath_rate : float = 0.0
var arm_bentness: float = 0.3

# VISUAL
var fatness : float = 0.5
var muscularity : float = 0.5

## LA FORMA DEL TORSO de este arquetipo —alto, ancho de cada tapa y fondo— NO está acá: es un `TorsoShape`,
## se edita desde el panel del sandbox y se guarda aparte (ver TorsoShapes). Lo que el arquetipo aporta es
## el DEFECTO, derivado de sus propios knobs en `SkeletonSizesUtil.create`: sin nada guardado, el personaje
## es el que el código describe.
##
## Lo que estuvo acá y salió: un chaflán (`torso_chamfer`), después una redondez de superelipse
## (`torso_roundness`) y una tabla de anillos autorados (`torso_profile`). El torso arranca siendo una CAJA
## y la forma se va a ir incorporando como REGLAS sobre ella, no como filas que haya que posicionar de a
## una: con treinta columnas y diecisiete anillos, mover anillo por anillo es trabajo de más para decir
## "esta caja es más ancha arriba".

var has_neck: bool = true

# PROPORTIONS — LARGOS DE HUESO
## Las tres cadenas paramétricas, 0..1 sobre los rangos medidos del modelo de Blender
## (SkeletonSizesUtil.MIN_/MID_/MAX_*). **0.5 = el largo tal como fue esculpido**, no el promedio de
## los extremos: el modelo ES el genérico, y los extremos se modelan a mano sin obligación de quedar
## simétricos. Por eso la interpolación va en dos tramos (lerp_three).
## Reemplazan a `height` + `legs_to_feet_proportion` + `chest_to_low_spine_proportion` + `reach`:
## ahora el modelo define lo posible y el arquetipo elige adentro. Ver "The reference rig" en
## character-parametric:docs/technical/character-body.md.
##
## ── EL TORSO PUEDE SER NEGATIVO, Y ESTÁ BIEN ──────────────────────────────────────────────────────
## `torso_chain_for` no clampea, así que un valor negativo ENCOGE respecto de lo esculpido. El nene, el
## flaco y el viejo lo usan. No es un bug ni un valor a "arreglar".
##
## Es la consecuencia de re-basar el torso al MEDIO del rango usado (×1.4547 en Blender) en vez de al
## extremo corto. El motivo fue de sombreado, no de proporción, y era de la malla skinneada de Blender,
## que ya no existe: escalaba el hueso solo en su eje Y (`scaled_local(1, s, 1)`) y el skinning
## transformaba las normales con esa misma matriz, cuando a una normal le corresponde la inversa
## transpuesta. El error crecía con `|s − 1|`, y el buff —el más estirado, con s = 1.70— se veía mal en
## hombros y panza.
##
## Centrando la base, la desviación máxima cayó de 0.75 a 0.20 y el sombreado se limpió para los seis.
## Las proporciones NO cambiaron: los seis valores se recalibraron con `t = s_viejo / 1.4547 − 1`.
var legs_length  : float = 0.5
var arms_length  : float = 0.5

## Cuánto puede ESTIRAR el brazo al agarrar, en múltiplos de su largo en reposo. Es una variable
## INDEPENDIENTE de `arms_length`, y la distinción importa: `arms_length` es la proporción del cuerpo
## —qué brazo tiene el personaje parado sin hacer nada— y esto es cuánto se sale de esa proporción
## para alcanzar algo. Un personaje de brazos cortos puede tener un estirón enorme y al revés.
##
## De acá sale `SkeletonSizesUtil.interaction_reach`, o sea el alcance de agarre en metros: es LA
## perilla del alcance por arquetipo.
##
## El techo lo pone el rango autorado en Blender (ver ReferenceRig.ARM_MODEL_FACTOR), y
## SkeletonSizesUtil lo clampea ahí solo. Con la malla de Blender eso era lo que hacía que el brazo
## estirado tuviera la silueta que se esculpió y no se viera "de goma".
var arm_stretch : float = 2.0

## ── LOS DOS EJES DE MASA ──────────────────────────────────────────────────────────────────────────
## Con la malla de Blender iba cada uno derecho a un shape key (`muscle_max` / `fat_max`); esa malla ya
## no existe. Hoy lo único que leen es el ancho del esqueleto: `muscle` ensancha el hombro y `fat` la
## cadera (ver ReferenceRig.FRAME_MODEL_FACTOR / HIPS_MODEL_FACTOR y SkeletonSizesUtil).
##
## `0, 0` = EL MODELO TAL CUAL SE ESCULPIÓ, que es el extremo FLACO Y SIN MÚSCULO. Por eso ningún
## arquetipo va en 0: hasta el viejo débil lleva algo de las dos.
##
## `muscle + fat` es cuánta masa; `muscle / (muscle + fat)` es de qué tipo. Un tipo normal vive cerca de
## 0.7 de suma, un fuerte o un gordo cerca de 1, y el gordo fuerte arriba de 1.5.
##
## Están separados de `fatness` a propósito: `fatness` dimensiona los COLISIONADORES del rig lógico
## (los radios de las cápsulas de la columna), que es otra cosa. Si con el tiempo resulta que siempre
## se mueven juntos, se unifican; hoy no hay evidencia de eso.
var muscle : float = 0.0
var fat : float = 0.0



var incompatible_archetypes : Array[Archetype] = []
var archetype_frequency : float = 1.0

## EL ARQUETIPO, con lo que el panel del sandbox haya guardado de su POSTURA Y SU ANDAR escrito encima
## (ver PoseShapes). `apply_saved = false` devuelve el del código puro, y lo usa el propio panel: es el
## defecto que muestra y el valor al que vuelve Olvidar.
##
## ⚠ EL OVERRIDE VA ACÁ, donde el arquetipo nace, y no más abajo. Todo lo que viene después —la mezcla con
## un segundo arquetipo, los multiplicadores de especie, la variación por individuo— se calcula entonces
## sobre los números guardados igual que se calculaba sobre los escritos a mano, sin saber que esto existe.
static func create(archetype: Archetype, apply_saved := true) -> EntityArchetype:
	var out := _authored(archetype)
	# (El gordo atlético todavía no sale a la calle: `_pick_archetype` no lo sortea.)
	if apply_saved:
		PoseShapes.apply(out, int(archetype))
	# LA CARGA DEL SALTO, LA MISMA PARA TODOS (04/11/2026, el usuario: «haría que sea el mismo en todos, al igual
	# que el wind up de arrojar algo»): `JUMP_WINDUP_S`. Ya no es una perilla de cada uno (ver PoseShape.JUMP_KNOBS).
	out.time_to_max_jump = JUMP_WINDUP_S
	return out


## (De 0,5 a 0,25 s el 04/11/2026, el usuario: «podés aumentarle la carga así no necesitan tanto windup».)
const JUMP_WINDUP_S := 0.25


## Lo que dice el código, sin capas encima.
static func _authored(archetype: Archetype) -> EntityArchetype:
	match archetype:
		Archetype.fat_man:
			return fat_man_arch()
		Archetype.kid:
			return kid_arch()
		Archetype.lanky:
			return lanky_arch()
		Archetype.buff:
			return buff_arch()
		Archetype.old:
			return old_arch()
		Archetype.fat_athletic:
			return fat_athletic_arch()
	return generic_arch()

## NEUTRO — el arquetipo de referencia del modelo de Blender. Postura sin nada raro: sin joroba, sin
## piernas lisiadas, base de pies angosta, brazos rectos al costado. No es un
## personaje de juego: existe para poder MIRAR las proporciones del modelo tal como se esculpió, sin que
## la postura de un arquetipo se coma la evaluación.
##
## Sus cadenas están elegidas para reproducir el modelo esculpido ORIGINAL, que no es lo mismo que
## poner 0.5: a medida que una cadena consigue sus extremos autorados en Blender, el modelo pasa a ser
## el 0.0 de esa cadena y el valor que reproduce el original se corre. Ver abajo.
##
## Con `EntityInstantiation.FORCE_ARCHETYPE` apuntando acá, todos los personajes vuelven a ser este —
## la vista de la fase 1, que sigue sirviendo para mirar las proporciones del modelo sin ruido. Para
## mirar UN arquetipo sin tocar código está el panel de debug (tab Arquetipos).
## Ver "The reference rig" en character-parametric:docs/technical/character-body.md.
static func generic_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	arch.strength = 1.0
	arch.weight = 80.0
	arch.speed = 0.3
	arch.sprint_multiplier = 2.6
	arch.time_to_top = 3.4
	arch.time_to_standup = 1.5
	arch.throw_strength = 0.9
	arch.jump_height = 1.12
	arch.time_to_max_jump = 0.5
	arch.min_age = 20
	arch.max_age = 60
	arch.robot_chance = 0.0
	arch.alien_chance = 0.0
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	# No entra en el sorteo ni en los blends: es un arquetipo de referencia, no de población.
	arch.archetype_frequency = 0.0
	arch.shoulder_swing = 1.0
	arch.arm_swing = 0.8
	arch.walk_hip_sway = 0.5
	arch.walk_twist = 0.5833
	arch.root_bounciness = 1.0
	arch.step_height = 0.4
	# ZANCADA — significa literalmente "qué tan largo es el paso", nada más: el paso caminando, en piernas (ver
	# SkeletonSizesUtil, LA ZANCADA MANDA). La altura de pelvis no sale de acá: la resuelve la geometría cada frame (ver
	# BoneInstantiator._update_pelvis_drop).
	arch.stride_reach = 0.49
	arch.slouch = 0.0
	arch.leg_bentness = 0.00
	arch.tremor = 0.0
	arch.shoulders_forward = -0.25
	arch.shoulders_drop = 0.0
	# `arm_bentness` SÍ puede ser 0: el piso de la flexión lo pone `SkeletonSizesUtil.ARM_REST_EXTENSION`
	# (0.985 → ~20° de codo), que existe justo para que la extensión total nunca se alcance. A extensión
	# total el codo queda colineal, el plano de flexión se indefine y la torsión de la mano sale
	# arbitraria — fue el bug de las manos dadas vuelta.
	#
	# HOY TODOS LOS ARQUETIPOS ESTÁN EN 0. Los valores viejos (0.10–0.20) venían de cuando el brazo del
	# modelo era más corto y el codo necesitaba flexión propia para no quedar colineal; con el tope de
	# 0.985 haciendo ese trabajo, lo único que agregaban era un codo doblado de más. Vuelve a ser un
	# knob por arquetipo cuando haya una razón de postura para diferenciarlos.
	#
	# `arm_openness` y `stance_width` estuvieron IGUALADOS EN LOS SEIS un tiempo: los valores viejos
	# (0.2 a 0.58) eran de cuando la postura era lo único que distinguía a un arquetipo de otro, y con
	# la variedad viniendo de largo de cadena, músculo y grasa, abrir los brazos encima solo era ruido.
	#
	# El `fat_man` es el primero que los vuelve a mover, y con la razón que faltaba: no es gusto de
	# postura, es que el cuerpo OCUPA LUGAR. Con la cadera a 1.62× los muslos se tocan y con ese torso
	# los brazos no pueden colgar pegados. Los dos números salen de la geometría, no del estilo — y ese
	# es el criterio para que otro arquetipo los toque.
	arch.arm_bentness = 0.0
	arch.fatness = 0.5
	arch.muscularity = 0.5
	arch.has_neck = true
	# ── LOS VALORES QUE REPRODUCEN EL MODELO ESCULPIDO ────────────────────────────────────────────
	# Ojo: NO son 0.5 los tres, y la diferencia es estructural, no un ajuste fino.
	#
	# Una cadena sin extremos autorados usa el esquema provisorio (el modelo es el 0.5, los extremos son
	# factores sobre él) ⇒ 0.5 reproduce el modelo. Una cadena YA AUTORADA en Blender tiene el modelo
	# como 0.0 —porque el 0.0 tiene que ser un extremo real— ⇒ el valor que reproduce el original es
	# otro, y sale de despejar `1 + (F−1)·v` contra el largo que tenía antes de acortarlo.
	#
	#   pierna: se acortó al 65% en Blender, F = 2 ⇒ v = 0.5385 devuelve los 0.9119 m de siempre
	#   brazo:  ver ARM_EXT_MIN/MAX — el arquetipo se mueve en una banda angosta del rango ×4
	#   torso:  todavía provisorio ⇒ 0.5
	arch.legs_length  = 0.589
	arch.arms_length  = 0.5851
	# El genérico es la malla tal cual: deformación cero también en las de clase B.
	arch.muscle        = 0.0
	arch.fat           = 0.0
	arch.arm_stretch  = 2.0
	# STANCE NEUTRAL EN TODOS LOS ARQUETIPOS, por ahora a propósito.
	#
	# La separación de pies ya sale del MODELO (`rig.foot_rest_x`, escalado por el largo de
	# pierna); esto es un multiplicador encima. Estaba en 1.3–1.4 en todos, de cuando la estancia
	# se estimaba del ancho de cadera, y se leía como piernas muy abiertas.
	#
	# Vuelve a diferenciarse cuando estén `torso_length` y `frame_width`: recién ahí la postura
	# tiene con qué distinguirse y el stance deja de ser el único parche disponible.
	arch.stance_width = 1.0
	return arch

static func fat_man_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	arch.strength = 0.9
	arch.weight = 120.0
	arch.speed = 0.3
	arch.sprint_multiplier = 2.3
	arch.time_to_top = 4.6
	# EL EQUILIBRIO (ver `balance`): pesado, cuesta moverlo; inclinado, tarda en volver y rebota como gelatina.
	balance(arch, 120.0)
	arch.time_to_standup = 2.0
	arch.throw_strength = 1.05
	arch.jump_height = 0.45
	arch.time_to_max_jump = 0.3
	arch.min_age = 1
	arch.max_age = 99
	arch.robot_chance = 0.3
	arch.alien_chance = 0.6
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	arch.archetype_frequency = 1.0
	arch.shoulder_swing = 0.6
	arch.arm_swing = 0.68
	arch.walk_hip_sway = 0.5
	arch.walk_twist = 0.5833
	arch.root_bounciness = 1.0
	arch.step_height = 0.4
	# Camina "corto para lo que mide": pasitos rápidos bajo un cuerpo pesado, base ancha.
	arch.stride_reach = 0.59
	arch.slouch = 0.0
	arch.leg_bentness = 0.25
	arch.tremor = 0.0
	# DESPEJADAS contra la masa, no medidas solas. El ancho final es `masa × escala`, y las medidas de
	# Blender son 1.61765 de cadera y 1.45811 de hombro: con `fat 1.0` la cadera ya trae ×1.3 puesto, y
	# con `muscle 0.0` el hombro no trae nada y la medida va entera acá.
	# ⚠ Si algún día se mueve `fat` o `muscle`, estos dos hay que volver a despejarlos.
	# 1,90 m (07/11/2026, el usuario: «dejalo que mida 1.90»): sin esto, 1,75.
	arch.body_scale = 1.0857
	arch.breath_depth = 0.3
	arch.breath_rate = 0.0
	arch.shoulders_forward = -0.70
	arch.shoulders_drop = 0.0
	arch.arm_bentness = 0.0
	arch.fatness = 1.0
	arch.muscularity = 0.9
	arch.has_neck = true
	# Torso grande sobre piernas cortas. ≈1.74 m.
	arch.legs_length  = 0.60
	arch.arms_length  = 0.7245
	arch.muscle        = 0.0
	arch.fat           = 1.0
	arch.stance_width = 1.18
	return arch

static func kid_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	# LA FUERZA (04/11/2026, propuesta al usuario): kid 0,35, viejo 0,45, flaco alto 0,6, gordo 0,9, fornido
	# 1,2, gordo atlético 1,4 (ver `create`). Contra los pesos de las cajas, ver GrabbableInteractable.load_of.
	arch.strength = 0.35
	arch.speed = 0.4
	arch.sprint_multiplier = 2.5
	arch.time_to_top = 2.8
	# EL EQUILIBRIO (ver `balance`): muy liviano, cualquier golpe lo mueve; buen equilibrio, vuelve rápido y rebota.
	balance(arch, 35.0)
	arch.time_to_standup = 1.0
	arch.throw_strength = 0.5
	arch.jump_height = 0.8
	arch.time_to_max_jump = 0.5
	arch.min_age = 1
	arch.max_age = 99
	arch.robot_chance = 0.0
	arch.alien_chance = 0.0
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	arch.archetype_frequency = 1.0
	arch.shoulder_swing = 1.0
	arch.arm_swing = 1
	arch.walk_hip_sway = 0.5
	arch.walk_twist = 0.5833
	arch.root_bounciness = 1.0
	arch.step_height = 0.4
	# Trotecito: piernas cortas, muchos pasos chicos.
	arch.stride_reach = 0.69
	arch.slouch = 0.1
	arch.leg_bentness = 0.00
	arch.tremor = 0.0
	arch.shoulders_forward = 0.0
	arch.shoulders_drop = 0.55
	arch.arm_bentness = 0.0
	arch.fatness = 0.23
	arch.muscularity = 0.17
	arch.has_neck = true
	# El más chico de todos. ≈1.38 m.
	arch.legs_length  = 0.26
	# 0.0 es el PISO REAL: el brazo tal cual se esculpió en Blender. No hay más corto que esto
	# sin re-esculpir la base, y para un personaje de 1.43 m sigue quedando proporcionalmente
	# largo — el mismo re-baseo que hubo que hacerle a la pierna le va a hacer falta al brazo.
	arch.arms_length  = 0.3614
	arch.muscle        = 0.0
	arch.fat           = 0.0
	arch.stance_width = 1.0
	return arch

## EL FLACO ALTO. *Del 22/10/2026 al 07/11/2026 fue una copia del gordo con lo suyo encima (el usuario: «no tienen
## que haber copias»); son los mismos números, escritos acá.*
static func lanky_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	arch.strength = 0.6
	arch.speed = 0.3
	arch.sprint_multiplier = 2.3
	arch.time_to_top = 4.6
	# EL EQUILIBRIO (ver `balance`): liviano y angosto, se tumba más de costado; se endereza rápido pero se bambolea.
	balance(arch, 70.0)
	arch.time_to_standup = 2.0
	arch.throw_strength = 0.8
	# EL SALTO DE CADA UNO (04/11/2026, el usuario: «algunos personajes con más salto, algunos con menos»): el
	# fornido 1,0, el gordo atlético 0,85, el kid 0,8, el flaco alto 0,7, el gordo 0,45, el viejo 0,35.
	arch.jump_height = 0.7
	arch.min_age = 1
	arch.max_age = 99
	arch.robot_chance = 0.3
	arch.alien_chance = 0.6
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	arch.archetype_frequency = 1.0
	arch.shoulder_swing = 0.6
	arch.arm_swing = 0.68
	arch.walk_hip_sway = 0.5
	arch.walk_twist = 0.5833
	arch.root_bounciness = 1.0
	arch.step_height = 0.4
	arch.stride_reach = 0.73
	arch.slouch = 0.0
	arch.leg_bentness = 0.25
	arch.tremor = 0.0
	# Los anchos, despejados contra la masa como los del gordo (ver `fat_man_arch`).
	arch.body_scale = 1.0
	arch.breath_depth = 0.3
	arch.breath_rate = 0.0
	arch.shoulders_forward = -0.70
	arch.shoulders_drop = 0.0
	arch.arm_bentness = 0.0
	arch.fatness = 1.0
	arch.muscularity = 0.9
	arch.has_neck = true
	arch.legs_length  = 0.60
	arch.arms_length  = 0.7245
	arch.muscle        = 0.0
	arch.fat           = 1.0
	arch.stance_width = 1.18
	return arch

## EL FORNIDO. *Del 22/10/2026 al 07/11/2026 fue una copia del gordo con lo suyo encima; son los mismos números, escritos
## acá.*
static func buff_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	arch.strength = 1.2
	arch.speed = 0.3
	arch.sprint_multiplier = 2.3
	arch.time_to_top = 4.6
	# EL EQUILIBRIO (ver `balance`): el más firme; vuelve seco a su lugar.
	balance(arch, 95.0)
	arch.time_to_standup = 2.0
	arch.throw_strength = 1.45
	arch.jump_height = 1.0
	arch.min_age = 1
	arch.max_age = 99
	arch.robot_chance = 0.3
	arch.alien_chance = 0.6
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	arch.archetype_frequency = 1.0
	arch.shoulder_swing = 0.6
	arch.arm_swing = 0.68
	arch.walk_hip_sway = 0.5
	arch.walk_twist = 0.5833
	arch.root_bounciness = 1.0
	arch.step_height = 0.4
	arch.stride_reach = 0.59
	arch.slouch = 0.0
	arch.leg_bentness = 0.25
	arch.tremor = 0.0
	# Los anchos, despejados contra la masa como los del gordo (ver `fat_man_arch`).
	arch.body_scale = 1.0
	arch.breath_depth = 0.3
	arch.breath_rate = 0.0
	arch.shoulders_forward = -0.70
	arch.shoulders_drop = 0.0
	arch.arm_bentness = 0.0
	arch.fatness = 1.0
	arch.muscularity = 0.9
	arch.has_neck = true
	arch.legs_length  = 0.60
	arch.arms_length  = 0.7245
	arch.muscle        = 0.0
	arch.fat           = 1.0
	arch.stance_width = 1.18
	return arch


## EL GORDO ATLÉTICO. *Del 26/10/2026 al 07/11/2026 nacía en `create` como la mitad del gordo y la mitad del fornido, con
## lo que cada uno tenía guardado; son esos números, escritos acá (el usuario: «no tienen que haber copias»). Lo
## suyo encima: el más fuerte de todos (04/11/2026, «el gordo atlético deberían ser los más fuertes»), su salto y su tiro.*
static func fat_athletic_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	arch.strength = 1.4
	arch.speed = 0.275
	arch.sprint_multiplier = 1.9
	arch.time_to_top = 3.4
	# EL EQUILIBRIO (ver `balance`): entre el gordo y el fornido.
	balance(arch, 107.5)
	arch.time_to_standup = 2.0
	arch.throw_strength = 1.6
	arch.jump_height = 0.85
	arch.min_age = 1
	arch.max_age = 99
	arch.robot_chance = 0.3
	arch.alien_chance = 0.6
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	arch.archetype_frequency = 1.0
	arch.shoulder_swing = 1.3
	arch.arm_swing = 0.815
	arch.walk_hip_sway = 0.7
	arch.walk_twist = 0.75
	arch.root_bounciness = 0.75
	arch.step_height = 0.45
	arch.stride_reach = 0.515
	arch.slouch = 0.375
	arch.leg_bentness = 0.25
	arch.tremor = 0.0
	# Los anchos, despejados contra la masa como los del gordo (ver `fat_man_arch`).
	arch.body_scale = 1.04285
	arch.breath_depth = 0.3
	arch.breath_rate = 0.0
	arch.shoulders_forward = -0.05
	arch.shoulders_drop = 0.0
	arch.arm_bentness = 0.025
	arch.fatness = 1.0
	arch.muscularity = 0.9
	arch.has_neck = true
	arch.legs_length  = 0.60
	arch.arms_length  = 0.7245
	arch.muscle        = 0.0
	arch.fat           = 1.0
	arch.stance_width = 1.49
	return arch


## ── EL EQUILIBRIO DE CADA ARQUETIPO (02/11/2026, propuesto al usuario y aprobado como punto de partida) ──────
## El peso dice cuánto cuesta moverlo (la masa: en un choque, el liviano se lleva el cambio de velocidad); la estabilidad,
## adelante, atrás y de costado, cómo está plantado de cada lado. Los dos juntos son la FIRMEZA, que divide cuánto lo
## inclinan los golpes y la inercia (ver CharacterRigidBody3D._firmness): todos caen en el mismo punto, así que
## inclinarse es estar cerca de caer. `spring`, qué tan duro se endereza; `damp`, cuánto frena el rebote (más, rebota
## menos). Caminar no cambia con el peso: su fuerza ya es proporcional a él.
static func balance(arch: EntityArchetype, weight_kg: float) -> void:
	arch.weight = weight_kg

static func old_arch() -> EntityArchetype:
	var arch = EntityArchetype.new()
	arch.strength = 0.45
	arch.speed = 0.15
	arch.sprint_multiplier = 1.8
	arch.time_to_top = 1.25
	# EL EQUILIBRIO (ver `balance`): frágil, sobre todo para atrás; le cuesta enderezarse y casi no rebota.
	balance(arch, 65.0)
	arch.time_to_standup = 1.0
	arch.throw_strength = 0.6
	arch.jump_height = 0.35
	arch.time_to_max_jump = 0.5
	arch.min_age = 50
	arch.max_age = 99
	arch.robot_chance = 0.0
	arch.alien_chance = 0.0
	arch.human_chance = 1.0
	arch.incompatible_archetypes = [] as Array[Archetype]
	arch.archetype_frequency = 1.0
	arch.shoulder_swing = 0.35
	arch.arm_swing = 0.605
	arch.walk_hip_sway = 0.5
	arch.walk_twist = 0.5833
	arch.root_bounciness = 1.0
	arch.step_height = 0.3
	# Arrastra los pies: la zancada más corta de todas.
	arch.stride_reach = 0.28
	arch.slouch = 1.0
	arch.leg_bentness = 0.30
	arch.tremor = 0.375
	arch.shoulders_forward = 1.0
	arch.shoulders_drop = 1.0
	arch.arm_bentness = 0.0
	arch.fatness = 0.1
	arch.muscularity = 0.0
	arch.has_neck = true
	# Encogido: todo por debajo de la media. ≈1.59 m.
	arch.legs_length  = 0.560
	arch.arms_length  = 0.4819
	arch.muscle        = 0.0
	arch.fat           = 0.0
	arch.stance_width = 1.0
	return arch


func blend_with(b: EntityArchetype, t: float) -> EntityArchetype:
	var r := EntityArchetype.new()
	r.strength                      = lerpf(strength, b.strength, t)
	r.weight                        = lerpf(weight, b.weight, t)
	r.speed                         = lerpf(speed, b.speed, t)
	r.sprint_multiplier             = lerpf(sprint_multiplier, b.sprint_multiplier, t)
	r.time_to_top                   = lerpf(time_to_top, b.time_to_top, t)
	r.landing_tolerance             = lerpf(landing_tolerance, b.landing_tolerance, t)
	r.time_to_standup               = lerpf(time_to_standup, b.time_to_standup, t)
	r.throw_strength                = lerpf(throw_strength, b.throw_strength, t)
	r.jump_height                   = lerpf(jump_height, b.jump_height, t)
	r.time_to_max_jump              = lerpf(time_to_max_jump, b.time_to_max_jump, t)
	r.min_age                       = lerpf(min_age, b.min_age, t)
	r.max_age                       = lerpf(max_age, b.max_age, t)
	r.robot_chance                  = lerpf(robot_chance, b.robot_chance, t)
	r.alien_chance                  = lerpf(alien_chance, b.alien_chance, t)
	r.human_chance                  = lerpf(human_chance, b.human_chance, t)
	r.shoulder_swing                = lerpf(shoulder_swing, b.shoulder_swing, t)
	r.arm_swing 					= lerpf(arm_swing, b.arm_swing, t)
	r.root_bounciness               = lerpf(root_bounciness, b.root_bounciness, t)
	for knob: String in WalkStyle.ARCHETYPE_KNOBS:
		r.set("walk_" + knob, lerpf(float(get("walk_" + knob)), float(b.get("walk_" + knob)), t))
	r.step_height                   = lerpf(step_height, b.step_height, t)
	r.stride_reach                  = lerpf(stride_reach, b.stride_reach, t)
	r.slouch                        = lerpf(slouch, b.slouch, t)
	r.spine_bend                    = lerpf(spine_bend, b.spine_bend, t)
	r.leg_bentness                  = lerpf(leg_bentness, b.leg_bentness, t)
	r.tremor                        = lerpf(tremor, b.tremor, t)
	r.breath_depth                  = lerpf(breath_depth, b.breath_depth, t)
	r.breath_rate                   = lerpf(breath_rate, b.breath_rate, t)
	r.body_scale                    = lerpf(body_scale, b.body_scale, t)
	r.shoulders_forward             = lerpf(shoulders_forward, b.shoulders_forward, t)
	r.shoulders_drop                = lerpf(shoulders_drop, b.shoulders_drop, t)
	r.fatness                       = lerpf(fatness, b.fatness, t)
	r.muscle                        = lerpf(muscle, b.muscle, t)
	r.fat                           = lerpf(fat, b.fat, t)
	r.muscularity                   = lerpf(muscularity, b.muscularity, t)
	r.arm_stretch                   = lerpf(arm_stretch, b.arm_stretch, t)
	# DISCRETO A PROPÓSITO, y por eso se copia de A en vez de promediarse: no es una proporción, es de
	# qué está hecho el personaje. Un robot puede no tener cuello; medio cuello no existe.
	r.has_neck                      = has_neck
	r.legs_length                   = lerpf(legs_length, b.legs_length, t)
	r.arms_length                   = lerpf(arms_length, b.arms_length, t)
	r.stance_width = lerpf(stance_width, b.stance_width, t)
	r.arm_bentness          = lerpf(arm_bentness, b.arm_bentness, t)
	return r
