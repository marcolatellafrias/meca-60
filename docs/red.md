# La red

`game/net/` (de character-parametric) · fila **Multijugador** · ver [[filas]]

- `SessionManager`, `NetSpawner`, `CharacterSpawner`, con GodotSteam.
- En la fila: **H** abre sesión en esta compu y otra instancia se une con **J**; **G** por Steam; **K** menú de inicio
  para unirse por código; **L** sale.
- Van por la red los personajes y los objetos de esa parcela; **las mecas todavía no**.
- Test: `tests/net_check.tscn`, dos instancias (`--host-local` y `--join-local`).
