# La meca

`game/mech/` · fila **Meca** · ver [[filas]]

- **El cuerpo se define una sola vez**: `MechBody` (medidas, partes, postura; pierna y brazo por ley de cosenos). La de
  pelea y la de [[equilibrio]] son el mismo cuerpo.
- **Nace donde vive**: se ubica antes de armarle nada encima; lo físico montado se mueve con ella
  (`MechTorso.carry_mounted`).
- Las piernas caminan; **el torso gira aparte** sobre la pelvis.
- **Piñas** cargadas (mantener y soltar el clic); la fuerza sale de la velocidad del puño en el mundo; el mouse dobla la
  piña. El puño siempre al alcance, barre contra la capa 1 y se traba contra edificios.
- **Puestos** adentro con la silla de character-parametric (`MechSeat`), montacargas (`MechLift`); el torso es un
  `MotionFrame`.
- **O** desde afuera (**T** primera persona), **U** subir. Rival sin piloto: `MechBrain`.
- Física simplificada, no estadísticas: no hay vida, todo es equilibrio.

Test: `tests/mech_check.tscn` (con ventana).
