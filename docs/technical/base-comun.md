# La base común de las mecas

Lo que comparten **la meca propia** y **las mecas enemigas (los jefes)**: `BalanceBody`, en `game/balance_body/`
(separada de `Mech` el 13/11/2026; ver [[estructura]] y [[pendulo]]). La meca propia hereda de ella; un jefe también.
Esta nota junta lo acordado, para quien haga la meca y quien haga los jefes.

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
  patas saliendo de los costados, en vez de abajo (el usuario, 13/11/2026). Hoy `BodyLegs` cuelga las dos piernas de una
  pelvis debajo de la caja; la pieza de las piernas tiene que poder decir **de dónde sale cada pata** —de una pelvis o de
  puntos del cuerpo— y cuántas son. «Es un detalle mínimo, pero se puede estandarizar.»
- **El equilibrio es el péndulo** (el cuerpo sobre un punto de apoyo que lo sigue): con cuatro patas o con ruedas, lo
  que cambia es cómo se dibuja y qué tan rápido lo alcanza el apoyo, no la regla.
- **Todo se mueve con fuerzas e impulsos**, nunca por código.
- **Los brazos simulados** (`MuscleArm`) se guardan por si sirven para un jefe.

## Cómo se usa
Un cuerpo nuevo hereda de `BalanceBody`, pone su `size` y su masa en `_init`, y redefine tres ganchos: `_build` (arma sus
piezas: cerebro, armas, otro medio de moverse), `_think` (al empezar cada paso escribe lo que se le pide) y
`_after_step`. Puede llevar sus propias perillas (`knobs`, un `BodySettings`).

**Lo que falta**: la pieza de las piernas todavía es una sola, `BodyLegs` (dos patas desde una pelvis). Las patas que
salen del cuerpo, las cuatro patas o las ruedas son otra pieza que hay que poder elegir en `_build`; hoy el cuerpo arma
siempre `BodyLegs`.

## Quién
Es de la sesión de la meca; la de jefes la usa y le pide cambios.

## Las curvas de los movimientos discretos (14/11/2026)
`MoveCurve` y `MoveRamp`, en `game/balance_body/`. Las escribió el módulo Jefes para rodar hecho bola; son de la base
común para que las use todo movimiento discreto (el usuario: «si yo hago un dash… y lo tengo activado con easing, que
haga easing»).
- **Una curva** (`MoveCurve.Shape`: lineal, arranca lento, frena al final, o las dos) es la forma en el tiempo de un
  movimiento que ya tiene sus números.
- **De un tramo** (el dash, el salto, una carga: tantos metros en tantos segundos): `MoveCurve.velocity` da la velocidad
  en cada momento.
- **Sostenidos** (caminar, rodar): `MoveRamp` sube hacia la velocidad pedida en un tiempo, con su curva, y baja al
  soltar en otro, con la suya. Es continua: cambiar de pedido a mitad de camino no salta. Una bajada larga es la inercia.
- Hoy la usa sólo el jefe bola (rodar). Falta que la usen el dash, el salto y caminar de la meca.
