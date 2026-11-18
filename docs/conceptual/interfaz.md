# La interfaz: el lenguaje común

**Borrador** (17/11/2026). Primero que funcione; la capa estética, al final. Ver [[base]], [[progresion]].

## El lenguaje común
- **Una sola letra**: la de trazos rectos (`StrokeFont`, la de character-parametric). Hoy escribe sólo en el mundo 3D;
  para las pantallas hace falta un control 2D que la dibuje. Le faltan el `$` y los círculos de la dificultad.
- **Tres tamaños**: el título de la estación (uno por pantalla), el texto de listas y botones, y la ayuda gris.
- **Un solo color de acento**: el amarillo de las rayas de peligro.
- **Los botones**: normal, con el mouse encima, elegido, la acción principal (una sola, amarilla, abajo a la derecha) y
  lo que no se puede (gris; el porqué, con el mouse).
- **El marco de toda estación**: arriba, su nombre, la plata de la tripulación y el capitán; abajo, las teclas y la
  acción principal.
- **Una imagen se entiende antes que un texto**: cada cosa que se compra tiene su **ícono en pixel art** (24 × 24, en
  color, con contorno oscuro: el estilo 3 de las maquetas). Los de hoy son placeholders hechos por código; después, a
  mano o capturas de los modelos con el fondo borrado.

## Las estaciones (primera versión)
- **El menú principal**: crear partida, unirse con código, opciones, salir.
- **La esclusa**: sólo un cartel arriba («esperando tripulación», quién está, el código para invitar). Sin explicar el
  botón: se dan cuenta solos.
- **Contratos**: la lista (dificultad, jefe, paga, afijos) y el detalle con el jefe en 3D. Bien así (el usuario,
  17/11/2026); cambios menores después.
- **Armería** (la variante B): la tienda en grilla con ícono, nombre y precio; la meca dibujada con sus huecos y el
  depósito de la sucursal, **sólo con íconos** (sin nombres); la descripción, en el cartel del mouse. Se arrastra para
  comprar, poner y sacar.
- **Cosméticos y pintura**, dos pestañas:
  - **Cosméticos**: **el mismo sistema que la armería** (el usuario: «así de paso tenemos un lenguaje unificado»): la
    tienda en grilla, la meca con sus huecos de cosméticos (el banderín, la cabina, los propulsores) y el depósito.
  - **Pintura**: se elige qué superficie, se pinta en 2D por píxeles (lápiz, balde, goma, grosor) con un selector de
    color. Hay que replantearlo si la meca es la redonda. **Sin terminaciones** (mate, satinado, gastado: no).
- **Casilleros y cuadro del empleado del mes**: no van en la primera versión.

## Abierto
- Qué hacen los que no son capitán en las estaciones (¿proponen?).
- Los íconos y las imágenes de verdad.
