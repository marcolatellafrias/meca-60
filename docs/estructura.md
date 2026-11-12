# La estructura del código

Para enterarse de cómo está armado y criticarlo. El detalle de cada pieza está en el comentario largo con que empieza
su archivo.

## La meca — `game/mech/`
**Una clase con sus piezas aparte**, no una pila de herencias. *Hasta el 13/11/2026 eran tres clases una arriba de la
otra (el cubo, el cubo péndulo, la meca péndulo), con sus tres perillas, tres paneles y tres parcelas; la de abajo
cargaba otro modelo de equilibrio que la meca no usaba.*

| Archivo | Clase | Qué es |
|---|---|---|
| `mech.gd` | `Mech` | El cuerpo físico (la caja 1:1) y **su equilibrio, el péndulo**: el apoyo, caerse, volver. Arma sus piezas y las llama, en orden, una vez por paso. |
| `mech_cabin.gd` | `MechCabin` | Lo que se ve y por donde se camina: los tres pisos, el afuera, el ascensor y **el marco** que lleva a los de adentro. |
| `mech_exterior.gd` | `MechExterior` | La pasarela y la escalera de atrás (superficies pisables, altura libre medida, barandas donde hay caída). |
| `pelvis_lift.gd` | `PelvisLift` | El ascensor de la pelvis. |
| `mech_legs.gd` | `MechLegs` | La pelvis y las piernas: dibujo que pisa por radio alrededor del apoyo. |
| `mech_leg.gd` | `MechLeg` | Una pierna (dibujo). |
| `mech_nozzles.gd` | `MechNozzles` | Las toberas: levantarse cuando se cae, y el propulsor. |
| `mech_moves.gd` | `MechMoves` | Caminar, correr, agacharse, el salto cargado, el propulsor. **Acá van los dashes y los propulsores de costado.** |
| `mech_keys.gd` | `MechKeys` | **El único lugar que lee teclas**: el teclado y el mouse de quien la posee, y su cámara. |
| `mech_arm.gd` | `MechArm` | Lo que se le pide a un brazo (posturas, piñas, la pose, la mano). Base de los dos caminos. |
| `mech_hand.gd` | `MechHand` | La mano (izquierda o derecha, en espejo). |
| `mech_body.gd` | `MechBody` | Las medidas del cuerpo y la IK de una pierna y de un brazo. |
| `mech_settings.gd` | `MechSettings` | Todas sus perillas, en un solo recurso. |
| `mech_panel.gd`, `mech_knock_panel.gd` | `MechPanel`, `MechKnockPanel` | El F1 (perillas) y el F2 (pegarle, el ascensor). |
| `mech_archetype.gd` | `MechArchetype` | La parcela: la meca y una de práctica adelante. La usan las dos filas. |
| `clay.gd` | `Clay` | La arcilla de los bocetos: cajas, cilindros, esferas, miembros. |

### Las tres reglas que la ordenan
1. **Lo que se le pide está separado de quién lo pide.** `Mech` tiene variables (`move`, `sprint`, `crouch`, `jump`,
   `aim_yaw`, `covering`) y sus brazos, `punch()`. Hoy las escribe `MechKeys`; mañana, las consolas de adentro o un
   jefe. Nada más en la meca lee teclas.
2. **La caja sólo se mueve con fuerzas e impulsos.** Caminar, saltar, las toberas, las piñas que recibe: todo es
   `apply_force` / `apply_impulse` sobre el cuerpo. Adentro y por afuera se camina.
3. **Una pieza, un archivo, un trabajo.** `Mech` las llama en orden fijo en su paso: las teclas, los movimientos, el
   equilibrio, las toberas, las piernas, los brazos, el marco.

## Los dos caminos — los brazos
- `game/pose_arm/` · `PoseArm`: el discreto (fila **Meca discreta**).
- `game/muscle_arm/` · `MuscleArm`, con sus perillas, su panel y su parcela (filas **Meca física** y **Brazo**).
Los dos heredan de `MechArm`. `Mech.arms_kind` dice cuál lleva (o ninguno: la de práctica). Ver [[brazo]].

## La otra variante de equilibrio — `game/line_cube/`
**La línea de equilibrio**, congelada, entera y aparte, por si se vuelve a ella: `HoverCube` (el cubo que flota con
resorte, la línea, tropezar) y `LeggedCube` (con pelvis y piernas), con sus perillas, paneles y parcela. Fila **Cubo con
piernas**. No comparte nada con la meca salvo `MechBody`, `MechLeg` y `Clay`. Ver [[cubo]] y [[cubo-con-piernas]].

## El sandbox — `game/sandbox/`, `game/arena/`
`DesignSandbox` (las filas y sus paneles), `SandboxParcel`, `SeededArchetype`, `SandboxPossession` (poseer),
`TestBall` (la bola), las parcelas de personajes y objetos. Ver [[sandbox]], [[poseer]], [[filas]].

## Lo que vino de character-parametric
`game/character/`, `game/interactables/`, `game/net/`, `game/objects/`, `game/common/`, `game/debug/`… El personaje,
agarrar, sentarse, el marco (`MotionFrame`) y la red. **Ya es código de la meca**: se edita cuando hace falta. Sigue
entero como vino, con cosas de ciudad y de nave que acá no se usan: **es la segunda etapa de limpieza**, después de la
meca. Ver [[personajes-traidos]].

## Lo que todavía criticaría
- `MechKeys` mezcla tres cosas chicas: las teclas, la cámara de poseer y la cabeza del que va sentado. Cuando haya
  consolas, las teclas se van a ellas y queda la cámara.
- `MechCabin` arma los pisos con números sueltos (el asiento, la consola): cuando las consolas sean de verdad, cada
  piso debería armarse de piezas.
- `MechArchetype` y las dos filas: si un camino se descarta, `arms_kind` y la fila se van (ver [[filas]]).
- Las perillas de los brazos físicos (`MuscleArmSettings`) están aparte de `MechSettings`; las del discreto son
  constantes en `PoseArm`.
