# La cabina redonda

`game/mech/round/` (`RoundCabin`, `RoundGrid`, `RoundShape`, `RoundShapePanel`) · módulo **Interior** · ver [[cabina]]
(la cuadrada), [[meca]]

Una segunda cabina, **en otra parcela** (la fila **«Meca redonda»**), para probarla sin tocar la cuadrada (el usuario,
15/11/2026: «para no pisar lo de la cuadrada, podríamos hacer como un "fork" en otra parcela»). Es la misma meca (se
mueve, se posee, se cae igual), con `Mech.cabin_shape = Mech.Cabin.ROUND`; lo que cambia con la cabina se pregunta en un
solo lugar, `Mech.cabin_kit`: la caja, el hombro y si se ven las toberas.

## La forma
Sale de la maqueta de arcilla (`tests/round_cabin_look.tscn`), donde se decidió:
- **Adentro, lados planos** (12); **afuera, un cilindro liso**. Los lados del frente (5), de vidrio de piso a techo.
- **Techo bajo** (2,3 m libres).
- **Debajo de la cabina, un disco** del mismo radio (1 m), y recién debajo las piernas: le da volumen a la meca.
- **Sin tableros ni hologramas**: las sillas solas («si queremos ir con este approach más cilíndrico, no podemos tener
  tableros en el piso y todos los elementos van a pasar a ser cosas de las sillas»). **Las tres de adelante siguen el
  cilindro**: la del medio en el lado del frente y las de los brazos dos lados más allá, mirando hacia afuera.
- **La tarima, chica, al centro, baja (30 cm), con un escalón todo alrededor**; para la cápsula, una rampa (como las
  escaleras). Arriba, el movimiento y, **corrido atrás, el ascensor**, que baja por el disco. *Atraviesa la pelvis: se
  arregla después (el usuario: «que atraviese por ahora»).*
- **Atrás, en las paredes**: los cuatro kits en los lados de los costados; las dos municiones y la batería al medio, en
  el de atrás de todo (por ahora, sólo se ven).
- **Sin toberas que se vean** (sólo en la redonda): empujan igual, no se dibujan (`BalanceBody.show_nozzles`).

## La forma se cambia jugando: el F2 de la fila
`RoundShapePanel`, en cuatro pestañas: **La caja** (lados, radio, alto libre, alto del disco y **el domo**: el techo
termina en un domo de metal, sin vidrio, abierto por dentro, que va de un casquete chato a una media esfera), **La tarima y el ascensor**
(radio y alto de la tarima, radio del ascensor y cuánto va corrido atrás) y **El vidrio** (cuántos lados, **el alto del visor**
—hasta dónde sube el vidrio; arriba, metal: se sube el techo sin subir el visor—, color, cuánto se ve) y **Brazos y piernas**, la misma de la cuadrada: el cuerpo es uno solo para todas las mecas, y se guarda con
la forma de la cuadrada (cambiarlo acá lo cambia allá). **Guardar** la escribe en `game/mech/round/round_shape.tres` (no se sube) y rearma las mecas; la cuadrada tiene
la suya aparte. Las sillas, la tarima, el ascensor y los recursos se acomodan solos.

## Los tests
- `tests/round_mech_look.tscn`: la meca redonda de verdad, de afuera y de adentro.
- `tests/round_ride_check.tscn`: subirse, el ascensor abajo y arriba, subir a la tarima caminando, el salto y la caída
  con uno adentro (con `--sin_empuje`, sin el empujón fuerte; `--pared`, caminar contra la pared de atrás).

## Lo que sigue
- **El empujón fuerte** (11 m/s² durante 2,5 s, el de `mech_ride_check`): el de adentro se resbala por el piso abierto,
  llega a la pared de atrás a unos 7 m/s y la atraviesa. Caminando, la pared lo frena. En la cuadrada no pasa porque lo
  frena antes la tarima alta.
- **Las bolas de los hombros** se meten un poco adentro de la cabina (se ven desde adentro).
- **La caja de choque de la meca** sigue siendo una caja (la del cilindro): las esquinas chocan afuera del cilindro.
- **El ascensor contra la pelvis**, y los puestos de las sillas (cuando se decidan).
