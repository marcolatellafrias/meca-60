# Las escaleras

`game/stairs/` (`Stairs`) · la usan las escaleras de incendio del [[mapa]] y la de atrás de la meca · ver [[personajes-traidos]]

## La regla: TODA escalera se arma con `Stairs`
El usuario (13/11/2026): «las escaleras… para que funcionen bien con los personajes actuales… tienen dos zonas, actúa
como rampa para la cápsula, pero para los pies actúa como escalones… siempre que se usen escaleras tienen que ser de
esta forma». Es la escalera de «bajar la escalera» del laboratorio de locomoción de character-parametric
(`LocomotionLabArchetype`), en su versión de escalones de 15 cm.

**Nunca una rampa sola que se dibuja como escalera, ni escalones sólidos que pisa la cápsula.** Un tramo de escalera
son DOS cuerpos:

| | Los escalones | La rampa |
|---|---|---|
| Se ve | sí | no |
| Capa | Escalones (14, `PhysicsLayers.FEET`) | Rampa (13, `PhysicsLayers.RAMP`) |
| La ven | los rayos de los pies y el ragdoll | la cápsula y su rayo de piso |
| Forma | cajas de 15 cm de alto y 31,5 de pisada | una tabla por los **rincones de abajo** de cada escalón |

Así **toda pisada queda entre 0 y un escalón por encima de la cápsula**: la pierna la alcanza doblándose y nunca le falta
largo. *En el laboratorio, con la rampa por los bordes de arriba de los escalones, algún pie quedaba fuera de alcance el
90 % del tiempo.*

- **Los descansos** igual: el piso de los pies a su altura y, debajo, el de la cápsula **un escalón más abajo**. La rampa
  de cada tramo se estira un escalón para atrás y uno para adelante, hasta el piso de la cápsula de los descansos de sus
  puntas.
- **El descanso que da a un piso común** (un techo, la calle): la tabla de la cápsula sube ese escalón a lo ancho del
  descanso, para empalmar sin escalón.
- **La medida**: 15 cm de alto (un tramo lo ajusta un pelo para cerrar justo) y **31,5 cm de pisada** (`Stairs.TREAD`:
  ocho celdas de 1/16 del cubo de recurso, las de la grilla de la cabina cuadrada de la meca grande, borrada el
  17/11/2026; la medida quedó igual).
  *El laboratorio usaba 50 cm; con eso un piso de 3 m pide un tramo de 10 m, que no entra en una fachada. Si los pies
  no se sienten bien jugando, la pisada es lo primero que hay que mirar.*
- **Nada más que los personajes pisa una escalera**: ni la meca ni los objetos sueltos (un cubo que se suelta en una
  escalera, cae).

## Cómo se usa
- `Stairs.flight(parent, start, toward, height, width, color)`: un tramo que arranca en `start` (el piso de abajo) y
  sube `height` hacia `toward`.
- `Stairs.landing(parent, top, size, yaw, color, rise_toward)`: un descanso; con `rise_toward`, el que da a un piso común.
- `Stairs.run_for(height)` / `steps_for(height)`: cuánto ocupa un tramo y cuántos escalones lleva.

## Las escaleras de incendio del mapa (`Battlefield.stairs`)
Pegadas a la fachada que mira al centro, en zigzag por dos carriles de 1,4 m: **un tramo por piso** (unos 3 m, 18 a 20
escalones, 5,7 a 6,3 m de largo) y un descanso de 1,6 m en cada vuelta; el último da al techo.

## Lo que se probó (`battlefield_check`)
Una cápsula de persona que, como la del personaje, pisa el piso y la rampa (no los escalones) sube la escalera de una
casa de 11 m (4 tramos) y la de una torre de 30 m (10 tramos) hasta el techo. En cada paso, lo que pisarían los pies
queda **de 0,00 a 0,15 m** sobre el piso de la cápsula. **Falta verlo con el personaje de verdad, jugando.**

## Quién la usa
- Las escaleras de incendio del mapa (`Battlefield.stairs`, arriba).
- Las dos escaleras de adentro de la cabina de la meca, que suben a la tarima (`MechCabin`, desde el 14/11/2026; antes,
  la escalera de atrás, `MechExterior`, desde el commit `3e5abfd`). El marco de la meca (`MotionFrame`) copia la rampa a
  su sombra de siempre y los escalones a una segunda sombra, en la capa Escalones.
