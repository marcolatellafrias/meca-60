# Las maquetas de jefes

**14/11/2026, módulo Jefes.** Bocetos de arcilla, quietos, para pensar con el usuario jefes con **puntos débiles**,
**fases** y **ataques de área**. Todavía no se mueven ni pelean: son para mirar, elegir y refinar. El código está en
`game/bosses/maquettes/`: `BossMaquettes` (las seis y su arcilla) y `BossMaquetteArchetype` (una parcela cada una). Están
en la fila **Maquetas de jefes**, debajo de la del Jefe bola, y se miran con `tests/boss_maquettes_look.tscn` (con
ventana, unos 15 s: cada una de frente y desde arriba).

El usuario: «un sistema en el que los bosses tienen puntos débiles… si me tiro con un personaje… desconectar algún cable
o sacarle un core… mucho risk y mucho reward. Si voy a pie y me tiro desde un punto alto y justo encajo, puedo llegar a
matarlo desde cerca»; «varios ciclos… caminando, pero después tal vez va volando… por tiempo o por threshold de vida…
cuando le rompe las alas se cae y va caminando… modo frenzy»; ataques «menos físicos y más bien poderes de AoE»;
«empecemos con muchas maquetas de clay». El jefe bola «no va mucho con esa idea».

## Cómo se hacen los jefes (15/11/2026, con el usuario)
**Hechos a mano, con variaciones**, no procedurales: «los bosses más diseñados a mano, pero con ciertas variaciones para
que si lo peleás varias veces sigue siendo interesante… vamos a empezar a diseñar de a poco personajes y vamos a ver cómo
se siente». Los dos que siguen, en paralelo: **el jefe bola** (el punto débil, el núcleo abajo, entre las patas; normal y
hecho bola) y **uno humanoide** (patas y brazos cuadrados, con cabeza, más alocado que la meca propia; normal y con ira).
**Los poderes son discretos o mixtos**: un golpe físico que dispara algo claro (una onda, una línea, una zona) con su
aviso, su forma y su efecto (daño por código y, a veces, un empujón o una caída). La lista para elegir está en la charla
del 15/11/2026; todavía no está confirmada.

## El jefe bola, rediseñado (15/11/2026; acordado, sin hacer)
- **Una cabeza de disco** (como la de la Tenaza), con el ojo. **Sin rendija ni cañón**: sus armas son los tentáculos y el
  ojo («lo único que tiene como armamento son los tentáculos y el ojo… se elimina todo lo de la rendija»).
- **El punto débil: el núcleo abajo de la bola, entre las patas**; se llega caminando («te la jugás, no tenés que saltar
  desde ningún lado, pero es complicado»).
- **Dos estados**: normal y hecho bola.
- **Los poderes** (de la lista del 15/11/2026; fuera la succión, la erupción en línea y el pulso desde abajo): el pisotón
  con onda, el agarre con un tentáculo, el láser de los ojos, el modo bola (embestir), el remolino de los tentáculos y el
  salto aplastante.

## Las siluetas del humanoide (15/11/2026)
`HumanoidMaquettes`, primeras en la fila: seis siluetas de meca, de cajas (los miembros cuadrados, con cabeza), normales y
con ira (otro color, los ojos rojos, las rejillas al rojo, las toberas prendidas). El usuario: «tiene que parecer una
meca… inspirarte de las mecas… medio un trope». **Gorila** (encorvado, brazos largos, ojo único), **Caballero** (erguido,
cresta en V, falda de placas), **Luchador** (ancho, la cabeza hundida, chimeneas), **Tanque** (una caja con puños de
bloque y una cúpula), **Duelista** (alto, rodillas para atrás, hojas en los antebrazos, aletas) y **Torre** (todo arriba,
hombreras gigantes, patas chicas). Con ira tendrá un solo estado más.

## Con personalidad (15/11/2026): la misma base, seis caracteres
**Lo acordado con el usuario**, después de las recorribles («son medio monotemáticos, son básicamente un cañón con
patas»):
- **Primero un jefe divertido; después los puntos débiles y las plataformas.** «Primero vamos a lo base, a hacer un boss
  divertido que no sea tan monotemático… distintas formas de moverse que puedan cambiar en base a la fase, y distintas
  formas de atacar… distintas armas en distintos brazos… a qué brazo nos conviene romperle primero».
- **La base: cuatro patas, dos brazos y un accesorio en el techo**, con formas simples, no de insecto.
- **Las baterías, unificadas con la meca, para después**: una por componente (las patas, cada brazo, el techo; si tiene
  más brazos, más baterías), **siempre en el mismo lugar**. Sacarle una lo vuelve más lento o inestable, o ese brazo más
  torpe. Nada de buscarlas: lo difícil es llegar a pie sin morirse. Las de 1 a 3 por jefe, no muchas.
- **Lo de recorrer** (trampolines de energía, escaleras de vez en cuando, que se sienta ajeno) **queda para más adelante**.

Están en `ArmedMaquettes`, primeras en la fila: un kit (torso, patas, armas, techo, cabeza, pecho) y una ficha por jefe.
A la izquierda el normal; a la derecha **con ira**: cambia de color, cambia la pose (cómo se mueve en esa fase) y se le
prende lo suyo.

| Jefe | Brazo izquierdo | Brazo derecho | Techo | Lo suyo | Con ira |
|---|---|---|---|---|---|
| **Fogonero** (caja, patas columna) | martillo: golpe al piso con onda | lanzallamas: un cono adelante | chimeneas | el horno del pecho, caños de escape | abre el horno, se pone al rojo, escupe brasas y embiste agachado |
| **Vigía** (alto, patas largas) | escudo: se cubre y empuja | cañón largo | radar: marca dónde cae el tiro | la cabeza con ojos que tiran láser | tira el escudo, se agacha con las patas abiertas, salta de costado; láser |
| **Tenaza** (**la elegida**; un disco en patas de cangrejo) | pinza grande: agarra a la meca | pinza chica: cortes rápidos | lanzacohetes: otro disco atrás, con los tubos al ras | la cabeza, otro disco, con los ojos en una tira roja | pinzas arriba, abiertas; se agacha y corre de costado sin dejar de mirarte |
| **Minero** (cuña, orugas) | garra: tira rocas | taladro: embiste | reflector que encandila | rueda en vez de caminar | se clava con el taladro y salen grietas alrededor |
| **Campanario** (cúpula, patas de perro) | horquilla: un rayo de punta a punta | bola con cadena | bobina | el núcleo celeste del pecho | recoge las patas y flota sobre un anillo; la bobina tira rayos al piso |
| **Artillero** (caja baja, patas de perro) | sierra | ametralladora | lanzamisiles | ágil, corre y frena | se planta (clava las patas) y es una torreta: dispara todo |

**La Tenaza es la elegida** (15/11/2026; el usuario: «el que yo pienso con el que podríamos ir»). Sus cambios, pedidos por
él: las dos pinzas nacen del frente («ahora mismo es como que se están cruzando con las piernas»); el cuerpo, un disco en
vez de una caja; la cabeza, otro disco, con los ojos como una tira recortada, rojos; otro color (marfil; con ira, rojo
oscuro); el lanzacohetes de atrás, más integrado a la forma (otro disco, con los tubos al ras). Con ira ya no se da
vuelta: corre de costado mirándote, como un cangrejo.

## Las recorribles (15/11/2026): el hexápodo y el cuadrúpedo
El usuario, de la primera tanda: «muy simplistas… no se dan mucho a espacios a recorrer a pie… tienen que tener algo de
recorrido, algo de interés… una silueta más o menos simple»; «una de 6 patas y otra de 4»; «los puntos débiles sean
básicamente las baterías y los componentes que se dan a ver solamente a veces… a pie tenés que timear para cuando esté
abierta una compuerta… y sacarlo». Están en `WalkerMaquettes`, primeras en la fila.
- **La silueta es simple** (un casco sobre patas), **pero el cuerpo es un lugar**: cubiertas, pasarelas con baranda,
  escaleras y una rampa, a la escala de una persona. Al lado, un edificio para tirarse. **El recorrido va en celeste.**
- **Los puntos débiles son baterías detrás de compuertas**: cerradas casi siempre (el estado de la izquierda); se abren
  un rato después de un ataque fuerte suyo (el de la derecha). **Una batería por pata**, en las pasarelas; **la del
  cañón**; **el núcleo**, en lo más alto. Y **una compuerta grande al frente, a la altura de la meca**: la de la meca.
- **Hexápodo plataforma**: largo (50 m), la cubierta a 26 m. Se cae en la cubierta baja de atrás (la plataforma de luz);
  una escalera sube a la cubierta, otra baja a la pasarela de cada lado (tres compuertas por lado, una por pata), y la
  de la torre sube al núcleo. Las compuertas se abren después del pisotón (la onda roja).
- **Cuadrúpedo bastión**: más alto y compacto, en pisos. Se cae en la cubierta (29 m); una rampa baja a la pasarela de
  alrededor (una compuerta por pata), una escalera sube al segundo piso (la batería del cañón, a los costados) y otra a
  la torreta (el núcleo). Las compuertas se abren después del cañonazo.
- *Pensado y todavía sin ver: subido, al rato se sacude (agarrarse o bajarse); si la meca se queda pegada mucho tiempo,
  carga un pulso que la aleja.*

## Cómo se leen
- Cada parcela tiene **dos estados**, uno al lado del otro: a la izquierda el primero, a la derecha el que viene después
  (la fase rota, caída o enojada).
- **Naranja que brilla**: un punto débil (un núcleo, una unión de cables). **Naranja oscuro**: los cables.
- **Rojo transparente en el piso**: un ataque de área; un **anillo rojo** es una onda. Lo amarillo transparente, un rayo.
- **Celeste**: el recorrido a pie. **Bloque rojo**: la meca (18 m). **Muñeco amarillo**: una persona (1,8 m). **Torre gris**: un punto alto desde donde
  tirarse (con una persona arriba).

## La primera tanda, de seis (14/11/2026)
| Maqueta | Punto débil | Fases | Ataques de área |
|---|---|---|---|
| **Trípode faro** | el núcleo en la escotilla de arriba de la cabeza (sólo tirándose desde la torre); los cables de cada rodilla | cortados los cables de una rodilla, se traba; con una pata rota se arrodilla y la cabeza queda a tiro | el faro barre el piso con su luz; el pisotón, una onda |
| **Polilla** | las raíces de las cuatro alas, con sus cables (desde lo alto, cuando pasa cerca) | vuela en círculos; rotas dos alas, se cae (por vida) y camina en seis patas, con la panza y su núcleo a la vista | columnas que caen en fila desde arriba |
| **Caracol fortaleza** | el núcleo en la chimenea de arriba de la caparazón: caer adentro, desde lo alto | con poca vida se mete en la caparazón, se agrieta y brilla por las grietas (frenesí): gira y empuja | golpea el piso y salen anillos que hay que saltar; alrededor, una zona que quema |
| **Relicario** | tres nodos que le dan vueltas, atados con cables (bajos, pero giran) | rotos los tres, se cae y queda como una rampa: se sube caminando hasta el núcleo de la punta mientras se levanta | círculos en el piso que explotan después de un rato; rayos que bajan |
| **Ciempiés de vagones** | los enganches de arriba entre vagón y vagón, subiéndose al lomo | desenganchado uno, se parte en dos más chicos que pelean aparte, más rápido | la cola deja una línea que quema; los vagones barren al doblar |
| **Colmena colgante** | los cables de la bolsa que cuelga debajo: hay que meterse donde pisa | cortada la bolsa, frenesí: se agacha, pisa más rápido y el núcleo cae al piso | debajo, el pisotón; de la bolsa caen gotas que dejan charcos |

## Lo que se repite (para pensar el sistema)
- **Un punto débil es un lugar del cuerpo, no un número**: se llega a pie (subiéndose, tirándose de lo alto, metiéndose
  debajo) o con la meca. Cerca de él hay un ataque que castiga quedarse (el riesgo).
- **Se abre un momento** (15/11/2026; el usuario: «también puede ser algo que se abra momentáneamente, que es lo que
  pasa generalmente»): casi siempre está tapado, y se destapa en una ventana corta, que es cuando hay que estar ahí.
  Propuesta para cada maqueta, sin hacer: la escotilla del Trípode se abre para ventilar después de barrer con el faro; las
  alas de la Polilla se despliegan del todo al tirar las columnas; la chimenea del Caracol se destapa para soltar vapor
  después de los anillos; los nodos del Relicario bajan y se quedan quietos mientras carga los círculos; los enganches del
  Ciempiés se estiran y se ven al doblar; la bolsa de la Colmena se abre para soltar las gotas.
- **Las fases cambian por algo que se rompe** (una pata, las alas, la bolsa, los nodos) o por la vida, y cambian cómo se
  mueve y qué queda expuesto.
- **El frenesí** es una fase más: más rápido, más ataques, y se ve (brilla, se pone rojo).

Falta: elegir con el usuario cuáles siguen, y de esas, qué se prueba primero (el punto débil a pie, una fase, un ataque
de área).
