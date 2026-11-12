# Los proyectiles y la arena de esquivar

`game/projectiles/` (`ProjectileField`, `Missile`) · `game/dodge_arena/` (`DodgeArenaArchetype`, `MissileTurret`) ·
fila **Arena de esquivar** · ver [[filas]] y [[meca]]

## Los proyectiles (13/11/2026)
Son **piezas para reusar**: los van a usar los jefes y las armas de la meca propia (el usuario: «esto después lo vamos
a reusar… que soporte sincronización online, y también podrías usar las partículas»).

- **Un proyectil es una trayectoria conocida**: de dónde sale, adónde cae y cuánto tarda. Cada máquina lo dibuja sola;
  por la red va **un mensaje por proyectil**, no posiciones.
- **Lanzar se le pide al host** (`ProjectileField.launch`, desde cualquier máquina): él le pone un número y lo anuncia a
  todos. Lo que se ve (la marca, la estela, la explosión) lo hace cada máquina; **lo que hace** (el empujón) lo aplica
  sólo el host.
- El `ProjectileField` tiene que estar en el mismo lugar del árbol en todas las máquinas (un hijo fijo de la parcela o
  del mapa).
- **El de mortero** (`Missile.Kind.MORTAR`): sube derecho, se va alto y cae de arriba sobre su punto. **La marca**: un
  círculo en el piso desde que sale, y adentro otro que crece hasta llenarlo justo cuando cae. La estela es el humo
  de propulsor de la fila Partículas; la explosión, su destello, sus chispas y su polvo.
- **El empujón**: a todo lo suelto en la columna sobre el círculo le cambia la velocidad hacia afuera (10 m/s en el
  centro, nada en el borde). No hay daño: a la meca, su péndulo decide si se inclina o se cae.

## La arena de esquivar
Para probar con algo real cómo se siente mover la meca (el usuario: «lo tengo que testear con algo real, que es
esquivar»). Un redondel de 95 m de radio con un muro de 12 m (más alto que donde empieza la caja: un muro bajo le
pasaría por abajo), **una torre al medio** que no es un jefe, y la Meca discreta.

- **Cada 3,2 s una andanada** de cinco: uno donde está la meca, uno donde va a estar si sigue igual (quieta, al azar) y
  tres al azar alrededor. Tardan 2,8 s en caer. Decide sólo el host.
- **P** prende y apaga la torre; **U** sube al jugador; **O** posee la meca; **F1** y **F2**, los de la meca.

Medido (13/11/2026): quieta, de cinco la agarran uno o dos; corriendo en círculo, de veinte la agarran entre dos y
cinco; un golpe en el centro la inclina unos 7°, y dos juntos la tiran.

## Lo que falta
- Probar la red con dos instancias (`--host-local` y `--join-local`): está hecho para eso, todavía sin probar.
- Quien se une a mitad de una andanada no ve los misiles que ya estaban en el aire.
- El misil explota en el piso: si cae sobre la meca, atraviesa la caja el último instante.

Test: `tests/dodge_arena_look.tscn` (unos 25 s, sin el sandbox).
