# La estructura del código

Para enterarse de cómo está armado y criticarlo. El detalle de cada pieza está en el comentario largo con que empieza
su archivo.

## El cuerpo con equilibrio — `game/balance_body/` (la base común)
**Lo que comparten la meca propia y los jefes**: un solo cuerpo físico, una caja, con su equilibrio. Ver
[[base-comun]].

| Archivo | Clase | Qué es |
|---|---|---|
| `balance_body.gd` | `BalanceBody` | La caja (`size`, la masa) y **su equilibrio, el péndulo**: el apoyo, caerse, volver. Lo que se le pide (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`). Arma sus piezas y las llama en orden; cada uno agrega lo suyo con tres ganchos: `_build` (sus piezas), `_think` (escribe lo que se le pide) y `_after_step`. |
| `body_legs.gd` | `BodyLegs` | Dos piernas desde una pelvis debajo de la caja: dibujo. Los pasos nuevos (el sistema clásico, `LegSettings`, F4) o los de largo fijo de antes. Otro medio de moverse es otra pieza. |
| `body_nozzles.gd` | `BodyNozzles` | Las toberas: levantarse cuando se cae, y el propulsor. |
| `body_moves.gd` | `BodyMoves` | Caminar, correr, agacharse, el salto cargado, el propulsor. **Acá van los dashes y los propulsores de costado.** |
| `body_settings.gd` | `BodySettings` | Todas sus perillas, en un recurso (`BalanceBody.knobs`; por defecto el de la meca). |

Usa de `game/mech/` las medidas y la pierna (`MechBody`, `MechLeg`) y la arcilla (`Clay`).

## La meca propia — `game/mech/`
`Mech` hereda de `BalanceBody` y agrega lo suyo. *Hasta el 13/11/2026 eran tres clases una arriba de la otra (el cubo,
el cubo péndulo, la meca péndulo); ese día se aplanaron y después se separó el cuerpo con equilibrio, para los jefes.*

| Archivo | Clase | Qué es |
|---|---|---|
| `mech.gd` | `Mech` | La meca propia: el cuerpo con equilibrio más su cabina, sus teclas y sus brazos (`arms_kind`: ninguno, discretos o físicos). Poseerla. |
| `mech_cabin.gd` | `MechCabin` | Lo que se ve y por donde se camina: los tres pisos, el afuera, el ascensor y **el marco** que lleva a los de adentro. |
| `mech_exterior.gd` | `MechExterior` | La pasarela y la escalera de atrás (superficies pisables, altura libre medida, barandas donde hay caída). |
| `pelvis_lift.gd` | `PelvisLift` | El ascensor de la pelvis. |
| `mech_keys.gd` | `MechKeys` | **El único lugar que lee teclas**: el teclado y el mouse de quien la posee, y su cámara. |
| `mech_arm.gd` | `MechArm` | Lo que se le pide a un brazo (posturas, piñas, la pose, la mano). Base de los dos caminos. |
| `mech_hand.gd` | `MechHand` | La mano (izquierda o derecha, en espejo). |
| `mech_body.gd` | `MechBody` | Las medidas del cuerpo y la IK de una pierna y de un brazo. |
| `mech_leg.gd` | `MechLeg` | Una pierna (dibujo). |
| `mech_panel.gd` | `MechPanel` | El F1 (perillas, en pestañas; la física tiene las suyas). Pegarle y el ascensor son teclas del panel chico (`MechArchetype.knock_keys()`). |
| `mech_rows.gd` | `MechRows` | Las filas de la meca en el sandbox (Meca discreta, Meca física, Arena de esquivar). |
| `mech_archetype.gd` | `MechArchetype` | La parcela: la meca y una de práctica adelante. La usan las dos filas. |
| `clay.gd` | `Clay` | La arcilla de los bocetos: cajas, cilindros, esferas, miembros. |

### Las tres reglas que la ordenan
1. **Lo que se le pide está separado de quién lo pide.** El cuerpo tiene variables (`move`, `sprint`, `crouch`,
   `jump`, `aim_yaw`; la meca, además, `covering` y `punch()` en sus brazos). En la meca las escribe `MechKeys`;
   mañana, las consolas de adentro; en un jefe, su cerebro. Nada más lee teclas.
2. **La caja sólo se mueve con fuerzas e impulsos.** Caminar, saltar, las toberas, las piñas que recibe: todo es
   `apply_force` / `apply_impulse` sobre el cuerpo. Adentro y por afuera se camina.
3. **Una pieza, un archivo, un trabajo.** El cuerpo las llama en orden fijo en su paso: lo que se le pide, los
   movimientos, el equilibrio, las toberas, las piernas, y lo de cada uno (en la meca, los brazos y el marco).

## Los dos caminos — los brazos
- `game/pose_arm/` · `PoseArm`: el discreto (fila **Meca discreta**).
- `game/muscle_arm/` · `MuscleArm`, con sus perillas, su panel y su parcela (filas **Meca física** y **Brazo**).
Los dos heredan de `MechArm`. `Mech.arms_kind` dice cuál lleva (o ninguno: la de práctica). Ver [[brazo]].

## La otra variante de equilibrio — `game/archive/line_cube/` (archivada)
**La línea de equilibrio**, congelada, entera y aparte, por si se vuelve a ella: `HoverCube` (el cubo que flota con
resorte, la línea, tropezar) y `LeggedCube` (con pelvis y piernas), con sus perillas, paneles y parcela. Fila **Cubo con
piernas**. No comparte nada con la meca salvo `MechBody`, `MechLeg` y `Clay`. Ver [[cubo]] y [[cubo-con-piernas]].

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
- `MechCabin` arma los pisos con números sueltos (el asiento, la consola): cuando las consolas sean de verdad, cada
  piso debería armarse de piezas.
- `MechArchetype` y las dos filas: si un camino se descarta, `arms_kind` y la fila se van (ver [[filas]]).
- Las perillas de los brazos físicos (`MuscleArmSettings`) están aparte de `BodySettings`; las del discreto son
  constantes en `PoseArm`.
