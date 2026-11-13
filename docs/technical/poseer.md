# Poseer

`game/sandbox/sandbox_possession.gd` · ver [[sandbox]]

Para probar de a uno lo que en el juego se maneja desde adentro (en el juego final una meca nunca se posee: se maneja
con sus controles físicos). Separa dos cosas: **a quién le llegan las teclas** y **desde dónde se mira**.

- **O**, mirando algo que se puede poseer: lo posee. Las teclas pasan a él y el jugador se apaga donde está. Bajo la
  mira aparece «O poseer: …».
- **O** otra vez: lo suelta, vuelve el jugador. **Se acuerda de lo último**: O sin mirar nada lo retoma. Soltar sirve
  para moverse a mirar de otro lado y seguir manejando; no hay una tecla aparte para eso.
- **T**, poseyendo: pasa por las tres vistas.
  - **Libre**: la cámara del jugador, donde quedó.
  - **Tercera persona**.
  - **Primera persona**: la del que va **sentado adentro** (en la meca, el puesto del medio; en los cubos, el asiento
    de su cabina), viendo el vidrio y los parantes como lo van a ver los jugadores. Los ojos van fijos al cuerpo (se
    inclina y cae con él) y **el mouse mueve la cabeza al instante**; el torso la alcanza con su demora.
- **El cartel** (abajo a la derecha): qué se posee, la vista y **sus controles**, que los dice lo poseído.

## Qué se puede poseer
Lo que está en el grupo `possessable` y contesta, por nombre:

| Método | Qué dice |
|---|---|
| `possess_name()` | cómo se llama |
| `possess_controls()` | sus controles, una línea por renglón |
| `possess_begin()` / `possess_end()` | empieza y deja de leer las teclas |
| `possess_camera(first, delta)` | dónde va la cámara, en primera o en tercera persona |
| `possess_status()` (si quiere) | lo que le pasa ahora: una carga, un combustible |

Hoy: la [[meca]] (las dos filas y la de práctica), el [[cubo-con-piernas]], el [[brazo]] físico y **los personajes**:
cualquiera que no sea el jugador y se simule (los maniquíes de las sillas de la meca, la gente de la fila Locomoción).

## Poseer a un personaje
`game/character/character_possession.gd` (`CharacterPossession`). Simple a propósito: **no se le cambia la clase** ni
se le pasa el control del jugador. El teclado y el mouse aprietan los botones de su intención, como un guion, y las
manos son las de `CharacterActions`. Por eso sigue siendo lo que era: va en el marco de la meca, se choca y se cae
igual (poseído se levanta solo, como el jugador). **Al soltarlo queda como quedó** —parado, tirado o sentado— y no
vuelve solo a su silla.

- **E**: sentado, se para; mirando una silla, se sienta (por su intención, sin el pedido al host del jugador); si no,
  usa lo que mira. WASD, shift, espacio y Ctrl como el jugador; clic izquierdo agarra, R tira.
- **Mirando una silla ocupada se posee al que está sentado**, no a la meca: sentado no tiene colisión.
- El rayo de poseer no ve **la sombra de un marco** (`MotionFrame.LAYER`, la copia de la meca para los de adentro),
  que tapaba las sillas.

Test: `tests/possess_check.tscn`; los personajes, `tests/possess_character.tscn`.

## Historia
- 13/11/2026: se poseen personajes, empezando por los maniquíes de las sillas de la meca.
- 12/11/2026: la primera persona pasa del frente de la caja al asiento de adentro, con la cabeza libre; los cubos
  ganan una cabina por dentro (un piso con vidrio y parantes, como los de la meca).
- 12/11/2026: nace, y reemplaza al «manejar desde afuera» que tenían por separado la meca (O, T, E) y los cubos (O, E).
