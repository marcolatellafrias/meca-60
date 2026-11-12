# El cubo físico

`game/physical_cube/` · fila **Cubo físico** · ver [[filas]]

Para comparar con el [[cubo]] de la línea de equilibrio: **sin línea**, su inclinación es la del cuerpo. Hereda del
cubo las toberas, caer, recuperarse y manejarlo con la **O**.

- **Gira de costado y de frente** con la física; **en Y no** (trabado, por gameplay).
- **Flota sobre cuatro resortes**, uno por esquina de abajo (*resortes de las esquinas: qué tan afuera*; más juntos, más
  se ladea).
- **Los pies** agarran el piso más abajo que el cubo (*dónde agarran*) y llevan la base hacia la velocidad pedida. Un
  golpe corre el cuerpo, los pies frenan la base y **vuelca**, más cuanto más arriba pegó.
- Lo que pide el que lo maneja lo empuja **desde el centro**: arrancar y frenar casi no lo cabecean.
- Un **torque chico** lo endereza además de los resortes.
- Pasado *se cae inclinado más de* (35°), cae y se recupera como el cubo.

## Lo medido (12/11/2026)
- Empujones: 4 m/s en el centro lo inclinan 30° sin caer; arriba cae con unos 3,5 m/s.
- Tiros: 1 m/s lo inclina 8° y lo corre 1,5 m; 5 m/s lo voltea.
- Manejarlo: cabecea 5° al arrancar y 13° al frenar.
- **Contra una pared a 8 m/s se cae**: es física pura y no distingue un golpe de una pared. Es lo que el cubo de la
  línea resuelve con «contra qué y dónde».

Perillas: `PhysicalCubeSettings` (F1, sin las de la línea). Test: `tests/physical_check.tscn`.
