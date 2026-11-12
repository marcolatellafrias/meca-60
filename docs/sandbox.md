# El sandbox

`game/sandbox/`

- **Filas** de parcelas: `DesignSandbox.categories()`. Cada parcela es un `SeededArchetype` (`build`, `max_footprint`,
  `describe`, `parcel_options`). Lista completa en [[filas]].
- **Paredes invisibles** (`SandboxParcel`): capa `PARCEL_BOUND`; las ve lo que se mueve con física dentro de la parcela.
  El jugador y la bola pasan. Lo que se mueve por código pregunta `SandboxParcel.holds`.
- **Paneles F por fila** (`TunerPanel`, como en character-parametric): se montan en `_mount_tuners`; abren parado en su
  fila, a la izquierda. Las propiedades exportadas de un `Resource` se vuelven deslizadores.
- **La bola** (`TestBall`): **J** tira, **K** pasa por los tiros de la fila (`ball_shots`) o por sus fuerzas
  (`ball_pushes`). Sin gravedad, sin rebote, choca sólo con la capa 1.
- Teclas a no repetir: WASD, espacio, shift, Ctrl, E, R, C, V, B, F1–F6, Escape.
