# La meca

`game/mech/` · fila **Meca** · ver [[filas]]

- **El cuerpo se define una sola vez**: `MechBody` (medidas, partes, postura; pierna y brazo por ley de cosenos). La de
  pelea y la de [[equilibrio]] son el mismo cuerpo.
- **Nace donde vive**: se ubica antes de armarle nada encima; lo físico montado se mueve con ella
  (`MechTorso.carry_mounted`).
- Las piernas caminan; **el torso gira aparte** sobre la pelvis.
- **Las piernas** (`MechLeg`, el dibujo; la usan la meca y los cubos con piernas): macizas, con las articulaciones
  —cadera, rodilla, tobillo— como **discos** del grosor de la pierna y el eje de costado. La **pelvis** es corta, entre
  los dos discos de las caderas. Articulaciones y pies, de un gris apenas más oscuro que la pierna (no negro).
- **Piñas** cargadas (mantener y soltar el clic); la fuerza sale de la velocidad del puño en el mundo; el mouse dobla la
  piña. El puño siempre al alcance, barre contra la capa 1 y se traba contra edificios.
- **Puestos** adentro con la silla de character-parametric (`MechSeat`), montacargas (`MechLift`); el torso es un
  `MotionFrame`.
- Mirándola, **O** la posee ([[poseer]]; **T** cambia la vista), **U** subir. Rival sin piloto: `MechBrain`.
- Física simplificada, no estadísticas: no hay vida, todo es equilibrio.

Test: `tests/mech_check.tscn` (con ventana).
