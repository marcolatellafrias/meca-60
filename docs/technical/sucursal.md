# La base en el sandbox

`game/base/` (`BaseLayout`, `BaseHatch`, `BaseSettings`, `BasePanel`, `BaseArchetype`) · fila **Base** (Mundo) · el diseño, en [[base]] · ver [[filas]]

La sucursal en arcilla, **sin estética**: el plano 6 de [[base]] armado de cajas, para recorrerlo con la meca y a pie.
Lo estético de cada cosa lo agrega el usuario después.

## Qué hay
- **Un solo piso, todo al mismo nivel**, en L: el elevador (24 × 24 m) y el gimnasio (36 × 24 m) en fila, y debajo
  del gimnasio la franja de las consolas (12 m de fondo y **5 m de alto**, a escala de persona: sobre su borde abierto,
  la pared de la nave baja hasta ahí, como un dintel). Debajo del elevador, pared. La nave, de 22 m, y **techo**; adentro,
  cinco lámparas colgadas (el sol no entra).
- **El elevador**: un cuadrado del piso con el borde amarillo a rayas. Ahí duerme la meca, mirando al gimnasio.
  Todavía no sube.
- **La compuerta del techo** (`BaseHatch`), sobre el elevador: dos hojas que **se corren hacia los costados**, como una
  puerta de ciencia ficción, cuando empieza una partida; cada una se guarda en su bolsillo, una caja sobre el techo (la
  de afuera, metida en la roca). Por ahora la abre y la cierra la **G** de la parcela.
- **La línea de peligro**, rayas amarillas y negras en el piso, entre el gimnasio y la franja: no hay pared ni vidrio.
- **La bolsa**: un cilindro de 5,2 m de diámetro, de 7 a 15 m de alto, colgado de una viga. **Fija por ahora**, con su
  colisión, para pegarle; la física, después.
- **Las consolas**, contra la pared de la franja: una caja con la pantalla inclinada y su cartel. Los contratos
  (6 m), la armería (4,5 m), los cosméticos y la pintura (4,5 m). Todavía no hacen nada.
- **Los personajes**: seis casilleros, el cuadro del empleado del mes al lado, y **el ascensor de personal**, una jaula
  metida en un hueco de la pared de la punta. **El hueco es sólo de su alto** (3,4 m): arriba sigue la pared. Es una
  ilusión de continuidad, no un pozo.

## Las medidas
En `BaseLayout`, en metros sobre el plano (`at(x, z, alto)` pasa a la parcela).
- **Se mueven con el F1** de la fila (`BasePanel`, perillas en `BaseSettings`): **el alto de la nave** (16 a 45 m), **el
  fondo de la franja** (6 a 30 m) y **su alto** (3,5 a 20 m). Al guardar, cada base armada se vuelve a armar en su
  lugar (`BaseLayout.rebuild`; la meca se queda). Lo guardado, `game/base/base_settings.tres`, es del usuario: no va al
  repositorio.
- Lo demás (el elevador, el largo, el hueco del ascensor de personal, la bolsa), en las constantes de `BaseLayout`.
- La parcela se mide con la franja más honda (30 m): con una menos honda, la base se arrima a la pared del fondo.
- Los paneles F2 a F4 son los de la meca propia (como en los jefes), para modificarla desde la base.

## Para mirarla
`tests/base_look.tscn` (con ventana, unos 8 s): cuatro capturas, desde afuera con la compuerta abierta, desde la
franja de las consolas, desde el gimnasio hacia la compuerta, y otra vez desde afuera con otras medidas (lo que hace el
F1 al guardar, sin guardarlas).
