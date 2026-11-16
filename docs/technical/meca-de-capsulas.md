# La meca de cápsulas

`game/mech/pods/` · fila **Meca de cápsulas** (la tercera del sandbox, después de la Meca de tres) · ver
[[dos-paradigmas]], [[meca-de-tres]], [[cabina]]

**La meca sin interior** (15/11/2026): el torso es macizo y cada uno va en su **cápsula**, una esfera empotrada en el
cuerpo. Sale de la maqueta 37 de `tests/sphere_pods_look` (el usuario: «pasemos esta maqueta de forma paramétrica y
ordenada al sistema de la nave»). Es una cabina más de la meca (`Mech.Cabin.PODS`), como la del vórtice.

## Cómo se llegó
Las maquetas 1 a 39 de `tests/sphere_pods_look`: esfera, disco, huevo, cápsula acostada, esferoides, domos que
sobresalen, burbujas en cuellos. Lo que quedó:
- **Empotradas, a favor**: cada uno ve lo que le sirve. El usuario: «el del medio es artillero, entonces está centrado.
  El de la izquierda y la derecha usan brazo izquierdo y derecho, entonces ven su lado. Y el de arriba ve como todo».
- Las cápsulas en los hombros (con los brazos atrás) no: el fondo de la propia cápsula tapa la mitad del frente.
- A la escala de la meca de verdad (piernas de 4,4 m, brazos de 5,5, la cintura a 7,4 m) el torso pasa los 11 m de
  diámetro.
- Se entra a cada cápsula desde abajo (después); por ahora, en modo creativo, se mete uno y E en su silla.

## El torso — `PodCabin`
Un domo de **fondo chato** (el borde de abajo, redondeado), una **pared derecha** en el medio y **el domo** arriba,
torneado en redondo. Desde adentro de una cápsula el torso no se ve (es de una cara): es como si tuviera su hueco.

## Las cápsulas
Cuatro, iguales (1,8 m): **arriba, el movimiento** (asoma la mitad y su mitad de afuera es toda vidrio: ve alrededor);
**al frente, el artillero**; **a los costados, los brazos izquierdo y derecho**. Cada una es **opaca con una ventana de
vidrio** hacia afuera (el usuario: «la esfera empotrada tiene una parte opaca y otra translúcida de cristal»): desde
adentro se ve oscuro todo menos la ventana. Cada una con su piso y su silla (`chairs`, en el orden de `MechCabin.POSTS`:
izquierda, medio, derecha, arriba). La U te deja en la de arriba.

## Un solo radial
Todo lo que va pegado al cuerpo va en **la mitad de la pared**, cada cosa a un rumbo desde el frente: las cápsulas de
los costados (`pod_step`), **los hombros, aparte** (`shoulder_step`; el usuario: «por separado tal vez sea mejor») y
los recursos atrás (sólo se ven). Bajando los pasos, todo se junta hacia adelante.

## Lo demás
- **La gatling**, abajo de la cápsula del medio, mirando al frente: sólo se ve («que se vea nomás»).
- **La columna**: del fondo a la pelvis, oscura. La pelvis es la de siempre (un tubo que une las piernas). Sin
  ascensor.
- **La meca — `PodMech`**: la Meca de tres (`ToolMech`: cinemática, la energía común, sus teclas, las placas) con
  esta cabina, **el cañón a la izquierda y el puño de siempre a la derecha** («con cañón y en el otro puño normal»).

## La forma, jugando — `PodShapePanel` (F2)
Se guarda aparte, en `game/mech/pods/pod_shape.tres` (`PodShape`): el radio del torso, el alto de la parte cilíndrica
(las cápsulas, los hombros y los recursos se acomodan a su mitad), el alto del domo, el borde de abajo, el rumbo de las
cápsulas, cuánto asoman, la ventana, el rumbo de los hombros, y la pestaña «Brazos y piernas» (la misma de las otras).

## Test
`tests/pod_mech_look.tscn` (unos 10 s, sin el sandbox): arma la parcela, imprime la caja, el hombro y las sillas, y con
ventana saca una hoja de afuera y desde los ojos de los cuatro sentados.

## Lo que falta
- Entrar desde abajo, cada uno por su escotilla.
- Los puestos de cada cápsula (con Interior y Tableros).
- Que la gatling tire.
