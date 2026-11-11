# Los personajes de character-parametric, traídos

`game/character/` (y `assets/models/character/`, y de `game/common/` `motion_frame.gd`, `physics_layers.gd` y
`debug_util.gd`) son **copias tal cual** de `D:\Godot\character-parametric`, tomadas el 11/11/2026 de su árbol de trabajo
(último commit allá: `50a538ef`). No se editan acá: si cambian allá, se vuelven a copiar.

Lo que esos archivos usan y acá no existe está en **esta carpeta**, con el mismo nombre y sólo lo que los personajes
le piden: agarrar y sentarse (`Interactable`, `GrabbableInteractable`, `SeatInteractable`…), el jugador con teclado
(`PlayerController`), el guion de exhibición (`ExhibitOperator`), la red (`CharacterNetSync`), la depuración
(`SkeletonDebugDraw`, `CharacterDebugView`, `DebugArchetype`) y dos autoloads (`UIState`, `WorldSettings`). Cuando se
traiga una de esas cosas de verdad, su pieza de acá se borra.

Se sacaron de la copia, porque son del jugador con teclado: `player_controller.gd`, `exhibit_operator.gd`,
`first_person_view.gd` y `possession_camera.gd`.

Quién los usa: `PeopleArchetype` (la fila Personajes y las personas al lado de la meca de equilibrio) y
`CharacterGetUp` (que se levanten solos, como allá con el guion).
