# La estructura del código

Para enterarse de cómo está armado y criticarlo. El detalle de cada pieza está en el comentario largo con que empieza
su archivo.

**El 17/11/2026 se borró la meca grande** (el usuario: «tal vez convenga… borrar todo el sistema de la meca grande…
limitarnos solamente a un approach de meca a una escala más humana, que es la de ahora»): sus cabinas (la cuadrada con
su trama, la redonda, la del vórtice, la de cápsulas, la maqueta por módulos), sus filas (la Meca de tres, la discreta,
la física, la cinemática, el laboratorio cinemático, la arena de esquivar, el brazo suelto, el cubo con piernas
archivado), sus paneles, sus tests y sus notas. Queda una sola meca, **la jaula** ([[meca-jaula]]). Todo lo borrado
está en el commit **`0bcaeaf`**.

## El cuerpo con equilibrio — `game/balance_body/` (la base común)
**Lo que comparten la meca propia y los jefes**: un solo cuerpo, una caja, con su equilibrio. Ver [[base-comun]].

| Archivo | Clase | Qué es |
|---|---|---|
| `balance_body.gd` | `BalanceBody` | La caja (`size`, la masa) y **su equilibrio, el péndulo**: el apoyo, caerse, volver. Lo que se le pide (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`). Arma sus piezas y las llama en orden; cada uno agrega lo suyo con tres ganchos: `_build` (sus piezas), `_think` (escribe lo que se le pide) y `_after_step`. |
| `kinematic_mover.gd`, `kinematic_settings.gd`, `stomp_feet.gd` | `KinematicMover`, `KinematicSettings`, `StompFeet` | **El motor discreto** (`BalanceBody.kinematic`): el controlador de personaje del motor contra lo fijo, sus perillas y los pies con choque. Es como se mueve la jaula. |
| `body_legs.gd` | `BodyLegs` | La pelvis (un cilindro) y dos piernas debajo de la caja: dibujo. Los pasos nuevos (el sistema clásico, `LegSettings`, F4) o los de largo fijo de antes. Otro medio de moverse es otra pieza. |
| `body_nozzles.gd` | `BodyNozzles` | Las toberas, invisibles: levantarse cuando se cae, y el propulsor. |
| `body_moves.gd` | `BodyMoves` | Caminar, correr, agacharse, el salto cargado, el propulsor (la física). |
| `body_settings.gd` | `BodySettings` | Todas sus perillas, en un recurso (`BalanceBody.knobs`; por defecto el de la meca). |
| `move_curve.gd`, `move_ramp.gd` | `MoveCurve`, `MoveRamp` | Las curvas de los movimientos discretos (las usan el dash y el Luchador). |

Usa de `game/mech/` las medidas y la pierna (`MechBody`, `MechLeg`) y la arcilla (`Clay`).

## La meca propia — `game/mech/`, `game/tool_mech/`
`Mech` hereda de `BalanceBody` y agrega lo suyo; `ToolMech` le agrega las herramientas y `CageMech` es la jaula. *Hasta
el 13/11/2026 eran tres clases una arriba de la otra (el cubo, el cubo péndulo, la meca péndulo); ese día se aplanaron y
después se separó el cuerpo con equilibrio, para los jefes.*

| Archivo | Clase | Qué es |
|---|---|---|
| `mech.gd` | `Mech` | La meca propia: el cuerpo con equilibrio más su cabina, sus teclas y sus brazos (`arms_kind`: ninguno o los de su `loadout`). Poseerla. Sin brazos, la de práctica. |
| `mech_cabin.gd` | `MechCabin` | Lo de toda cabina: las sillas y sus maniquíes, y **el marco** que lleva a los de adentro. |
| `mech_keys.gd` | `MechKeys` | **El único lugar que lee teclas**: el teclado y el mouse de quien la posee, y su cámara. |
| `mech_arm.gd` | `MechArm` | Lo que se le pide a un brazo (posturas, piñas, la pose, la mano). Base de los dos brazos. |
| `mech_hand.gd` | `MechHand` | La mano (izquierda o derecha, en espejo). |
| `mech_body.gd` | `MechBody` | Las medidas del cuerpo y la IK de una pierna y de un brazo. |
| `mech_leg.gd` | `MechLeg` | Una pierna (dibujo). |
| `mech_archetype.gd` | `MechArchetype` | Las reglas de toda parcela con la meca: sus teclas (la bola, U subirse, N/M pegarle) y los tiros de la bola. |
| `mech_rows.gd` | `MechRows` | Las filas de la meca en el sandbox (la Meca jaula). |
| `arms_panel.gd`, `knobs_panel.gd`, `knobs_file.gd` | `ArmsPanel`, `KnobsPanel`, `KnobsFile` | El panel de los brazos (F3) y lo de todo panel de perillas (ver [[base-comun]]). |
| `clay.gd` | `Clay` | La arcilla de los bocetos: cajas, cilindros, esferas, miembros. |
| `cage/` | `CageMech`, `CageCabin`, `CageShape`… | **La meca jaula**: su cabina, su forma (F2), sus teclas, su F1, subirse con la E. Ver [[meca-jaula]]. |
| `arm_tips/` | `ArmTip`, `ArmLoadout`, `EquipmentPanel`… | Lo que lleva cada brazo en la punta y el equipamiento (F5). Ver [[brazo]]. |
| `boards/` | `FaceBoard`, `FaceMount`, `FoldingArm` | Las caras con tablero. Ver [[tableros]]. |
| `../tool_mech/` | `ToolMech`, `ToolMechKeys`, `MechEnergy`, `EnergyBolt` | La meca con herramientas (la base de la jaula): la energía común, sus teclas, los tiros. |

### Las tres reglas que la ordenan
1. **Lo que se le pide está separado de quién lo pide.** El cuerpo tiene variables (`move`, `sprint`, `crouch`,
   `jump`, `aim_yaw`; la meca, además, `covering` y `punch()` en sus brazos). En la meca las escribe `MechKeys`;
   mañana, las consolas de adentro; en un jefe, su cerebro. Nada más lee teclas.
2. **La caja sólo se mueve con fuerzas e impulsos** (la física) **o con su motor** (la discreta): nunca a mano. Adentro
   y por afuera se camina.
3. **Una pieza, un archivo, un trabajo.** El cuerpo las llama en orden fijo en su paso: lo que se le pide, los
   movimientos, el equilibrio, las toberas, las piernas, y lo de cada uno (en la meca, los brazos y el marco).

## Los brazos
- `game/pose_arm/` · `PoseArm`: el discreto (el del cañón de la jaula).
- `game/muscle_arm/` · `MuscleArm`, con sus perillas (el del palo de la jaula).
Los dos heredan de `MechArm`; cada brazo de una meca elige el suyo (`ArmLoadout`). Ver [[brazo]].

## El sandbox — `game/sandbox/`
`DesignSandbox` (el que camina, en qué parcela está, sus teclas y qué panel F abre dónde), `SandboxCatalogue` (las
filas de cada módulo y el chequeo de las reglas), `SandboxRow` (una fila declarada), `SandboxSuper` (las
supercategorías), `SandboxKey` (una tecla del panel chico), `SandboxLayout` (dónde va cada fila en el piso),
`SandboxParcel`, `SandboxPanel` (el panel chico), `SeededArchetype`, `SandboxPossession` (poseer), `TestBall` (la bola).
Ver [[sandbox]], [[poseer]], [[filas]].

## Lo que vino de character-parametric
`game/character/`, `game/interactables/`, `game/net/`, `game/common/`, `game/debug/`… El personaje,
agarrar, sentarse, el marco (`MotionFrame`) y la red. **Ya es código de la meca**: se edita cuando hace falta. Sigue
entero como vino, con cosas de ciudad y de nave que acá no se usan: **es la segunda etapa de limpieza**, después de la
meca. Ver [[personajes-traidos]].

## Lo que todavía criticaría
- `MechKeys` mezcla tres cosas chicas: las teclas, la cámara de poseer y la cabeza del que va sentado. Cuando haya
  consolas, las teclas se van a ellas y queda la cámara.
- Con una sola meca, algunas costuras quedaron de más: `Mech.Cabin` y `cabin_kit` tienen una sola cabina; `ToolMech`
  es sólo la base de `CageMech`; `MechCabin`, de `CageCabin`. Se dejaron para no cambiar a la jaula en la limpieza.
- La física del péndulo (`BodyMoves`, `BodyNozzles`, `BodySettings`) hoy la usa sólo la meca de práctica.
- Las perillas de los brazos físicos (`MuscleArmSettings`) están aparte de `BodySettings`; las del discreto,
  en `PoseArmSettings`.
