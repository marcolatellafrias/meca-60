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
- **Los jefes** (18/11/2026, `BossNet`, en game/bosses/): los simula el host (su cabeza piensa sólo ahí) y las demás
  máquinas siguen su cuerpo (dónde está, los rumbos, la pose, el trompo, el horno, la ira, si vuela y el resorte). Lo
  común de seguir algo por la red (el dueño, mandar, el buffer y la mezcla) es `NetFollow` (game/common/), de la meca
  y del jefe. *Falta: lo que se ve de sus ataques (las zonas, la piedra, el fuego, la onda, el gancho), hoy sólo en el
  host.*
- **La vida y la muerte** (`Health`): la decide el host. Un golpe en otra máquina se le pide al host; el host dice a
  todos cuánta queda, con qué y el empujón, y en todas se muere igual (el ragdoll con el mismo empujón). **Los golpes
  de un jefe a la meca** los decide el host; la reacción la hacen todas y el empujón y la caída, la máquina de su dueño
  (`BodyNet.relay_hit`). **Agarrada**, la simula el host mientras la lleva y la revolea, y se la devuelve al que la
  manejaba cuando vuelve a estar parada (`borrow`, `give_back`).
- Test: `tests/net_check.tscn`, dos instancias (`--host-local` y `--join-local`). La meca: `tests/mech_net_check.tscn`
  (igual, con dos instancias): el otro la toma y la maneja (camina, dobla, se agacha, salta y hace un dash) y las dos
  la ven en el mismo lugar al centímetro (el motor, el rumbo y la caja); el host la sigue sin saltos (a lo más 0,3 m
  en un paso, en el dash). El jefe: `tests/boss_net_check.tscn` (dos instancias): el otro maneja la meca, el jefe la
  ataca (la tira, la agarra y la revolea) y después el otro lo mata: las dos ven al jefe muerto en el mismo lugar y en
  6 pedazos, y la meca en el mismo lugar, con la misma vida y el mismo dueño.
  Los brazos: `tests/arms_net_check.tscn` (igual): el otro dispara ráfaga y súper y tira dos piñas, y las dos máquinas
  cuentan los mismos tiros y piñas y la misma energía; la piña propia del host, sin ser dueño, no sale.
