class_name PhysicsLayers
extends RefCounted

## LAS CAPAS DE FÍSICA CON NOMBRE que el código usa por número (ver project.godot, `layer_names`).

## La de la ESCALERITA de la meca (3d_physics/layer_11 "Escalerita"): choca SOLO CON LOS JUGADORES —la ven la cápsula
## y sus rayos—, así no la atraviesa nadie que la pise y no la ve el tráfico.
const STEP := 1 << 10

## ── LA CÁPSULA VE UNA RAMPA Y LOS PIES ESCALONES (05/11/2026, el usuario: «una escalera con hitbox de rampa
## para la cápsula, pero con hitbox por escalones para los raycasts») ───────────────────────────────────────────────
## RAMP (13, "Rampa"): la ven sólo la cápsula y su rayo de piso. FEET (14, "Escalones"): la ven sólo los rayos de los
## pies y el ragdoll. Así el cuerpo —la física, el juego— baja por una rampa sin despegarse, y los pies pisan cada
## escalón. Ver LocomotionLabArchetype, BAJAR LA ESCALERA.
const RAMP := 1 << 12
const FEET := 1 << 13

## ── EL BORDE DE CADA PARCELA DEL SANDBOX (06/11/2026, el usuario: «ningún tipo de objeto físico… puede salir de
## las boundaries de una parcela… unas paredes que suban bastante… solamente útiles para las cosas que estén adentro… y
## no para mí»; «20 m de alto me sirve») ──────────────────────────────────────────────────────────────────────────────
## PARCEL_BOUND (16, "Borde de parcela"): la de las paredes invisibles alrededor de la zona de adentro de cada parcela
## (SandboxParcel, LOS BORDES). La ve sólo lo que vive en una parcela —se le suma al aparecer—; el jugador no.
const PARCEL_BOUND := 1 << 15

## *La 12 era la de lo que llevaba al ente (RIDE) hasta el 03/11/2026: la reemplazó la del Marco (MotionFrame.LAYER).*

## ── LO FIJO DEL MUNDO (13/11/2026, el usuario: «lo de las capas me parece bien… es como los juegos lidian con estos
## casos usualmente») ────────────────────────────────────────────────────────────────────────────────────────────────
## FIXED (17, "Fijo del mundo"): el piso, los edificios, las paredes: lo que no se mueve nunca. La mira lo que se mueve
## con el controlador de personaje del motor y SÓLO tiene que frenar contra el mundo (el cilindro de la meca cinemática,
## ver KinematicPillar): así no hay que distinguir a mano lo fijo de lo suelto. Lo fijo va ADEMÁS en su capa de siempre
## (`mark_fixed` le suma ésta): nada de lo que ya lo veía deja de verlo.
const FIXED := 1 << 16


## Marca `body` como fijo del mundo (ver FIXED), además de las capas que ya tenga.
static func mark_fixed(body: CollisionObject3D) -> void:
	body.collision_layer |= FIXED
