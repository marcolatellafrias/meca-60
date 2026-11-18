# El flujo de la partida (en red)

**Plan** (18/11/2026). Lo que hace falta para jugar online, del menú a la pelea con el jefe, y de quién es cada pieza. Ver
[[red]], [[sucursal]], [[base]], [[interfaz]], [[progresion]].

## Las reglas
- **El sandbox es un reflejo modular del juego** (el usuario, 18/11/2026: «el sandbox siempre debería ser un reflejo
  modular de las cosas que están en el juego»). El juego y el sandbox **arman las cosas con el mismo código y leen las
  mismas perillas guardadas**: la base del juego llama a lo mismo que la parcela Base (`BaseLayout`, `BaseSettings`).
  Lo que se mueve en un F1 del sandbox cambia el juego.
- **Los guardados que usa el juego van al repositorio**, pero sólo cuando el usuario dice que ese valor va (hasta
  entonces son suyos y no se commitean). Si no están, el juego arma con los valores por defecto.
- **El host es el capitán** y la autoridad: el estado de la sucursal vive en el host; los demás piden y el host aplica.
- **La meca va por la red** (BodyNet, de Jefes; los brazos y la energía, de Armas): en la base ya no está congelada.
  *Hasta el 19/11/2026 fue decorado quieto («está bien si queda la meca sin interacción»), mientras no viajaba.*

## Los pasos
1. **La escena de la base del juego** (`game/base/base_world.tscn`, `BaseWorld`): la base armada con `BaseLayout`, la
   meca jaula congelada en el elevador y la luz. Es un mundo de la red (grupo `net_world`) con su `CharacterSpawner`.
   «Crear partida» y «unirse» llevan acá (el sandbox de pruebas sigue en su botón). — *Mundo*, **hecho**. Como en
   character-parametric, la sesión arranca con «crear partida» (`SessionManager.host`) y el mundo, al cargar, avisa
   (`world_ready`) y nace el jugador (`CharacterSpawner`). Para mirarla: `tests/base_world_look.tscn`.
2. **Aparecer en la esclusa**: los personajes nacen adentro (`BaseWorld.start_point`). — *Mundo*, **hecho**, mirando a la
   compuerta. **El botón abre la compuerta para todos**: lo aprieta el capitán y el
   host la abre en todos (`BaseAirlock._open`); el pedido de otro no hace nada. — *Mundo*, **hecho**. **Abrir la esclusa
   empieza la partida y desde ahí no se une nadie más** (el usuario: «no se puede unir alguien una vez iniciada la
   partida, la partida se inicia al abrir la compuerta inicial»): el lobby de Steam deja de aceptar y al que igual se
   conecte el host lo rechaza y vuelve al menú con el aviso (`SessionManager.close_to_new_players`). Para probarlo:
   `tests/base_net_check.tscn` con `-- --tarde` en el host.
3. **El estado de la sucursal compartido**: la plata, el depósito, lo puesto y el contrato (`BaseState`) viven en el
   host y llegan a todos (`BaseSync`: al que llega, una foto entera; después, la foto a cada cambio). — *Mundo*,
   **hecho**.
4. **El capitán**: es el host (`BaseState.is_captain`). Sólo él compra, pone, saca, firma y sale a la arena; los demás
   ven las terminales, no pueden arrastrar y los botones están tramados («lo decide el capitán»). «Salir a la arena»
   abre la compuerta del techo en todos (`BaseSync.open_hatch`). — *Mundo*, **hecho**. Para probar con dos
   instancias: `tests/base_net_check.tscn` (`--host-local` y `--join-local`).
5. **La meca por red**: posición, piernas, brazos, puestos. — *Meca*, cuando la cierre.
6. **La meca armada para los que son**: al abrir la esclusa, el host cuenta los jugadores y en todas las máquinas la
   meca se rearma para ellos (`CageShape.crew`: 1, 2 o 3 puestos; con más, la de 3), en `BaseWorld._crew_aboard`. —
   *Mundo*, **hecho** (probado con dos instancias: las dos la ven para 2, en el mismo lugar).
7. **La salida a la arena, por el ascensor** (el usuario, 19/11/2026: «el sistema este de compuertas… es básicamente
   para ocultar cosas y poder cargar cosas sin que los jugadores le vean»). El cuadrado del elevador es una plataforma
   (`BaseElevator`) con un pedestal y su botón en la esquina, y un cartel que dice qué falta (el contrato, los que no
   subieron, o «listo»). Con el contrato firmado y **todos arriba**, el capitán aprieta: sube una **baranda** por el
   borde (que nadie se tire), se abre la compuerta del techo, la plataforma sube por **el pozo** (`BaseLayout._shaft`,
   su largo es una perilla del F1) y se abre **la segunda compuerta**, la del piso de la arena. Al arrancar, **la arena
   se arma arriba** (`BaseWorld._build_arena`: el mapa de pelea con **el hueco del ascensor** en el medio,
   `Battlefield.build(hole)`, y el sol); la plataforma llega a ras de su piso y la baranda baja. En red lo dispara el
   host en todos (`BaseSync.launch`) y cada máquina lo anda con los mismos tiempos. Los contratos sólo firman (el
   «salir a la arena» de la terminal se fue). — *Mundo*, **hecho**. Probado: `tests/base_launch_look.tscn` (capturas)
   y `tests/base_net_check.tscn` (los dos suben y se ven arriba, con la meca). **El jefe del contrato** se arma
   con la arena, igual y con el mismo camino en todas las máquinas (`Arena/Jefe/Luchador`, `BaseWorld._spawn_boss`), a
   50 m de la boca, dormido hasta que el ascensor llega; su blanco es la meca, que recibe su vida. Por ahora el único
   jefe hecho es el Luchador y hace de todos los contratos (su barra lleva el nombre del contrato); su letrero de
   prueba del sandbox, en la partida, no se ve. *Falta*: los recursos del mapa (todavía no van por la red) y el hueco a
   los costados en lugar del medio.
8. **El jefe por red**. — *Jefes*, **hecho** (18/11/2026; ver [[red]]): el jefe lo simula el host y las demás siguen su
   cuerpo; la vida la decide el host y la muerte (con su ragdoll) pasa en todas; los golpes del jefe a la meca los
   decide el host y el empujón lo hace la máquina de su dueño. Lo que se ve de sus ataques también llega a todas.
9. **La vuelta**: la paga del contrato a la plata de la tripulación, lo que vuelve de la arena (ver [[progresion]]). —
   *Mundo*.

## Abierto
- Si el host se va, se termina la partida ([[progresion]]): volver al menú con el aviso.
