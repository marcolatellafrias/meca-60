# El mapa de pelea

`game/battlefield/` (`Battlefield`, el mapa; `BattlefieldArchetype`, su parcela) · fila **Mapa de pelea** · test
`battlefield_check` · ver [[filas]]

Por ahora hay **un solo mapa** donde pelean las mecas (el usuario, 13/11/2026). Es arcilla: el arte viene después.

## Qué es
**Una arena circular de Ø 260 m, plana y mayormente libre.** La arena es **un fondo**: en el medio las mecas pelean,
se mueven y esquivan sin estorbos. Lo que sirve **a pie** (cubrirse, escaleras, recovecos, de dónde saltar, los
recursos) **va junto, en el borde**, no desparramado. El usuario: «la arena debería estar mayoritariamente libre de
cosas… las cosas no tienen que estar desparramadas tan así al tuntún, pero tampoco tan perfectitas».

- **El borde**: un muro que se ve de 8 m y choca hasta 40 (la meca salta 14 m y no tiene que salirse).
- **Cuatro barrios** contra el muro, de distinto largo. Casas de **11 m** (tapan a una persona), edificios de **30 m**
  (tapan a la meca) y **un hito de 44 m**; una fila contra el muro y algunas casas más adentro; autos en la calle de
  adelante.
- **Escaleras de incendio** en zigzag, pegadas a la fachada que mira al centro: un tramo por piso, en dos carriles, con
  un descanso en cada vuelta y el último al ras del techo. Hechas con `Stairs`: escalones para los pies, rampa para la
  cápsula (ver [[escaleras]]). Para que la gente **suba a los techos**: un
  mejor ángulo, subirse más rápido a la meca, tirar la bomba al jefe o esconderse para sabotearlo.
- **Los recursos** (los cubos de verdad, que se agarran: ver [[recursos]]): tres por lugar, sobre una baldosa ocre con un
  poste y una bandera que se ven de lejos, **frente a cada barrio** y **arriba de algún edificio de 30 m**.
- **Al medio, tres ruinas** lejos una de otra: una pared rota en tres tramos que bajan (14, 10 y 6 m), la esquina de un
  edificio caído (16 m, en L) y una tapia baja (4 m: tapa a la gente; la caja de la meca va más arriba).
- La parcela trae **una meca discreta** para manejar (nace a 45 m del centro, mirándolo) y **una de práctica** sin
  brazos más allá del medio, de jefe quieto.

Todo lo fijo es `StaticBody3D` (el piso de la meca es sólo lo estático). La distribución sale de una semilla propia y
no cambia con la R: es UN mapa.

## Lo que se probó (`battlefield_check`)
- La meca da una vuelta de seis puntos por el campo libre (a unos 55 m del centro), caminando y corriendo, con un
  salto: sin caerse y sin trabarse (como mucho 0,2 s quieta).
- Contra el muro, corriendo por un hueco entre dos barrios: queda a 126 m del centro (el muro empieza a 130).
- **El centro libre para la meca mide unos 60 m de radio** (Ø ~120–130 m): más allá están los recursos (a 64 m), los
  autos (~74 m) y las escaleras de las casas de adentro (~78 m). Una primera vuelta con puntos a 76 m se trabó contra un
  barrio.
- Una cápsula del tamaño de una persona, que pisa la rampa como el personaje, sube la escalera de una casa de 11 m y la
  de una torre de 30 m hasta el techo, con las pisadas siempre de 0 a 15 cm por encima de ella (ver [[escaleras]]).

## Cómo se llegó (para no repetir)
Se maquetaron cuatro tandas en arcilla, que el usuario fue descartando (las capturas, en la conversación; el código, en
la historia de git, commits `441c888`, `1670c6e`, `95f26c9` y `6c7d3ae`):
1. **Mapas temáticos** (pueblo, cantera, puerto, río, fábrica, campo): «antes de las temáticas, quiero experimentar con
   formas abstractas».
2. **Arenas abstractas circulares**. Gustaron los pilares (que pasaron a ser edificios) y **el tren**; con potencial
   **la barredora** y **las islas** (para más adelante); las terrazas y el cráter, no por ahora («mantener las cosas
   planas»; el agua no va con el estilo); las columnas que suben y el muro que se cierra, demasiado complejos. Y la
   escala: más grande que la de un Dark Souls, porque es meca contra meca.
3. **Una arena con edificios repartidos**: se leían como estorbos.
4. **Distribuciones mayormente libres** (centro libre, torre al medio, cráter de ruinas, bolsones, media luna, estadio,
   viaducto, vagones): eligió **centro libre y borde con cosas**, con edificios más altos y unas pocas ruinas al medio.

## Lo que falta (ideas que quedaron)
- **El paquete de la empresa en paracaídas**: un helicóptero tira recursos cada tanto y se ve dónde caen. Otra forma de
  conseguir recursos, además de ir a buscarlos.
- **Obstáculos de circunstancia**: el tren que cruza era el preferido.
- El fondo de afuera del muro (hoy, el piso del sandbox).
