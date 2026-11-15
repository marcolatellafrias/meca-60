# La base en el sandbox

`game/base/` (`BaseLayout`, `BaseArchetype`) · fila **Base** (Mundo) · el diseño, en [[base]] · ver [[filas]]

La sucursal en arcilla, **sin estética**: el plano 6 de [[base]] armado de cajas, para recorrerlo con la meca y a pie.
Lo estético de cada cosa lo agrega el usuario después.

## Qué hay
- **Un solo piso, todo al mismo nivel**, en L: el elevador (24 × 24 m) y el gimnasio (36 × 24 m) en fila, y debajo
  del gimnasio la franja de las consolas (6 m). Debajo del elevador, pared. Paredes de 22 m, sin techo.
- **El elevador**: un cuadrado del piso con el borde amarillo a rayas. Ahí duerme la meca, mirando al gimnasio.
  Todavía no sube.
- **La línea de peligro**, rayas amarillas y negras en el piso, entre el gimnasio y la franja: no hay pared ni vidrio.
- **La bolsa**: un cilindro de 5,2 m de diámetro, de 7 a 15 m de alto, colgado de una viga. **Fija por ahora**, con su
  colisión, para pegarle; la física, después.
- **Las consolas**, contra la pared de la franja: una caja con la pantalla inclinada y su cartel. Los contratos
  (6 m), la armería (4,5 m), los cosméticos y la pintura (4,5 m). Todavía no hacen nada.
- **Los personajes**: seis casilleros, el cuadro del empleado del mes al lado, y **el ascensor de personal**, una jaula
  metida en un hueco de la pared de la punta.

## Las medidas
En `BaseLayout`, en metros sobre el plano (`at(x, z, alto)` pasa a la parcela). Para cambiar el plano se cambian ahí.

## Para mirarla
`tests/base_look.tscn` (con ventana, unos 8 s): dos capturas, desde arriba y desde la franja de las consolas.
