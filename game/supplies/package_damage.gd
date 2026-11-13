class_name PackageDamage
extends SoundEntity

## EL DAÑO DE UN OBJETO AGARRABLE: cuelga del cuerpo, mide los golpes que recibe, le baja la durabilidad
## y lo muestra OSCURECIÉNDOLO; cuando llega a cero avisa que se rompió. Es el modelo de
## conceptual/objects.md —la durabilidad arranca en 1.0, cada golpe por encima de un umbral le resta, los
## golpecitos no cuentan, y la fragilidad dice cuánto resta cada uno—, sin la parte de valor y entrega,
## que todavía no existe.
##
## ── CÓMO SE MIDE UN GOLPE: POR IMPULSO DE CONTACTO ──────────────────────────────────────────────
## Cada cuadro se suman los impulsos de los contactos del cuerpo y se divide por su masa: eso da los
## METROS POR SEGUNDO que el choque le cambió a la velocidad, que es exactamente "qué tan fuerte lo
## golpearon" y no depende de quién lo empujaba.
##
## Medido con Jolt a 240 Hz, caja fuerte de 150 kg cayendo de 3 m: el cuadro del golpe reporta 1073 N·s,
## o sea **7.16 m/s**; el cuadro siguiente 0.98 (el cuerpo asentándose) y después, apoyada y quieta,
## **0.041 m/s por cuadro para siempre** — que es su propio peso sostenido (150 · 9.8 / 240 = 6.12 N·s,
## exacto). O sea que el reposo y un golpe de verdad están separados por un factor de 175: un umbral en
## el medio los distingue sin ninguna cuenta extra.
##
## ⚠ POR QUÉ NO SE MIDE CON Δv DE LA VELOCIDAD, que es como lo hace el personaje
## (`CharacterRigidBody3D._detect_external_impact`): a un paquete lo mueve el solver del agarre con
## fuerzas grandes (`GrabbableInteractable`), así que su Δv crudo está lleno de aceleración que NO es un
## golpe, y habría que restarle la fuerza aplicada igual que hace el personaje con la suya. El impulso de
## contacto ya viene limpio: sostener algo no genera contactos, y estrellarlo contra una pared sí. Es la
## diferencia entre tener que saber quién lo empujaba y no tener que saberlo.

## Debajo de esto un golpe no cuenta. En m/s de velocidad que el choque le sacó al cuerpo (ver arriba).
## 2.0 deja pasar el apoyarlo, el arrastrarlo y el empujón de un compañero, y toma una caída de medio
## metro (3.1 m/s) para arriba. El peso apoyado da 0.041, o sea 50 veces menos.
const IMPACT_THRESHOLD := 2.0
## El golpe que destruye de una a un objeto de fragilidad 1.0, en m/s por encima del umbral. Con 8.0,
## una caída de 3 m (7.16 m/s) le saca 0.64 al televisor y 0.05 a la caja fuerte: el televisor aguanta
## dos y la caja fuerte diecinueve. ES EL NÚMERO A TOCAR si el daño se siente injusto.
const DAMAGE_SCALE := 8.0
## Cuánto queda del color con la durabilidad en cero. No es 0: un paquete negro no se lee como roto sino
## como un agujero, y además hay que seguir viendo de qué objeto se trata.
const DARKEST := 0.3
## Un golpe por vez: después de contar uno se ignoran los contactos por este rato, porque un choque real
## reparte impulso en dos o tres cuadros y cada uno pasaría el umbral por su cuenta.
const COOLDOWN_S := 0.25
## LA CAÍDA DE REFERENCIA, en metros: con qué golpe se habla de la fragilidad de un objeto. No cambia
## nada del daño — es la unidad en la que `PackageArchetype.falls_to_break` dice cuánto aguanta cada uno,
## y la que el test usa para tirarlos. Está acá y no allá para que el número con el que se cuenta y el
## número con el que se promete sean el mismo.
const FALL_REFERENCE_M := 3.0

## ── Y SUENA: EL GOLPE EN DOS CAPAS (ver SoundEntity) ────────────────────────────────────────────────────────────
## El cuerpo que pega (`golpe_paquete`, de todos) y su MATERIAL (`golpe_madera`…), juntos; más fuerte cuanto más fuerte
## el golpe, hasta HIT_LOUD. Suena también roto: un paquete roto sigue siendo algo que cae.
const MATERIALS: Array[StringName] = [&"madera", &"metal", &"vidrio", &"tela", &"ceramica"]
const SOUNDS := {
	&"hit_madera": [&"golpe_paquete", &"golpe_madera"],
	&"hit_metal": [&"golpe_paquete", &"golpe_metal"],
	&"hit_vidrio": [&"golpe_paquete", &"golpe_vidrio"],
	&"hit_tela": [&"golpe_paquete", &"golpe_tela"],
	&"hit_ceramica": [&"golpe_paquete", &"golpe_ceramica"],
}
## El golpe, en m/s, que suena a pleno; el umbral suena a un cuarto.
const HIT_LOUD := 8.0

## De qué es (ver MATERIALS): lo pone el arquetipo.
var material: StringName = &"madera"


func sounds() -> Dictionary:
	return SOUNDS


## Cuánto resta cada golpe, en múltiplos. 1.0 es frágil (se rompe en dos caídas), 0.1 es casi
## indestructible. Lo pone el arquetipo (ver PackageArchetype).
var fragility := 1.0
## 1.0 entero, 0.0 destruido.
var durability := 1.0

## Cada vez que cambia la durabilidad, con el valor nuevo. Lo escucha la jornada (Jornada), que lleva la del
## lote al anfitrión: en cero, el paquete se pierde porque se rompió.
signal changed(value: float)
## Llegó a cero. Quien lo escucha decide qué hacer con el cuerpo; hoy, sólo el test de los paquetes, que cuenta
## las caídas (la jornada se entera por `changed`).
signal destroyed()

var _body: RigidBody3D = null
## El polvo del golpe, creado la primera vez que hace falta: un objeto que nunca se golpea no paga un
## emisor. Se dispara con `restart()`, como el resto de las ráfagas (ver ParticleSystems).
var _dust: GPUParticles3D = null
var _cooldown := 0.0
var _destroyed := false


func _ready() -> void:
	_body = get_parent() as RigidBody3D
	if not is_instance_valid(_body):
		set_physics_process(false)
		return
	# El monitor de contactos es lo que hace que el estado del cuerpo traiga los impulsos. Sin esto
	# `get_contact_count()` da 0 siempre y el daño no se enteraría de nada.
	_body.contact_monitor = true
	_body.max_contacts_reported = maxi(_body.max_contacts_reported, 4)


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if _cooldown > 0.0 or not is_instance_valid(_body):
		return
	var hit := _impact_speed()
	if hit <= IMPACT_THRESHOLD:
		return
	_cooldown = COOLDOWN_S
	play_sound(StringName("hit_%s" % material), _body, 1.0, clampf(hit / HIT_LOUD, 0.25, 1.0))
	if not _destroyed:
		_apply(fragility * (hit - IMPACT_THRESHOLD) / DAMAGE_SCALE)


## LO DEJA SANO: la durabilidad entera, el color de vuelta. Para lo que lo vuelve a usar (los paquetes que caen de la
## fila Sonidos, ver SoundCauses).
func reset() -> void:
	durability = 1.0
	_destroyed = false
	_cooldown = 0.0
	_tint()


## Qué tan fuerte lo golpearon este cuadro, en m/s. Ver el bloque de arriba.
func _impact_speed() -> float:
	var state := PhysicsServer3D.body_get_direct_state(_body.get_rid())
	if state == null or state.get_contact_count() == 0:
		return 0.0
	var impulse := Vector3.ZERO
	for i in state.get_contact_count():
		impulse += state.get_contact_impulse(i)
	return impulse.length() / maxf(_body.mass, 0.001)


func _apply(amount: float) -> void:
	durability = maxf(durability - amount, 0.0)
	_tint()
	_puff()
	changed.emit(durability)
	if durability > 0.0:
		return
	_destroyed = true
	destroyed.emit()


## LO OSCURECE, que es por ahora toda la lectura del daño: las piezas del bosquejo comparten un shader
## con un uniforme `damage`, y subirlo les apaga el color sin tocar la malla ni el material de cada una
## (ver PackageArchetype.SHADER). Un objeto a medio romper se ve sucio; roto, casi negro.
func _tint() -> void:
	PackageArchetype.set_damage(_body, 1.0 - durability)


## LA BOCANADA DE POLVO del golpe (ParticleSystems.impact_dust). Sale del centro del cuerpo y no del
## punto de contacto: el punto de contacto hay que pedírselo al estado del cuerpo y cambia de cuadro a
## cuadro, y a 18 partículas que se abren para todos lados desde adentro de la caja no se nota la
## diferencia — lo que se lee es "esto se golpeó", no dónde.
func _puff() -> void:
	if not is_instance_valid(_dust):
		_dust = ParticleSystems.impact_dust()
		_dust.name = "polvo"
		_body.add_child(_dust)
	_dust.restart()
	_dust.emitting = true

