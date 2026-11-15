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
