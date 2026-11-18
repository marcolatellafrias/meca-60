# La red

`game/net/` (de character-parametric) · fila **Multijugador** · ver [[filas]]

- `SessionManager`, `NetSpawner`, `CharacterSpawner`, con GodotSteam.
- En la fila: **H** abre sesión en esta compu y otra instancia se une con **J**; **G** por Steam; **K** menú de inicio
  para unirse por código; **L** sale.
- Van por la red los personajes y los objetos de esa parcela, y **las mecas** (18/11/2026, `BodyNet`, en
  game/balance_body/; ver [[movimiento-comun]], «Qué viaja por la red»): un dueño la simula (el host, o quien la posee
  con la O) y manda su motor 20 veces por segundo; las demás máquinas la ponen ahí, 100 ms atrás, y arman el esqueleto,
  las piernas y los pies con eso. Manejada desde adentro, los controles de los tableros ya viajan y le llegan al dueño.
  **Los brazos y la energía** (`MechArmsNet`, en game/tool_mech/): el mismo dueño manda lo que se pide (la energía, la
  guardia, el escudo, el modo, el gatillo y la palanca del cañón, lo que gira) 20 veces por segundo, y cada piña que
  sale, con garantía; cada máquina mueve los brazos y tira sus tiros con eso. En las demás no sale una piña que no
  mande el dueño. **El daño lo aplica sólo el host** (`EnergyBolt.lands`): cuenta una vez.
  *Falta: los golpes de los jefes y la muerte (Jefes).*
- Test: `tests/net_check.tscn`, dos instancias (`--host-local` y `--join-local`). La meca: `tests/mech_net_check.tscn`
  (igual, con dos instancias): el otro la toma y la maneja (camina, dobla, se agacha, salta y hace un dash) y las dos
  la ven en el mismo lugar al centímetro (el motor, el rumbo, la caja y un pie); el host la sigue sin saltos.
  Los brazos: `tests/arms_net_check.tscn` (igual): el otro dispara ráfaga y súper y tira dos piñas, y las dos máquinas
  cuentan los mismos tiros y piñas y la misma energía; la piña propia del host, sin ser dueño, no sale.
