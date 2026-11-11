class_name PhysicsLayers
extends RefCounted

## LAS CAPAS DE FÍSICA CON NOMBRE que el código usa por número (ver project.godot, `layer_names`).

## La de la ESCALERITA de la nave (3d_physics/layer_11 "Escalerita"): choca SOLO CON LOS JUGADORES —la ven la cápsula
## y sus rayos—, así no la atraviesa nadie que la pise y no la ve el tráfico.
const STEP := 1 << 10

## ── LA CÁPSULA VE UNA RAMPA Y LOS PIES ESCALONES (05/11/2026, el dios del juego: «una escalera con hitbox de rampa
## para la cápsula, pero con hitbox por escalones para los raycasts») ───────────────────────────────────────────────
## RAMP (13, "Rampa"): la ven sólo la cápsula y su rayo de piso. FEET (14, "Escalones"): la ven sólo los rayos de los
## pies y el ragdoll. Así el cuerpo —la física, el juego— baja por una rampa sin despegarse, y los pies pisan cada
## escalón. Ver LocomotionLabArchetype, BAJAR LA ESCALERA.
const RAMP := 1 << 12
const FEET := 1 << 13

## ── EL BORDE DE CADA PARCELA DEL SANDBOX (06/11/2026, el dios del juego: «ningún tipo de objeto físico… puede salir de
## las boundaries de una parcela… unas paredes que suban bastante… solamente útiles para las cosas que estén adentro… y
## no para mí»; «20 m de alto me sirve») ──────────────────────────────────────────────────────────────────────────────
## PARCEL_BOUND (16, "Borde de parcela"): la de las paredes invisibles alrededor de la zona de adentro de cada parcela
## (SandboxParcel, LOS BORDES). La ve sólo lo que vive en una parcela —se le suma al aparecer—; el jugador no.
const PARCEL_BOUND := 1 << 15

## *La 12 era la de lo que llevaba al ente (RIDE) hasta el 03/11/2026: la reemplazó la del Marco (MotionFrame.LAYER).*
