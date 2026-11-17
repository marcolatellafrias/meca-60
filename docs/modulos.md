# Los módulos y quién es dueño de qué

El proyecto se trabaja en paralelo, una sesión por módulo (13/11/2026). **Todas trabajan en la misma carpeta y en la
misma rama**: cada una toca sólo lo suyo y commitea sólo sus archivos. Esta nota dice qué es de quién y por dónde se
tocan. Cómo está armado el código por dentro, en [[estructura]].

| Módulo | Es dueño de | Qué hace |
|---|---|---|
| **Meca** | `game/balance_body/`, `game/mech/` (menos la cabina), `game/tool_mech/`, `game/pose_arm/`, `game/muscle_arm/`, `game/projectiles/` (los proyectiles por red, que también usan los jefes) | Cómo pelea la meca propia: su equilibrio, moverse, saltar, los dashes y propulsores, los brazos y sus accesorios (sierra, cañón, ametralladora), la energía, las roturas. **Es dueña de la base común** (ver [[base-comun]]). |
| **Interior** | `game/mech/mech_cabin.gd`, la cabina de la jaula (`game/mech/cage/`) y los tableros (`game/mech/boards/`) | Cómo la manejan los personajes desde adentro: las consolas, los huecos donde se enchufan los recursos, las reparaciones, los pisos, la escalera, el ascensor. |
| **Personajes** | `game/character/`, `game/interactables/` (agarrar, sentarse, los controles de mano) | Los seis arquetipos, su cuerpo, caminar, caerse, agarrar, sentarse. |
| **Jefes** | `game/bosses/` (nueva) | Las mecas enemigas. **Arrancó el 13/11/2026, de cero y de a un paso con el usuario**: un primer jefe sencillo para probar cómo se siente pelear, contra el cubo del laboratorio cinemático (borrado con la meca grande el 17/11/2026; un primer intento, armado de una sin consultar, se revirtió). Hoy, las [[maquetas-jefes]] y lo común de la pelea ([[pelea-jefes]]); y el primero de verdad, el [[luchador]] de orugas (el jefe bola se borró el 15/11/2026). |
| **Mundo** | `game/battlefield/`, la sucursal | El mapa de pelea y la sucursal (la base, las misiones). |
| **Arte** | `game/pixel_art/` | Traer modelos de Blender y pintarles las caras con píxeles. |
| **Generalista** | `docs/` de conjunto (este índice, [[estructura]], [[filas]]), `CLAUDE.md`, `game/sandbox/`, `game/supplies/` | Supervisa, reparte, cuida estos límites. Los recursos (los cubos) los toca quien los necesite, avisando. |

## Las costuras (por dónde se tocan, y nada más)
- **Meca ↔ Interior**: **lo que se le pide** a la meca (`move`, `sprint`, `crouch`, `jump`, `aim_yaw`, `covering`, y
  `punch()` en sus brazos) y **lo que se lee** (el equilibrio, y cuando existan la energía y el daño). El interior
  escribe y lee eso; nunca toca la física. Hoy lo escribe `MechKeys` (las teclas de poseer): las consolas lo van a
  reemplazar.
- **Interior ↔ Personajes**: agarrar, sentarse y manejar un control con la mano (`game/interactables/`). Si el interior
  necesita un control nuevo, lo pide a Personajes o lo arma con lo que hay.
- **Meca ↔ Jefes**: `BalanceBody` (ver [[base-comun]]). Compartir sólo el cuerpo con equilibrio; el resto, piezas.
- **Mundo ↔ Meca**: el piso de la meca es sólo lo que sea `StaticBody3D` (su rayo saltea lo que se mueve).
- **Arte ↔ todos**: cuando el flujo de píxeles esté, cada módulo pinta lo suyo con él.

## Los archivos compartidos
- El sandbox: **cada módulo declara sus filas y sus paneles F en su propio archivo de filas** (`MechRows`, `SupplyRows`,
  `CharacterRows`, `WorldRows`, `ArtRows`, `NetworkRows`; ver [[sandbox]]). `game/sandbox/` es del generalista; un
  módulo nuevo agrega una línea en `SandboxCatalogue.rows()`.
- `docs/technical/filas.md`, `docs/00-indice.md`: cada módulo agrega su renglón.
- `project.godot`: lo reescribe el editor solo; no commitearlo salvo que el cambio sea a propósito.
