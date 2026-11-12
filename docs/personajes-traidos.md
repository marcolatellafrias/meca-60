# Lo traído de character-parametric

`game/character/`, `game/interactables/`, `game/objects/`, `game/common/`… y la frontera en `game/character_port/`
(su `LEEME.md` dice qué se trajo y dónde se cortó). **No se edita**: si cambia allá, se vuelve a copiar.

- **El jugador** es el personaje de allá: ente (sin cuerpo, **V** vuela) o cuerpo con **B** (el gordo atlético).
- Agarrar (clic izquierdo), sentarse (**E**), empujar (**R**).
- Fila **Personajes**: los seis arquetipos, que se caen y se levantan (`CharacterGetUp`). Fila **Objetos**: paquetes y
  una silla.
- Test: `tests/player_check.tscn`.

Ver también [[red]].
