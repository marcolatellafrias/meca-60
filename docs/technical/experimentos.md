# Los experimentos

`game/base/experiments.gd` (`Experiments`). El 22/11/2026, el usuario: «cuando selecciones un contrato sea un
experimento y cuando selecciones otro sea otro… cuando selecciones el contrato puedas cambiar los valores de los paneles.
O sea, no hacer un sistema nuevo encima». En el juego final van a ser contratos de verdad.

## Qué es
- **Un contrato de prueba** es uno de `ContractsCatalog.CONTRACTS` con `experiment` (hoy, los únicos tres: los que nombraban jefes sin hacer se sacaron el 22/11/2026). Firmarlo
  cambia las perillas de los paneles de siempre: el dash (`DashSettings`), todos los jefes (`BossSettings`) y el Luchador
  (`BrawlerSettings`). Firmar uno sin experimento vuelve a lo guardado de siempre.
- **De dónde salen las perillas**: si el experimento ya se guardó alguna vez, de su archivo
  (`<archivo>_exp_<id>.tres`, al lado del de siempre); si no, de lo guardado de siempre con los cambios de
  `Experiments.CHANGES`.
- **Los paneles siguen andando encima**: F3 (el dash) y **F5 (el jefe, nuevo en la partida: el mismo panel del F1 de su
  fila)**. Con un experimento firmado, «Guardar» guarda en el archivo del experimento y no toca el de siempre; la línea
  de arriba del F3 lo dice. Los paneles abiertos se rearman al cambiar de experimento.
- **En red**: cada máquina lo aplica al cambiar el contrato (`BaseSync._on_contract`, después de mandar la foto); el dash
  además lo reparte el host, así manda el suyo. Los archivos son del usuario: los del experimento, también.

## Los tres de hoy
| | Esquivar por posición (`posicion`) | Esquivar por tiempo (`timing`) | Las dos (`mixto`) |
|---|---|---|---|
| Poderes | la onda, la piedra, el agarre, el lanzallamas (también tranquilo) | la embestida y el trompo | los seis |
| Marcas en el piso | sí | no: se lee la pose, como en Souls | las zonas sí; la embestida y el trompo, por la pose |
| Dash | la ráfaga, sin intocable | la ráfaga de 5 m, intocable 0,3 s | **Shift** la ráfaga, intocable 0,3 s, y **Ctrl** el sobrevuelo |

Un poder prendido se usa tranquilo y con ira; apagado, nunca. El bombardeo queda apagado en los tres (pide el vuelo).
**Los dos propulsores de la espalda** (`MechThrusters`) están en toda meca jaula: se prenden cuando va bastante más rápido
que caminando.
Son puntos de partida: lo demás sale de lo guardado de siempre, y se ajusta con los paneles.

## La ráfaga intocable
`DashSettings.burst_untouchable` (F3, pestaña Ráfaga; 0, nunca): desde que arranca la ráfaga, esos segundos ningún golpe
la toca (`MechDash.untouchable`, `CageMech.block_hit`). El golpe que la encuentra intocable **queda usado**, como uno
frenado por el escudo (`HitReaction.blocks`): no vuelve a pegar cuando se termina.

## Cómo se prueba
`tests/experiments_check.tscn` (unos 5 s): firmar cada prueba y volver, adónde guarda, y la ráfaga intocable. Si un
experimento ya tiene archivo guardado, sus números no se miden.

## «bolitas» (22/11/2026)
Sólo las bolitas de distintos tipos (`OrbsPower`, ver [[poderes-jefes]]). La meca tiene el dash intocable por 0,2 s y el sobrevuelo.
