# La base común de las mecas (pendiente)

Lo que van a compartir **la meca propia** y **las mecas enemigas (los jefes)**. Todavía no está separada: hoy vive
adentro de `Mech` (ver [[estructura]] y [[pendulo]]). Esta nota junta lo acordado, para decírselo a quien haga la meca
y a quien haga los jefes cuando arranquen.

## Qué es
**Un solo cuerpo físico** que se inclina, pierde el equilibrio y recibe golpes. Nada más. El usuario (13/11/2026): «los
jefes van a heredar una clase abstracta que comparten con la meca propia, que es todo el sistema de equilibrio… un
cuerpo físico que se inclina y pierde equilibrio»; y a la vez «no quiero correr el riesgo de limitarme por compartir
demasiado… las mecas de jefes tal vez puedan llegar a tener cosas más locas».

## Qué NO es (son piezas que cada uno elige o reemplaza)
- **El medio de moverse**: dos piernas, cuatro, ruedas, o volar.
- **Los brazos** o lo que tenga para pegar.
- **La cabina** y el marco para caminar adentro: sólo la meca propia.
- **Quién la maneja**: las teclas, las consolas, o el cerebro de un jefe. Todos escriben «lo que se le pide».

Por eso conviene armarla **de piezas y no como una clase abstracta larga**: un jefe raro arma lo suyo sin heredar nada
que lo limite.

## Para tener en cuenta al diseñarla
- **Las piernas no siempre salen de la pelvis.** En algunos van **en el cuerpo físico mismo**: una araña larga con las
  patas saliendo de los costados, en vez de abajo (el usuario, 13/11/2026). Hoy `MechLegs` cuelga las dos piernas de una
  pelvis debajo de la caja; la pieza de las piernas tiene que poder decir **de dónde sale cada pata** —de una pelvis o de
  puntos del cuerpo— y cuántas son. «Es un detalle mínimo, pero se puede estandarizar.»
- **El equilibrio es el péndulo** (el cuerpo sobre un punto de apoyo que lo sigue): con cuatro patas o con ruedas, lo
  que cambia es cómo se dibuja y qué tan rápido lo alcanza el apoyo, no la regla.
- **Todo se mueve con fuerzas e impulsos**, nunca por código.
- **Los brazos simulados** (`MuscleArm`) se guardan por si sirven para un jefe.

## Quién
La separa quien tiene la visión general, antes de que arranquen las sesiones de la meca y de los jefes; después es de
la sesión de la meca, y la de jefes la usa y pide cambios.
