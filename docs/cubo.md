# El cubo

`game/hover/` · fila **Cubo** · ver [[filas]]

Un cubo de 8 m (del orden del torso de la [[meca]]) para probar el equilibrio, la caída y la recuperación aparte de la
caminata.

## Parado
- **Flota con un resorte vertical**: dos rayos al piso desde la cara de abajo, la gravedad compensada, error y fuerza
  con tope. Un golpe de arriba o de abajo lo hunde y rebota solo.
- **No gira**: sus giros están trabados. Ningún golpe le cambia hacia dónde mira.
- **Dos velocidades de costado, aparte**: la propia (manejándolo con la **O**: arranca con *cuánto tarda en arrancar* y, al soltar, frena de a poco con *freno al soltar*) y la del retroceso que le dejan los golpes (*freno del retroceso*). Un golpe puede correrlo mucho sin que manejarlo se vuelva resbaloso.
- **La línea de equilibrio**: el mismo golpe (lo que cambió la velocidad sin que él lo pidiera) suma a la velocidad de la
  inclinación; un resorte la devuelve. Golpes seguidos se suman. Se dibuja inclinando el dibujo sobre el canto de abajo.
  Ver [[equilibrio]].

Corrimiento e inclinación salen del **mismo golpe medido**, pero se escalan aparte: *freno del retroceso* (cuánto se corre)
e *inclinación por m/s de golpe* (cuánto se inclina).

## Tropezar y caer
Al pasar *se cae en*, el cuerpo toma la inclinación del dibujo y queda suelto, con un giro de una vez: el justo para que
la base quede quieta (como pies trabados) más lo que se venía inclinando. Desde ahí es física: cae para el lado del
golpe. Caído pesa un poco más y se le frena el giro, poco.

## Recuperarse
Cuatro toberas por cara, con el humo de propulsor de character-parametric. Apenas deja de caer y de rodar rápido:
**sube** con las de la cara que mira al piso y, en cuanto puede girar sin tocar el piso, **se endereza** con las de los
costados. Derecho, se traba y vuelve a la línea mirando hacia donde miraba.

## Cómo se prueba
- **J** tira la bola, **K** pasa por los cuatro tiros: lenta (30 m/s) o rápida (100 m/s), que lo voltea o no.
- **F1** las perillas (`HoverCubeSettings`), **F2** volcarlo suave o fuerte.
- `tests/hover_check.tscn`.

## Historia
- 11/11/2026: nace como cuerpo libre que se endereza con un torque; se bifurca uno con la línea de equilibrio.
- 12/11/2026: queda uno solo, el de la línea. El del torque se borró: se torcía con cualquier golpe.
