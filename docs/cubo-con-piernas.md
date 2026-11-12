# El cubo con piernas

`game/legged_cube/` · fila **Cubo con piernas** · ver [[filas]]

El [[cubo]] (hereda todo: flotar, moverse, la línea, tropezar, caer, recuperarse) con una **pelvis** debajo y **dos
piernas**, para empezar a ver cómo se mueven. El cuerpo es el de la [[meca]] (`MechBody`): la cara de abajo del cubo
flota a la altura de la cintura.

- **Las piernas son dibujo**: el peso lo lleva el resorte vertical y los golpes los recibe el cubo.
- **La pelvis** mira hacia donde caminan las piernas y se inclina con la línea.
- **El torso gira aparte**: manejándolo (**O**), W/S y A/D mueven las piernas y el mouse apunta el cubo; la cámara
  sigue al torso.
- **Los pasos, por radio**: cada pie queda plantado hasta que su lugar debajo de la cadera, adelantado con la marcha
  (*cuánto se adelanta el pie*), se aleja más que *da un paso al alejarse más de*; ahí da un paso por el aire, de a un
  pie. Caminando, girando o corrido por un golpe, los pies lo siguen solos.
- **Al caer se pliegan** (*se recogen al caer en*), con easing: muslo adelante, canilla de vuelta y pie debajo de la
  cadera. Se pliegan, no se achican: las piezas no se estiran. Quedan plegadas tirado y subiendo, y **en cuanto empieza a
  enderezarse se estiran** (*se estiran al enderezarse en*) hacia debajo de las caderas: al quedar derecho ya está
  parado.

Perillas: `LeggedCubeSettings` (F1), las del cubo en su propia copia más las de los pasos. Test:
`tests/legged_check.tscn`.

## Historia
- 12/11/2026: nace, con pelvis («el cubo debería tener pelvis, obvio»), torso aparte, dos piernas y pasos por radio.
- 12/11/2026: las piernas se pliegan al caer y se estiran al enderezarse (antes quedaban duras).
