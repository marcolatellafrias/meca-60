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

Hoy: la [[meca]] de pelea y todos los cubos ([[cubo]], [[cubo-con-piernas]], [[cubo-fisico]], [[cubo-pendulo]]).
Pendiente: los personajes (hay que pasarles el control del jugador).

Test: `tests/possess_check.tscn`.

## Historia
- 12/11/2026: la primera persona pasa del frente de la caja al asiento de adentro, con la cabeza libre; los cubos
  ganan una cabina por dentro (un piso con vidrio y parantes, como los de la meca).
- 12/11/2026: nace, y reemplaza al «manejar desde afuera» que tenían por separado la meca (O, T, E) y los cubos (O, E).
