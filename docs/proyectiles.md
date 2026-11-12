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

## Las zonas que pegan — TRABAJO EN CURSO (13/11/2026)
`AreaStrike`: lo básico para probar cómo se mueve la meca; **se reformula** cuando se piensen de verdad los ataques de
los jefes (el usuario: «prefiero que hagas lo básico y después se lo reformula… que quede marcado como work in
progress»). Separa **la forma** (lo que dice cómo moverse) de **lo que pasa adentro** (el elemento): hoy el elemento es
sólo cómo se ve (explosión, fuego, eléctrico) y todas empujan igual; qué le hace cada uno a la meca se decide cuando
estén la energía y las roturas. Los ataques de cada jefe (y los melee, los proyectiles que se saltan, la sierra que te
hace agachar…) son del módulo de Jefes.

- Va por la red como los misiles: una descripción (`spec`) que se cumple sola con el tiempo; empuja sólo el host.
- **Quietas** (círculo, dona, franja): la marca desde que aparecen, lo de adentro crece hasta llenarla y ahí estalla.
- **Que avanzan** (onda que se abre, pared que cruza): **pegan sólo a lo que pisa el piso**; una meca en el aire pasa
  por arriba.
- Lo que agarra un golpe se busca sin tope: lo fijo (el muro, la cabina) llenaba el cupo de la consulta y la meca
  quedaba afuera (`AreaStrike.loose_in`).

## La arena de esquivar
Para probar con algo real cómo se siente mover la meca (el usuario: «lo tengo que testear con algo real, que es
esquivar»). Un redondel de 95 m de radio con un muro de 12 m (más alto que donde empieza la caja: un muro bajo le
pasaría por abajo), **una torre al medio** que no es un jefe, y la Meca discreta.

- **F3 elige el ataque** (`MissileTurret`): lluvia de misiles (cada 3,2 s, uno donde está la meca, uno donde va a
  estar y tres al azar), círculo gigante (4,5 s de aviso), dona (acercarse), ondas (saltarlas), lanza (un paso al
  costado), alfombra de misiles (caen en fila) y pared que cruza (saltarla), o todos de a uno. Decide sólo el host.
- **P** prende y apaga la torre; **U** sube al jugador; **O** posee la meca; **F1** y **F2**, los de la meca.
- Medido con la meca quieta: cada ataque la inclina entre 10° y 21°; el círculo gigante (14 m/s) la tira.

Medido (13/11/2026): quieta, de cinco la agarran uno o dos; corriendo en círculo, de veinte la agarran entre dos y
cinco; un golpe en el centro la inclina unos 7°, y dos juntos la tiran.

## Lo que falta
- Probar la red con dos instancias (`--host-local` y `--join-local`): está hecho para eso, todavía sin probar.
- Quien se une a mitad de una andanada no ve los misiles que ya estaban en el aire.
- El misil explota en el piso: si cae sobre la meca, atraviesa la caja el último instante.

Test: `tests/dodge_arena_look.tscn` (unos 25 s, sin el sandbox).
