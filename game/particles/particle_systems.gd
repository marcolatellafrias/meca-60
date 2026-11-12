class_name ParticleSystems
extends RefCounted

## LOS SISTEMAS DE PARTÍCULAS DEL JUEGO, uno por función. Cada uno arma su emisor ya configurado; quien lo usa solo
## lo cuelga, lo orienta y lo prende (ver CarModel, y el sistema de daño de los autos).
##
## ── LAS REGLAS QUE COMPARTEN ─────────────────────────────────────────────────────────────────────
##   · LA MALLA ES UNA DE LAS TRES ESTÁNDAR (ParticleMeshes): línea, esfera o cuadrado. Ninguna propia.
##   · COLORES PLANOS: el material no se sombrea; el sistema decide el color, la opacidad y el tamaño de cada
##     partícula, y esas tres cosas son lo que da carácter a un sistema. Dos maneras de darle color, y cada sistema
##     dice cuál usa: UN TONO AL AZAR por partícula (`_tones`, el humo del propulsor: todas iguales pero distintas)
##     o UNA VIDA DE COLORES (`_life`, el fuego: amarillo → rojo → negro mientras envejece).
##   · TODOS ACEPTAN OTRO TAMAÑO (`size`): el mismo sistema en chico es el mismo sistema (la estela de un pedazo que
##     vuela es el fuego en chico), no uno nuevo.
##   · EMITE HACIA SU −Z, el frente de cualquier nodo en Godot: orientarlo es del que lo cuelga (el propulsor lo
##     gira hacia la cola, ver CarModel). Un sistema no sabe a qué está pegado.
##   · EN COORDENADAS DEL MUNDO (`local_coords` apagado): lo que se soltó se queda donde se soltó, aunque lo que
##     lo emite se mueva o salte. Por eso tampoco interpola: un emisor que aparece en otro lado (un visual que
##     vuelve del pool) dejaría una raya de partículas en el camino.
##   · APAGADO NO CUESTA: un emisor sin partículas vivas y sin emitir no se procesa. Se prenden y se apagan por
##     distancia donde se usan.
##   · DE RÁFAGA O CONTINUO: los que son un evento (el destello, las chispas) salen todos juntos y se terminan
##     (`one_shot`); se disparan con `restart()`. Los demás emiten hasta que se los apaga.
##
## Para verlos y criticarlos: la fila "Partículas" del design sandbox (ParticleArchetype), con una parcela por
## sistema, una tecla para probarlo con las otras dos mallas, y las ráfagas repitiéndose solas.

## Los sistemas que hay: la fila "Partículas" del sandbox. Cada uno: `{name, kind, make}` —`make(kind, size)` da un
## emisor nuevo— y `burst` si es un evento que se dispara, en vez de emitir continuo.
static func catalogue() -> Array[Dictionary]:
	return [
		{"name": "Humo de propulsor", "kind": ParticleMeshes.Kind.SPHERE, "make": thruster_smoke},
		{"name": "Humo de propulsor fallando", "kind": ParticleMeshes.Kind.SPHERE, "make": failing_smoke},
		{"name": "Fuego", "kind": ParticleMeshes.Kind.SPHERE, "make": fire},
		{"name": "Destello de explosión", "kind": ParticleMeshes.Kind.SPHERE, "make": explosion_flash, "burst": true},
		{"name": "Chispas de explosión", "kind": ParticleMeshes.Kind.LINE, "make": explosion_sparks, "burst": true},
		{"name": "Polvo de golpe", "kind": ParticleMeshes.Kind.SPHERE, "make": impact_dust, "burst": true},
		{"name": "Vapor", "kind": ParticleMeshes.Kind.SPHERE, "make": steam},
		{"name": "Humo de chimenea", "kind": ParticleMeshes.Kind.SPHERE, "make": chimney_smoke},
		{"name": "Chispazo", "kind": ParticleMeshes.Kind.LINE, "make": zap, "burst": true},
	]


# ── HUMO DE PROPULSOR ────────────────────────────────────────────────────────────────────────────

## Bocanadas que salen de la tobera, se frenan, suben y se desvanecen. Lo que varía de una a otra es TAMAÑO,
## OPACIDAD y COLOR: el tamaño entre `SMOKE_SIZE_MIN` y `SMOKE_SIZE_MAX` (más lo que crece con la edad,
## `SMOKE_GROWTH`), y el color y la opacidad, de `SMOKE_TONES` —cada partícula saca un tono al azar de ahí, con
## su alfa— más la curva de opacidad, que la hace aparecer y apagarse (`SMOKE_FADE_IN`).
## Cuántas vivas por emisor, cuánto dura cada una, a qué velocidad sale de la tobera (m/s) y cuánto sube (m/s²).
const SMOKE_AMOUNT := 24
const SMOKE_LIFETIME := 1.2
const SMOKE_SPEED := 2.0
const SMOKE_RISE := 0.6
## Diámetro al salir (m) y cuánto crece hasta desaparecer.
const SMOKE_SIZE_MIN := 0.22
const SMOKE_SIZE_MAX := 0.42
const SMOKE_GROWTH := 2.6
## Cuánto se abre el chorro (grados) y qué tan lejos de la boca puede nacer una bocanada (m).
const SMOKE_SPREAD := 10.0
const SMOKE_MOUTH := 0.08
## Los tonos: de cada uno sale un color Y una opacidad. Gris claro y transparente, gris sucio y más denso.
const SMOKE_TONES: Array[Color] = [Color(0.66, 0.66, 0.64, 0.28), Color(0.52, 0.52, 0.53, 0.45),
	Color(0.36, 0.36, 0.38, 0.6)]
## Qué parte de la vida tarda en llegar a su opacidad plena; el resto se desvanece.
const SMOKE_FADE_IN := 0.15


## EL HUMO DE UN PROPULSOR SANO: esferas de colores planos que salen hacia atrás, se frenan, suben y se apagan.
static func thruster_smoke(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(SMOKE_SPEED, SMOKE_SPREAD, SMOKE_RISE, SMOKE_MOUTH * size)
	_size(process, SMOKE_SIZE_MIN * size, SMOKE_SIZE_MAX * size, SMOKE_GROWTH)
	process.color_initial_ramp = _tones(SMOKE_TONES)
	process.alpha_curve = _curve([Vector2(0.0, 0.0), Vector2(SMOKE_FADE_IN, 1.0), Vector2(1.0, 0.0)])
	return _emitter(kind, SMOKE_AMOUNT, SMOKE_LIFETIME, process)


# ── HUMO DE PROPULSOR FALLANDO ───────────────────────────────────────────────────────────────────

## El auto que se cae: el propulsor escupe humo NEGRO, más denso y más rápido que el sano, que se aclara a gris
## mientras se disipa. Es lo que se ve mientras cae, y también la columna de la chatarra que arde.
const FAILING_AMOUNT := 34
const FAILING_LIFETIME := 1.6
const FAILING_SPEED := 3.0
const FAILING_RISE := 1.4
const FAILING_SIZE_MIN := 0.3
const FAILING_SIZE_MAX := 0.55
const FAILING_GROWTH := 3.0
const FAILING_SPREAD := 16.0
## La vida del color: negro denso al salir, gris sucio en el medio, gris claro que se va.
const FAILING_LIFE: Array[Color] = [Color(0.06, 0.06, 0.06, 0.9), Color(0.22, 0.21, 0.2, 0.75),
	Color(0.5, 0.49, 0.48, 0.45), Color(0.62, 0.62, 0.62, 0.0)]


static func failing_smoke(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(FAILING_SPEED, FAILING_SPREAD, FAILING_RISE, SMOKE_MOUTH * size)
	_size(process, FAILING_SIZE_MIN * size, FAILING_SIZE_MAX * size, FAILING_GROWTH)
	process.color_ramp = _life(FAILING_LIFE)
	return _emitter(kind, FAILING_AMOUNT, FAILING_LIFETIME, process)


# ── FUEGO ────────────────────────────────────────────────────────────────────────────────────────

## Llamas: esferas que nacen amarillo fuerte, pasan a naranja, a rojo oscuro y terminan en negro transparente,
## creciendo todo el tiempo. SUBEN, mire adonde mire el emisor: sale despacio (`FIRE_SPEED`) y lo que manda es la
## subida (`FIRE_RISE`), que es en el mundo. Lo usa la chatarra que arde y, en chico (`size`), la estela de cada
## pedazo que sale volando en la explosión.
##
## Y ES LA ÚNICA QUE TIENE VIENTO: `FIRE_WIND` la corre de costado mientras sube, y una turbulencia suave la hace
## titilar. Las demás no lo necesitan —el humo ya se va con su propia inercia—; el día que el mundo tenga un viento
## de verdad (hoy solo lo tienen las nubes, ver el weather tuner), esta constante pasa a leerlo.
## Cuántas vivas y cuánto dura cada llama. La vida es LARGA a propósito: es lo que le da tiempo a subir y a pasar
## por todos sus colores —con una vida corta, la parte negra es un parpadeo que no se llega a ver—. Como el ritmo
## de nacimiento es `FIRE_AMOUNT / FIRE_LIFETIME`, alargar la vida pide más partículas para que la columna no se
## ralee.
const FIRE_AMOUNT := 46
const FIRE_LIFETIME := 1.5
const FIRE_SPEED := 0.5
## Cuánto sube (m/s²). Es lo que da la altura de la columna: con la misma vida, más subida es más alto. Lo que
## suba tiene que entrar en la caja de visibilidad del emisor (ver `fire`), o la columna se recorta.
const FIRE_RISE := 8.0
## El viento: cuánto la corre de costado mientras sube (m/s²), y cuánto titila.
const FIRE_WIND := Vector3(1.1, 0.0, 0.45)
const FIRE_TURBULENCE := 0.7
const FIRE_TURBULENCE_SCALE := 2.5
const FIRE_SIZE_MIN := 0.3
const FIRE_SIZE_MAX := 0.6
const FIRE_GROWTH := 2.8
const FIRE_SPREAD := 35.0
## Cuánto varía la duración de una llama a otra (0 todas iguales, 1 el máximo).
const FIRE_LIFE_RANDOM := 0.45
## La vida del color: amarillo, naranja, rojo oscuro y NEGRO OPACO, que recién al final se desvanece. Los momentos
## (`FIRE_LIFE_AT`) son desparejos a propósito: el amarillo y el naranja son el arranque, y el último tercio es la
## llama apagándose en negro —que es la parte que hay que ver, no un parpadeo antes de desaparecer—.
##
## SON MUCHAS PARADAS, Y ESE ES EL PUNTO. Cada partícula es un color plano —así se quiere—, pero a una columna le
## entran decenas de edades distintas a la vez: cuantos más escalones tiene la vida, más tonos conviven en el
## mismo momento y menos se lee como una mancha de un solo color. El volumen sale de ahí, de la mezcla, no de
## sombrear cada llama.
##
## Y EL DESVANECIDO ES TARDÍO: el negro se queda opaco hasta bien avanzada la vida (alfa 1 a 0.74, todavía 0.8 a
## 0.9) y recién ahí se va. La llama que se apaga dura, en vez de diluirse desde la mitad.
const FIRE_LIFE: Array[Color] = [Color(1.0, 0.98, 0.72, 1.0), Color(1.0, 0.93, 0.42, 1.0),
	Color(1.0, 0.72, 0.18, 1.0), Color(1.0, 0.48, 0.09, 1.0), Color(0.78, 0.22, 0.04, 1.0),
	Color(0.42, 0.1, 0.03, 1.0), Color(0.16, 0.11, 0.09, 1.0), Color(0.09, 0.08, 0.08, 0.8),
	Color(0.07, 0.07, 0.07, 0.0)]
const FIRE_LIFE_AT: Array[float] = [0.0, 0.08, 0.18, 0.3, 0.44, 0.58, 0.74, 0.9, 1.0]


static func fire(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(FIRE_SPEED, FIRE_SPREAD, FIRE_RISE, SMOKE_MOUTH * 2.0 * size)
	# Sube y se va con el viento: la gravedad es del mundo, así que da igual cómo esté girado el emisor.
	process.gravity = Vector3(FIRE_WIND.x, FIRE_RISE, FIRE_WIND.z)
	# Poco freno: con el de los humos la llama se quedaría quieta en vez de subir. Algo hay, para que la columna no
	# se dispare al cielo a lo largo de toda su vida.
	process.damping_min = 0.6
	process.damping_max = 1.4
	process.turbulence_enabled = true
	process.turbulence_noise_strength = FIRE_TURBULENCE
	process.turbulence_noise_scale = FIRE_TURBULENCE_SCALE
	_size(process, FIRE_SIZE_MIN * size, FIRE_SIZE_MAX * size, FIRE_GROWTH)
	process.color_ramp = _life(FIRE_LIFE, FIRE_LIFE_AT)
	process.lifetime_randomness = FIRE_LIFE_RANDOM
	var emitter := _emitter(kind, FIRE_AMOUNT, FIRE_LIFETIME, process)
	# Caja propia: la de cualquier emisor es larga hacia atrás y baja, y esta columna sube unos 9 m (`FIRE_RISE`
	# por la vida al cuadrado) — con la de siempre, la punta se recorta al salir la boca de cuadro. Es un cubo
	# alrededor del emisor, y no una caja alta, porque la subida es del mundo y el emisor puede estar girado.
	emitter.visibility_aabb = AABB(Vector3(-12.0, -12.0, -12.0), Vector3(24.0, 24.0, 24.0))
	return emitter


# ── EXPLOSIÓN: EL DESTELLO ───────────────────────────────────────────────────────────────────────

## La bola: unas pocas esferas grandes que se inflan de golpe. LO QUE SE VE ES EL AMARILLO: se lleva la mayor parte
## de la vida (`FLASH_LIFE_AT`), el paso a gris oscuro es de un salto, y el gris es una cola corta que se apaga
## enseguida —si el gris dura más que el amarillo deja de parecer una explosión y parece humo—. El humo que queda
## después no es de acá, lo pone quien arma la explosión (`failing_smoke`). De ráfaga: sale entera de una vez
## (`one_shot`) y se dispara con `restart()`.
const FLASH_AMOUNT := 3
const FLASH_LIFETIME := 0.38
const FLASH_SPEED := 1.0
const FLASH_SIZE_MIN := 1.6
const FLASH_SIZE_MAX := 2.6
## Cómo crece la bola: arranca chica, se infla de golpe en el primer cuarto de su vida y ya no se achica —una bola
## que se desinfla no golpea—.
const FLASH_CURVE: Array[Vector2] = [Vector2(0.0, 0.25), Vector2(0.25, 1.0), Vector2(1.0, 0.9)]
const FLASH_LIFE: Array[Color] = [Color(1.0, 0.98, 0.7, 1.0), Color(1.0, 0.85, 0.3, 1.0),
	Color(1.0, 0.6, 0.1, 1.0), Color(0.28, 0.26, 0.25, 0.8), Color(0.15, 0.15, 0.16, 0.0)]
## En qué momento de la vida va cada uno de esos colores: amarillo hasta bien entrada la vida, y el gris, al final.
const FLASH_LIFE_AT: Array[float] = [0.0, 0.25, 0.5, 0.66, 1.0]


static func explosion_flash(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(FLASH_SPEED, 180.0, 0.0, 0.4 * size)
	process.scale_min = FLASH_SIZE_MIN * size
	process.scale_max = FLASH_SIZE_MAX * size
	process.scale_curve = _curve(FLASH_CURVE)
	process.color_ramp = _life(FLASH_LIFE, FLASH_LIFE_AT)
	return _burst(_emitter(kind, FLASH_AMOUNT, FLASH_LIFETIME, process))


# ── EXPLOSIÓN: LAS CHISPAS ───────────────────────────────────────────────────────────────────────

## Tiritas amarillas que salen para todos lados, se frenan y caen. La malla LÍNEA se alinea sola con la velocidad,
## así cada chispa va a lo largo de su trayectoria. De ráfaga, como el destello.
const SPARK_AMOUNT := 48
const SPARK_LIFETIME := 0.65
const SPARK_SPEED := 16.0
const SPARK_LIFE_RANDOM := 0.5
## Largo de una chispa (m); el ancho sale de la malla (ParticleMeshes.LINE_WIDTH).
const SPARK_SIZE_MIN := 0.35
const SPARK_SIZE_MAX := 0.75
const SPARK_LIFE: Array[Color] = [Color(1.0, 0.95, 0.55, 1.0), Color(1.0, 0.62, 0.15, 1.0),
	Color(0.7, 0.15, 0.03, 0.0)]


static func explosion_sparks(kind := ParticleMeshes.Kind.LINE, size := 1.0) -> GPUParticles3D:
	# Todas nacen casi del mismo punto: así se ve que salen del centro, cada una apuntando adonde va.
	var process := _process(SPARK_SPEED, 180.0, -9.8, 0.08 * size)
	process.initial_velocity_min = SPARK_SPEED * 0.35
	process.damping_min = 0.5
	process.damping_max = 2.0
	process.scale_min = SPARK_SIZE_MIN * size
	process.scale_max = SPARK_SIZE_MAX * size
	process.color_ramp = _life(SPARK_LIFE)
	process.lifetime_randomness = SPARK_LIFE_RANDOM
	return _burst(_emitter(kind, SPARK_AMOUNT, SPARK_LIFETIME, process))


# ── POLVO DE GOLPE ───────────────────────────────────────────────────────────────────────────────

## LA BOCANADA DE UN GOLPE: lo que suelta un paquete cuando se cae y se daña (ver PackageDamage). De
## RÁFAGA, porque es un evento y no un chorro, y abriéndose para TODOS LADOS en vez de salir en una
## dirección: lo que se golpeó está ahí y el polvo sale de alrededor suyo, no de una boquilla. Es el
## único sistema del catálogo al que no le importa cómo esté orientado.
##
## Es el humo del propulsor con otros números, y eso es a propósito (ver las reglas de arriba): un
## sistema nuevo usa el mismo material y las mismas tres mallas, no una familia aparte. Lo que lo hace
## OTRO son tres cosas y se leen a simple vista: es SECO Y CORTO —sale, se frena enseguida y en vez de
## subir cae un poco—, es MÁS CLARO, porque es polvo y no hollín, y es CHICO, porque sale de una caja
## que se golpeó y no de una tobera.
const DUST_AMOUNT := 18
const DUST_LIFETIME := 0.9
const DUST_SPEED := 1.6
## Negativo: cae en vez de subir. Es polvo con peso, no humo caliente.
const DUST_RISE := -0.5
const DUST_SIZE_MIN := 0.10
const DUST_SIZE_MAX := 0.26
const DUST_GROWTH := 2.2
## De dónde nace: una bola alrededor del punto del golpe, no una boca.
const DUST_MOUTH := 0.18
## Se frena mucho más que el humo (que usa 1–2): un golpe es un "puf" en el lugar, no una estela.
const DUST_DAMPING_MIN := 3.0
const DUST_DAMPING_MAX := 5.0
## Tierra clara, como el humo pero sin hollín.
const DUST_TONES: Array[Color] = [Color(0.78, 0.75, 0.70, 0.30), Color(0.64, 0.61, 0.56, 0.45),
	Color(0.48, 0.45, 0.42, 0.55)]
const DUST_FADE_IN := 0.10


static func impact_dust(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(DUST_SPEED, 180.0, DUST_RISE, DUST_MOUTH * size)
	_size(process, DUST_SIZE_MIN * size, DUST_SIZE_MAX * size, DUST_GROWTH)
	process.damping_min = DUST_DAMPING_MIN
	process.damping_max = DUST_DAMPING_MAX
	process.color_initial_ramp = _tones(DUST_TONES)
	process.alpha_curve = _curve([Vector2(0.0, 0.0), Vector2(DUST_FADE_IN, 1.0), Vector2(1.0, 0.0)])
	return _burst(_emitter(kind, DUST_AMOUNT, DUST_LIFETIME, process))


# ── VAPOR ────────────────────────────────────────────────────────────────────────────────────────

## UN CHORRO DE VAPOR: lo que escupe una manguera de vapor desenchufada (ver WallPatch). Blanco, rápido y angosto al
## salir; se frena enseguida, se infla mucho, sube un poco y se desvanece. A diferencia de los otros, en chico ESCALA
## TAMBIÉN SU VELOCIDAD: es un chorro, y el de una manguerita es corto —con la velocidad de uno grande cruzaría el tablero.
const STEAM_AMOUNT := 60
const STEAM_LIFETIME := 0.9
const STEAM_SPEED := 3.2
const STEAM_RISE := 1.2
const STEAM_SIZE_MIN := 0.08
const STEAM_SIZE_MAX := 0.14
const STEAM_GROWTH := 4.5
const STEAM_SPREAD := 9.0
const STEAM_MOUTH := 0.04
## Blanco y bastante opaco al salir —tiene que notarse—, y se desvanece mientras se infla: no tapa la vista.
const STEAM_TONES: Array[Color] = [Color(0.98, 0.98, 0.98, 0.75), Color(0.92, 0.93, 0.95, 0.65),
	Color(0.85, 0.86, 0.89, 0.5)]
const STEAM_FADE_IN := 0.06


static func steam(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(STEAM_SPEED * size, STEAM_SPREAD, STEAM_RISE * size, STEAM_MOUTH * size)
	_size(process, STEAM_SIZE_MIN * size, STEAM_SIZE_MAX * size, STEAM_GROWTH)
	process.damping_min = 3.0 * size
	process.damping_max = 5.0 * size
	process.color_initial_ramp = _tones(STEAM_TONES)
	process.alpha_curve = _curve([Vector2(0.0, 0.0), Vector2(STEAM_FADE_IN, 1.0), Vector2(1.0, 0.0)])
	return _emitter(kind, STEAM_AMOUNT, STEAM_LIFETIME, process)


# ── HUMO DE CHIMENEA ─────────────────────────────────────────────────────────────────────────────

## EL HUMO DE UNA CHIMENEA INDUSTRIAL: bocanadas grandes y lentas que salen de la boca, suben y se van corriendo con
## el viento mientras crecen y se aclaran. Grises sucios, de a pocas: es una columna que se lee de lejos, no una
## nube. ⚠ EN COORDENADAS LOCALES, a diferencia de los otros: lo que lo emite no se mueve nunca, y así la columna
## escala con lo que la lleva —en la maqueta del sandbox la ciudad entera va a escala—.
const CHIMNEY_AMOUNT := 26
const CHIMNEY_LIFETIME := 7.0
const CHIMNEY_SPEED := 1.6
const CHIMNEY_RISE := 0.9
const CHIMNEY_WIND := Vector3(0.45, 0.0, 0.2)
const CHIMNEY_SIZE_MIN := 1.4
const CHIMNEY_SIZE_MAX := 2.4
const CHIMNEY_GROWTH := 3.2
const CHIMNEY_SPREAD := 12.0
const CHIMNEY_TONES: Array[Color] = [Color(0.42, 0.41, 0.4, 0.75), Color(0.55, 0.54, 0.53, 0.6),
	Color(0.33, 0.32, 0.31, 0.8)]
const CHIMNEY_FADE_IN := 0.08


static func chimney_smoke(kind := ParticleMeshes.Kind.SPHERE, size := 1.0) -> GPUParticles3D:
	var process := _process(CHIMNEY_SPEED * size, CHIMNEY_SPREAD, CHIMNEY_RISE * size, 0.4 * size)
	process.gravity = Vector3(CHIMNEY_WIND.x, CHIMNEY_RISE, CHIMNEY_WIND.z) * size
	process.damping_min = 0.2
	process.damping_max = 0.4
	_size(process, CHIMNEY_SIZE_MIN * size, CHIMNEY_SIZE_MAX * size, CHIMNEY_GROWTH)
	process.color_initial_ramp = _tones(CHIMNEY_TONES)
	process.alpha_curve = _curve([Vector2(0.0, 0.0), Vector2(CHIMNEY_FADE_IN, 1.0), Vector2(1.0, 0.0)])
	process.lifetime_randomness = 0.3
	var emitter := _emitter(kind, CHIMNEY_AMOUNT, CHIMNEY_LIFETIME, process)
	emitter.local_coords = true
	emitter.visibility_aabb = AABB(Vector3(-20.0, -20.0, -60.0) * size, Vector3(40.0, 40.0, 70.0) * size)
	return emitter


# ── CHISPAZO ─────────────────────────────────────────────────────────────────────────────────────

## UN CHISPAZO: la chispa chica de un cable que se enchufa o se desenchufa (ver PatchBoard). Pocas tiritas blancas y
## amarillas que salen en un abanico angosto —no para todos lados como las de la explosión—, viven un instante y caen.
## EXAGERADO a propósito: sutil, se leía como ruido y no como algo que pasó. Como el vapor, en chico ESCALA TAMBIÉN SU VELOCIDAD: el chispazo de un conector es corto. De ráfaga.
const ZAP_AMOUNT := 30
const ZAP_LIFETIME := 0.5
const ZAP_SPEED := 7.0
const ZAP_SPREAD := 55.0
const ZAP_FALL := -8.0
const ZAP_SIZE_MIN := 0.1
const ZAP_SIZE_MAX := 0.24
const ZAP_LIFE: Array[Color] = [Color(1.0, 1.0, 0.85, 1.0), Color(1.0, 0.85, 0.35, 1.0), Color(1.0, 0.5, 0.1, 0.0)]


static func zap(kind := ParticleMeshes.Kind.LINE, size := 1.0) -> GPUParticles3D:
	var process := _process(ZAP_SPEED * size, ZAP_SPREAD, ZAP_FALL * size, 0.02 * size)
	process.initial_velocity_min = ZAP_SPEED * size * 0.4
	process.damping_min = 2.0 * size
	process.damping_max = 4.0 * size
	process.scale_min = ZAP_SIZE_MIN * size
	process.scale_max = ZAP_SIZE_MAX * size
	process.color_ramp = _life(ZAP_LIFE)
	process.lifetime_randomness = 0.5
	return _burst(_emitter(kind, ZAP_AMOUNT, ZAP_LIFETIME, process))


# ── LO COMÚN ─────────────────────────────────────────────────────────────────────────────────────

## El arranque de cualquiera: sale hacia el −Z del emisor a `speed` (m/s), abriéndose `spread` grados, con `rise`
## de gravedad hacia arriba (negativo, cae) y naciendo en una bola de radio `mouth`.
static func _process(speed: float, spread: float, rise: float, mouth: float) -> ParticleProcessMaterial:
	var process := ParticleProcessMaterial.new()
	process.direction = Vector3.FORWARD
	process.spread = spread
	process.initial_velocity_min = speed * 0.7
	process.initial_velocity_max = speed
	process.gravity = Vector3(0.0, rise, 0.0)
	process.damping_min = 1.0
	process.damping_max = 2.0
	process.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	process.emission_sphere_radius = mouth
	return process


## El tamaño de una partícula (m) y cuánto crece con la edad.
static func _size(process: ParticleProcessMaterial, minimum: float, maximum: float, growth: float) -> void:
	process.scale_min = minimum
	process.scale_max = maximum
	process.scale_curve = _curve([Vector2(0.0, 1.0), Vector2(1.0, growth)], growth)


## Un emisor con las reglas de arriba: la malla estándar de `kind`, en el mundo, sin interpolar y apagado.
static func _emitter(kind: ParticleMeshes.Kind, amount: int, lifetime: float,
		process: ParticleProcessMaterial) -> GPUParticles3D:
	process.particle_flag_align_y = ParticleMeshes.aligns_to_velocity(kind)
	var emitter := GPUParticles3D.new()
	# DE ATRÁS PARA ADELANTE cuando la malla escribe profundidad (la esfera, ver ParticleMeshes.writes_depth). El
	# orden por defecto es el de nacimiento, y con el z-buffer puesto una partícula lejana dibujada tarde se borra
	# contra una cercana en vez de mezclarse detrás. Ordenadas por profundidad, atravesarse se ve como tiene que
	# verse. Las otras dos mallas no lo necesitan y no lo pagan.
	if ParticleMeshes.writes_depth(kind):
		emitter.draw_order = GPUParticles3D.DRAW_ORDER_VIEW_DEPTH
	emitter.amount = amount
	emitter.lifetime = lifetime
	emitter.local_coords = false
	emitter.interpolate = false
	emitter.fixed_fps = 0
	emitter.emitting = false
	emitter.process_material = process
	emitter.draw_pass_1 = ParticleMeshes.mesh(kind)
	emitter.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Lo que ya se soltó queda en el mundo, atrás de lo que lo emitió: la caja de visibilidad lo cubre, que si no
	# se recorta en cuanto la boca sale de cuadro.
	emitter.visibility_aabb = AABB(Vector3(-8.0, -4.0, -40.0), Vector3(16.0, 12.0, 44.0))
	return emitter


## De ráfaga: todas juntas, una sola vez. Se dispara con `restart()`.
static func _burst(emitter: GPUParticles3D) -> GPUParticles3D:
	emitter.one_shot = true
	emitter.explosiveness = 1.0
	emitter.visibility_aabb = AABB(Vector3(-12.0, -12.0, -12.0), Vector3(24.0, 24.0, 24.0))
	return emitter


## Una curva en una textura, como la piden los materiales de partículas.
static func _curve(points: Array, max_value := 1.0) -> CurveTexture:
	var curve := Curve.new()
	curve.max_value = max_value
	for p: Vector2 in points:
		curve.add_point(p)
	var texture := CurveTexture.new()
	texture.curve = curve
	return texture


## LOS TONOS de un sistema: cada partícula saca UNO al azar, con su opacidad, y lo tiene toda su vida.
static func _tones(tones: Array[Color]) -> GradientTexture1D:
	return _gradient(tones)


## LA VIDA de color de un sistema: todas las partículas pasan por estos colores y opacidades mientras envejecen.
## Repartidos parejo, o en los momentos que diga `at` (0 recién nacida, 1 al morir) cuando un color tiene que durar
## un instante y otro todo el resto.
static func _life(colors: Array[Color], at: Array[float] = []) -> GradientTexture1D:
	return _gradient(colors, at)


static func _gradient(colors: Array[Color], at: Array[float] = []) -> GradientTexture1D:
	var offsets := PackedFloat32Array()
	var ramp := PackedColorArray()
	for i in colors.size():
		offsets.append(at[i] if i < at.size() else float(i) / maxf(colors.size() - 1, 1))
		ramp.append(colors[i])
	var gradient := Gradient.new()
	gradient.offsets = offsets
	gradient.colors = ramp
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	return texture
