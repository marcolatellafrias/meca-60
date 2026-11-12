class_name SoundCatalog

## EL CATÁLOGO DE CLAVES DE SONIDO: una fila por sonido del juego, que dice CÓMO SUENA. Agregar un sonido es agregar una
## fila acá y pedirla desde la clase que suena, en su constante `SOUNDS` (ver SoundEntity: ahí se dice CUÁNDO suena —el
## evento, el estado, el movimiento— y con qué capas, corte y continuidad). La fila Sonidos del sandbox la muestra (ver
## SoundParcelArchetype), igual que el panel de sonidos de cada parcela (F1, ver SoundPanel). Ver
## docs/technical/audio.md.
##
## Cada fila dice:
##
##   · `key` — la clave, en minúscula y sin acentos: es también el NOMBRE DEL ARCHIVO.
##   · `category` — la carpeta: el archivo va en `assets/audio/<category>/<key>.ogg` (o `.wav`). Los que empiezan con la
##     clave y un guion bajo (`<key>_1.ogg`, `<key>_mercado.wav`…) son más archivos de la misma clave, que se alternan
##     al azar sin repetir el anterior (ver Sounds.files).
##   · `bus` — Efectos, Ambiente o Música (ver Sounds.BUSES y default_bus_layout.tres).
##   · `test` — el sonido de prueba al que cae mientras no haya archivo (ver TestSounds.KINDS); "" es que no tiene, y
##     sin archivo no suena nada.
##   · `title` — cómo se llama para una persona.
##   · `use` — PARA QUÉ SE USA, en una línea: lo que dice el panel de sonidos para elegir qué archivo va.
##
## QUIÉN LA PIDE no se escribe acá: sale de las constantes `SOUNDS` de las clases (ver SoundEntity.askers), así que no
## hay una segunda lista que se desactualice.
##
## Opcionales: `loop` (para lo que no tiene sonido de prueba; si no, lo dice el de prueba), `db`, `unit` y `max` (el
## volumen y el alcance, si no son los del de prueba; el volumen lo pisa la mezcla guardada, ver Sounds.mix_db),
## `fallback` (lo que suena sin archivo cuando no es un sonido de prueba sino otra cosa: la melodía de notas de la
## radio), `ref_hz` (las notas: a qué frecuencia está grabado el archivo, y cada nota lo sube o lo baja: un archivo por
## instrumento, las notas salen del código), `test_pitch` (el tono del de prueba, sólo para distinguirlo de otro que
## comparte el mismo: con archivo es 1), `random_pitch` y `random_db` (cuánto varía cada vez), `pending` (qué falta
## para que el juego lo pida) y `alternatives` (LLEVA VARIOS ARCHIVOS: soltar uno en el panel lo suma en vez de
## reemplazar el que hay; lo decidió el dios del juego el 11/10/2026 para los eventos del ambiente, los pasos, los
## golpes de paquete y los choques, lo que se oye muchas veces seguidas), `playlist` (UNA LISTA DE CANCIONES: sus
## archivos suenan uno tras otro, en el orden de sus nombres, sin sortear —las emisoras de la radio—; soltar uno lo
## suma) y `variants` (LLEVA VARIANTES CON NOMBRE:
## `timbre_dingdong.ogg`, `timbre_ring.ogg`…; cada objeto suena siempre con una, la suya —ver SoundEntity.sound_variant—,
## y no al azar como las alternativas; soltar una en el panel la suma. Lo decidió el dios del juego el 11/10/2026).

const ROWS := [
	# ── Lo que se toca: un golpe por acción ──────────────────────────────────────────────────────────────────────────
	{"key": "boton", "category": "controles", "bus": "Efectos", "test": "click", "title": "Botón y tecla: apretar",
		"use": "apretar un botón, una tecla o el manipulador Morse (al bajar el clic)"},
	{"key": "boton_suelta", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Botón y tecla: soltar", "use": "soltar un botón, una tecla o el manipulador Morse (al subir el clic)"},
	{"key": "palanca", "category": "controles", "bus": "Efectos", "test": "click", "title": "Palanca",
		"use": "una palanca o un interruptor que llega al fondo o cambia de posición"},
	{"key": "interruptor_sube", "category": "controles", "bus": "Efectos", "test": "click", "title": "Interruptor: subir",
		"use": "el interruptor de palanca que pasa a ARRIBA (encendido): al clic o al llegar al tope, lo que diga su toggle"},
	{"key": "interruptor_baja", "category": "controles", "bus": "Efectos", "test": "click", "test_pitch": 0.8,
		"title": "Interruptor: bajar",
		"use": "el interruptor de palanca que pasa a ABAJO (apagado): al clic o al llegar al tope, lo que diga su toggle"},
	{"key": "palanca_corre", "category": "controles", "bus": "Efectos", "test": "", "loop": true,
		"title": "Palanca que se corre",
		"use": "el roce de una palanca o un fader mientras se mueve (en loop; sigue donde quedó al volver a moverla)"},
	{"key": "perilla", "category": "controles", "bus": "Efectos", "test": "click", "title": "Perilla y rueda",
		"use": "el tic de cada posición al girar una perilla, una rueda o el fichero"},
	{"key": "rueda_derecha", "category": "controles", "bus": "Efectos", "test": "", "loop": true,
		"title": "Rueda y volante, a la derecha",
		"use": "una rueda o un volante girando a la derecha: el giro recorre el archivo, de tope a tope (o una vuelta)"},
	{"key": "rueda_izquierda", "category": "controles", "bus": "Efectos", "test": "", "loop": true,
		"title": "Rueda y volante, a la izquierda",
		"use": "una rueda o un volante girando a la izquierda: el giro recorre el archivo, de tope a tope (o una vuelta)"},
	{"key": "rueda_sola", "category": "controles", "bus": "Efectos", "test": "", "loop": true,
		"title": "Rueda que gira sola",
		"use": "una rueda o un mecanismo que gira sin mano —con la inercia, como un reloj— (en loop; sigue donde quedó)"},
	{"key": "manivela", "category": "controles", "bus": "Efectos", "test": "click", "title": "Manivela",
		"use": "el clic de cada diente al girar la manivela, y al patinar"},
	{"key": "tapa", "category": "controles", "bus": "Efectos", "test": "click", "title": "Tapa y escotilla",
		"use": "una tapa o una escotilla que termina de abrirse o de cerrarse"},
	{"key": "tapon_entra", "category": "controles", "bus": "Efectos", "test": "click", "title": "Cable: enchufar",
		"use": "la punta de un cable (o un pin) que entra en su conector"},
	{"key": "tapon_sale", "category": "controles", "bus": "Efectos", "test": "click", "title": "Cable: desenchufar",
		"use": "la punta de un cable (o un pin) que se despega de su conector"},
	{"key": "pieza_pone", "category": "controles", "bus": "Efectos", "test": "click", "title": "Pieza: ponerla",
		"use": "un pin o una pieza que se calza en el protoboard (o vuelve a su cajita)"},
	{"key": "pieza_saca", "category": "controles", "bus": "Efectos", "test": "click", "title": "Pieza: sacarla",
		"use": "un pin o una pieza que se saca del protoboard (o de su cajita)"},
	{"key": "tarjeta", "category": "controles", "bus": "Efectos", "test": "click", "title": "Tarjeta",
		"use": "meter o sacar una tarjeta perforada"},
	{"key": "pagina", "category": "controles", "bus": "Efectos", "test": "click", "title": "Página del manual",
		"use": "pasar una página del manual"},
	{"key": "libro_alza", "category": "controles", "bus": "Efectos", "test": "", "loop": false, "title": "Libro: alzarlo",
		"use": "levantar el manual de su lugar: el libro que se abre en las manos"},
	{"key": "libro_apoya", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Libro: acostarlo", "use": "el manual que vuelve a quedar acostado en su lugar"},
	{"key": "liquido_llena", "category": "controles", "bus": "Efectos", "test": "", "loop": true,
		"title": "Líquido que llena",
		"use": "un tubo o un tanque llenándose: el nivel recorre el archivo de vacío a lleno (en loop mientras sube)"},
	{"key": "liquido_vacia", "category": "controles", "bus": "Efectos", "test": "", "loop": true,
		"title": "Líquido que se vacía",
		"use": "un tubo o un tanque vaciándose: el nivel recorre el archivo de lleno a vacío (en loop mientras baja)"},
	{"key": "mapa_agarra", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Mapa: agarrarlo", "use": "el papel del mapa que se levanta y se abre en las manos"},
	{"key": "mapa_suelta", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Mapa: soltarlo", "use": "el mapa que vuelve doblado a su lugar"},
	{"key": "carrete", "category": "controles", "bus": "Efectos", "test": "click", "title": "Carrete del tragamonedas",
		"use": "cada carrete del tragamonedas que se frena"},
	{"key": "silla_sienta", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Silla: sentarse", "use": "sentarse en una silla o un asiento de la nave"},
	{"key": "silla_levanta", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Silla: pararse", "use": "pararse de una silla o un asiento de la nave"},

	# ── Genéricos: de nadie en particular, para usar donde haga falta (ver SoundEntity.GENERIC) ──────────────────────
	{"key": "foco_prende", "category": "avisos", "bus": "Efectos", "test": "", "loop": false,
		"title": "Foquito: prenderse", "use": "una lámpara indicadora que se prende: el tic del filamento"},
	{"key": "foco_apaga", "category": "avisos", "bus": "Efectos", "test": "", "loop": false,
		"title": "Foquito: apagarse", "use": "una lámpara indicadora que se apaga"},
	{"key": "error", "category": "genericos", "bus": "Efectos", "test": "buzz", "title": "Error",
		"use": "equivocarse: la clave mal puesta, tocar el alambre, la expendedora sin stock, un daño de la nave"},
	{"key": "falla", "category": "genericos", "bus": "Efectos", "test": "buzz", "test_pitch": 0.6, "title": "Falla",
		"use": "algo que se rompe o deja de andar: no es que uno se equivocó, es que la máquina falló"},
	{"key": "falla_tablero", "category": "genericos", "bus": "Efectos", "test": "buzz", "test_pitch": 0.5,
		"title": "Falla de tablero",
		"use": "un tablero o un sistema que se rompe: un apagón, un chisporroteo, algo que cede"},
	{"key": "falla_cable", "category": "genericos", "bus": "Efectos", "test": "buzz", "test_pitch": 1.6,
		"title": "Falla de cable",
		"use": "un cable que hace cortocircuito: el chispazo y el zumbido de algo mal conectado"},
	{"key": "fuga_vapor", "category": "genericos", "bus": "Efectos", "test": "static", "title": "Fuga de vapor",
		"use": "un caño o una manguera que pierde vapor, mientras pierde (en loop)"},
	{"key": "aprobado", "category": "genericos", "bus": "Efectos", "test": "", "loop": false, "title": "Aprobado",
		"use": "algo que salió bien: una tarjeta que se lee bien, una clave correcta, una prueba pasada"},
	{"key": "calculando", "category": "genericos", "bus": "Efectos", "test": "hum", "test_pitch": 3.0,
		"title": "Calculando", "use": "una máquina pensando o procesando mientras tanto (en loop)"},

	# ── Avisos y errores ─────────────────────────────────────────────────────────────────────────────────────────────
	{"key": "campanillas", "category": "avisos", "bus": "Efectos", "test": "ring", "title": "Campanillas",
		"use": "la campana de alarma sonando, y el premio del tragamonedas"},
	{"key": "sirena", "category": "avisos", "bus": "Efectos", "test": "siren", "title": "Sirena",
		"use": "la sirena de aviso de la nave, prendida (en loop)"},
	{"key": "corneta", "category": "avisos", "bus": "Efectos", "test": "horn", "title": "Corneta y parlante",
		"use": "el instrumento de la corneta y el parlante: una nota en 440 Hz que el juego afina a cada nota",
		"ref_hz": 440.0},
	{"key": "ding", "category": "avisos", "bus": "Efectos", "test": "horn", "title": "Ding de llegada",
		"use": "el ascensor que llega al piso, el aro que llega al final del alambre (una nota en 880 Hz)",
		"ref_hz": 880.0},

	# ── Aparatos prendidos ───────────────────────────────────────────────────────────────────────────────────────────
	{"key": "ventilador", "category": "aparatos", "bus": "Efectos", "test": "hum", "unit": 2.0, "max": 10.0,
		"title": "Ventilador", "use": "el ventilador industrial girando; el tono sigue la velocidad (en loop)"},
	{"key": "arco", "category": "aparatos", "bus": "Efectos", "test": "hum", "unit": 2.0, "title": "Arco eléctrico",
		"use": "el chisporroteo del arco eléctrico mientras está prendido (en loop)", "test_pitch": 2.2},
	{"key": "lectora", "category": "aparatos", "bus": "Efectos", "test": "hum", "title": "Lectora leyendo",
		"use": "la lectora de tarjetas mientras lee (en loop)", "test_pitch": 1.8},
	{"key": "nave_motor", "category": "nave", "bus": "Efectos", "test": "", "loop": true, "unit": 8.0, "max": 60.0,
		"title": "Motor de la nave",
		"use": "el motor de la nave volando, desde el casco; el tono sube con el acelerador (en loop)"},
	{"key": "nave_propulsor_vertical", "category": "nave", "bus": "Efectos", "test": "", "loop": true, "unit": 8.0,
		"max": 60.0, "title": "Propulsores de altura",
		"use": "los propulsores de abajo, mientras la nave sube o baja (en loop, tan fuerte como la palanca)"},
	{"key": "nave_propulsor_lateral", "category": "nave", "bus": "Efectos", "test": "", "loop": true, "unit": 8.0,
		"max": 60.0, "title": "Propulsores del costado",
		"use": "los propulsores del costado, mientras la nave gira (en loop, tan fuerte como el volante)"},
	{"key": "nave_turbo", "category": "nave", "bus": "Efectos", "test": "", "loop": true, "unit": 8.0, "max": 60.0,
		"title": "Turbo de la nave", "use": "el turbo de la nave, mientras empuja (en loop)",
		"pending": "la nave todavía no tiene turbo"},
	{"key": "motor_consola", "category": "aparatos", "bus": "Efectos", "test": "engine", "title": "Motor de la consola",
		"use": "el motor de la nave andando, desde la consola de manejo (en loop)"},
	{"key": "grabador", "category": "aparatos", "bus": "Efectos", "test": "horn", "title": "Grabador",
		"use": "el instrumento del grabador: una nota en 440 Hz que el juego afina a cada nota de la pista",
		"ref_hz": 440.0},
	{"key": "laser_pega", "category": "aparatos", "bus": "Efectos", "test": "", "loop": true,
		"title": "Láser pegando", "use": "el rayo del láser pegando en su receptor (en loop, en el receptor)"},
	{"key": "laser_libre", "category": "aparatos", "bus": "Efectos", "test": "", "loop": true,
		"title": "Láser sin pegar", "use": "el rayo del láser prendido que no pega en nada (en loop, en el emisor)"},
	{"key": "moneda_entra", "category": "aparatos", "bus": "Efectos", "test": "click", "title": "Moneda en la ranura",
		"use": "una moneda que termina de entrar por la ranura de la expendedora"},
	{"key": "expendedora_ok", "category": "aparatos", "bus": "Efectos", "test": "", "loop": false,
		"title": "Expendedora: aceptado", "use": "la expendedora acepta la compra: había moneda y había producto"},
	{"key": "expendedora_falla", "category": "aparatos", "bus": "Efectos", "test": "buzz",
		"title": "Expendedora: rechazado",
		"use": "la expendedora rechaza la compra: falta la moneda o el lugar está agotado"},
	{"key": "expendedora", "category": "aparatos", "bus": "Efectos", "test": "hum", "title": "Expendedora cargando",
		"use": "el producto cargándose: el resorte girando hasta que lo larga (en loop)", "test_pitch": 0.7},
	{"key": "expendedora_cae", "category": "aparatos", "bus": "Efectos", "test": "click",
		"title": "Lo que cae de la expendedora", "use": "el consumible que cae a la bandeja de la expendedora"},

	# ── La radio: lo único con música ────────────────────────────────────────────────────────────────────────────────
	{"key": "estatica", "category": "radio", "bus": "Música", "test": "static", "title": "Estática de la radio",
		"use": "el ruido entre emisoras, que sube cuanto peor se sintoniza (en loop)"},
	# LA MÚSICA DE CADA EMISORA (ver Radio): sus canciones, una tras otra en el orden de sus nombres y vuelta a empezar,
	# que todos oyen en el mismo punto (el reloj compartido). Sin archivo, la emisora toca su melodía de notas.
	{"key": "radio_lr1", "category": "radio", "bus": "Música", "test": "", "loop": true, "playlist": true,
		"db": -6.0, "unit": 4.0,
		"max": 25.0, "title": "Emisora LR1", "use": "las canciones de la emisora LR1, una tras otra, en loop",
		"fallback": "su melodía de notas, por el parlante"},
	{"key": "radio_puerto", "category": "radio", "bus": "Música", "test": "", "loop": true, "playlist": true,
		"db": -6.0, "unit": 4.0,
		"max": 25.0, "title": "Emisora PUERTO", "use": "las canciones de la emisora PUERTO, una tras otra, en loop",
		"fallback": "su melodía de notas, por el parlante"},
	{"key": "radio_tango", "category": "radio", "bus": "Música", "test": "", "loop": true, "playlist": true,
		"db": -6.0, "unit": 4.0,
		"max": 25.0, "title": "Emisora TANGO", "use": "las canciones de la emisora TANGO, una tras otra, en loop",
		"fallback": "su melodía de notas, por el parlante"},
	{"key": "radio_voltera", "category": "radio", "bus": "Música", "test": "", "loop": true, "playlist": true,
		"db": -6.0, "unit": 4.0,
		"max": 25.0, "title": "Emisora VOLTERA", "use": "las canciones de la emisora VOLTERA, una tras otra, en loop",
		"fallback": "su melodía de notas, por el parlante"},

	# ── Calle y autos ────────────────────────────────────────────────────────────────────────────────────────────────
	{"key": "motor_auto", "category": "autos", "bus": "Efectos", "test": "engine", "title": "Motor de auto",
		"use": "el motor de cada auto volador del tráfico (en loop)"},
	{"key": "bocina", "category": "autos", "bus": "Efectos", "test": "", "loop": false, "title": "Bocina de auto",
		"use": "un bocinazo de auto", "pending": "los autos todavía no tocan bocina"},
	{"key": "choque", "category": "autos", "bus": "Efectos", "test": "", "loop": false, "title": "Choque y explosión",
		"use": "un auto que choca o explota", "alternatives": true,
		"pending": "los choques y las explosiones de los autos todavía no suenan"},

	# ── Puertas y compuertas: un golpe al abrir y otro al cerrar (ver ShipDoor) ──────────────────────────────────────
	{"key": "timbre", "category": "puertas", "bus": "Efectos", "test": "ring", "loop": false, "unit": 4.0,
		"max": 25.0, "title": "Timbre", "variants": true,
		"use": "el timbre de una entrada: cada variante (ding dong, ringgg…) es un timbre_<nombre>; cada casa, una",
		"pending": "las entradas de las casas todavía no tienen timbre"},
	{"key": "compuerta_atras_abre", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 6.0, "max": 40.0, "title": "Compuerta de atrás de la nave: abrir",
		"use": "la rampa de atrás de la nave, que baja (dura menos de un segundo)"},
	{"key": "compuerta_atras_cierra", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 6.0, "max": 40.0, "title": "Compuerta de atrás de la nave: cerrar",
		"use": "la rampa de atrás de la nave, que sube (dura menos de un segundo)"},
	{"key": "compuerta_costado_abre", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 6.0, "max": 40.0, "title": "Compuerta del costado de la nave: abrir",
		"use": "la puerta corrediza del costado, que se mete en la pared (dura menos de un segundo)"},
	{"key": "compuerta_costado_cierra", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 6.0, "max": 40.0, "title": "Compuerta del costado de la nave: cerrar",
		"use": "la puerta corrediza del costado, que sale de la pared y cierra (dura menos de un segundo)"},
	{"key": "porton_abre", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 6.0, "max": 40.0, "title": "Portón de la sucursal: abrir",
		"use": "el portón grande de la sucursal, que sube (dura menos de un segundo)"},
	{"key": "porton_cierra", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 6.0, "max": 40.0, "title": "Portón de la sucursal: cerrar",
		"use": "el portón grande de la sucursal, que baja (dura menos de un segundo)"},
	{"key": "puerta_abre", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 5.0, "max": 30.0, "title": "Puerta de calle: abrir",
		"use": "una puerta de calle que se abre: la usan los peatones, y avisa (dura menos de un segundo)",
		"pending": "las puertas de los edificios todavía no se abren"},
	{"key": "puerta_cierra", "category": "puertas", "bus": "Efectos", "test": "", "loop": false,
		"unit": 5.0, "max": 30.0, "title": "Puerta de calle: cerrar",
		"use": "una puerta de calle que se cierra (dura menos de un segundo)",
		"pending": "las puertas de los edificios todavía no se abren"},

	# ── Personas ─────────────────────────────────────────────────────────────────────────────────────────────────────
	{"key": "pasos", "category": "personas", "bus": "Efectos", "test": "", "loop": false, "title": "Pasos",
		"use": "un paso, uno por pisada", "alternatives": true,
		"pending": "los personajes todavía no suenan al caminar", "random_pitch": 1.08, "random_db": 2.0},

	# ── Paquetes: cada golpe es dos capas, el cuerpo que pega y su material (ver PackageDamage) ──────────────────────
	{"key": "golpe_paquete", "category": "paquetes", "bus": "Efectos", "test": "", "loop": false,
		"title": "Golpe de paquete: el cuerpo", "use": "el golpe seco de un paquete que cae o choca, sea de lo que sea",
		"alternatives": true, "random_pitch": 1.06, "random_db": 2.0},
	{"key": "golpe_madera", "category": "paquetes", "bus": "Efectos", "test": "", "loop": false,
		"title": "Golpe de paquete: madera", "use": "la capa del material: madera que golpea: el baúl, el armario",
		"alternatives": true, "random_pitch": 1.06, "random_db": 2.0},
	{"key": "golpe_metal", "category": "paquetes", "bus": "Efectos", "test": "", "loop": false,
		"title": "Golpe de paquete: metal", "use": "la capa del material: metal que golpea: la caja fuerte, el horno",
		"alternatives": true, "random_pitch": 1.06, "random_db": 2.0},
	{"key": "golpe_vidrio", "category": "paquetes", "bus": "Efectos", "test": "", "loop": false,
		"title": "Golpe de paquete: vidrio", "use": "la capa del material: vidrio que vibra o se raja: el televisor",
		"alternatives": true, "random_pitch": 1.06, "random_db": 2.0},
	{"key": "golpe_tela", "category": "paquetes", "bus": "Efectos", "test": "", "loop": false,
		"title": "Golpe de paquete: tela", "use": "la capa del material: algo tapizado y blando que golpea: el sillón",
		"alternatives": true, "random_pitch": 1.06, "random_db": 2.0},
	{"key": "golpe_ceramica", "category": "paquetes", "bus": "Efectos", "test": "", "loop": false,
		"title": "Golpe de paquete: cerámica", "use": "la capa del material: cerámica que golpea o se quiebra: la vasija",
		"alternatives": true, "random_pitch": 1.06, "random_db": 2.0},

	# ── Los consumibles: uno al agarrarlo y otro al tomarlo (ver HopperItem) ─────────────────────────────────────────
	{"key": "consumible_tonic_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Tónico Vigor: agarrarlo",
		"use": "Tónico Vigor, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_tonic_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Tónico Vigor: tomarlo", "use": "Tónico Vigor, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_mate_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Mate cocido: agarrarlo",
		"use": "Mate cocido, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_mate_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Mate cocido: tomarlo", "use": "Mate cocido, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_coffee_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Café: agarrarlo",
		"use": "Café, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_coffee_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Café: tomarlo", "use": "Café, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_flask_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Grapa: agarrarlo",
		"use": "Grapa, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_flask_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Grapa: tomarlo", "use": "Grapa, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_cigars_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Cigarros: agarrarlo",
		"use": "Cigarros, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_cigars_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Cigarros: tomarlo", "use": "Cigarros, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_jump_pills_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Pastillas Saltarinas: agarrarlo",
		"use": "Pastillas Saltarinas, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_jump_pills_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Pastillas Saltarinas: tomarlo", "use": "Pastillas Saltarinas, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_steroid_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Elixir de Toro: agarrarlo",
		"use": "Elixir de Toro, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_steroid_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Elixir de Toro: tomarlo", "use": "Elixir de Toro, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_despertina_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Despertina: agarrarlo",
		"use": "Despertina, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_despertina_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Despertina: tomarlo", "use": "Despertina, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_antiallergic_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Antialérgico: agarrarlo",
		"use": "Antialérgico, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_antiallergic_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Antialérgico: tomarlo", "use": "Antialérgico, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},
	{"key": "consumible_repair_kit_agarra", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Kit de reparación: agarrarlo",
		"use": "Kit de reparación, al sacarlo de la bandeja de la expendedora y llevarlo al cinturón"},
	{"key": "consumible_repair_kit_consume", "category": "consumibles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Kit de reparación: tomarlo", "use": "Kit de reparación, al tomarlo del cinturón",
		"pending": "los consumibles todavía no se toman"},

	# ── El ambiente de la ciudad, de día (ver CityAmbience) ──────────────────────────────────────────────────────────
	# LA CAMA: loops planos, sin nada que se reconozca, de largos que no coinciden, cada uno en su reproductor.
	{"key": "ciudad_fondo", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": true, "db": -10.0,
		"title": "Cama: fondo grave (la ciudad lejos)",
		"use": "un loop plano y grave, la ciudad entera de lejos, sin nada que se reconozca"},
	{"key": "ciudad_medio", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": true, "db": -12.0,
		"title": "Cama: medio (viento, vapor, el aire de la calle)",
		"use": "un loop plano del aire de la calle: viento, vapor; de otro largo que el fondo"},
	{"key": "ciudad_agudo", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": true, "db": -16.0,
		"title": "Cama: agudo suave (gente lejana, textura)",
		"use": "un loop suave de textura aguda: gente lejana; de otro largo que los otros dos"},
	# LOS EVENTOS: sueltos, al azar, desde un punto alrededor de quien escucha.
	{"key": "ciudad_campana", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": false, "db": -12.0,
		"title": "Evento: campanada lejana", "use": "una campanada de iglesia lejos, cada tanto",
		"alternatives": true, "random_pitch": 1.05, "random_db": 2.0},
	{"key": "ciudad_barco", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": false, "db": -14.0,
		"title": "Evento: sirena de barco del puerto", "use": "la sirena de un barco en el puerto, cada tanto",
		"alternatives": true, "random_pitch": 1.05, "random_db": 2.0},
	{"key": "ciudad_silbato", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": false, "db": -14.0,
		"title": "Evento: silbato", "use": "un silbato (vigilante, tren, fábrica), cada tanto",
		"alternatives": true, "random_pitch": 1.05, "random_db": 2.0},
	{"key": "ciudad_voces", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": false, "db": -14.0,
		"title": "Evento: voces", "use": "voces sueltas de la calle, un grito, un pregón, cada tanto",
		"alternatives": true, "random_pitch": 1.05, "random_db": 2.0},
	{"key": "ciudad_auto", "category": "ambiente", "bus": "Ambiente", "test": "", "loop": false, "db": -12.0,
		"title": "Evento: un auto que pasa", "use": "un auto volador que pasa lejos, cada tanto",
		"alternatives": true, "random_pitch": 1.05, "random_db": 2.0},
]

static var _by_key: Dictionary = {}


## La fila de `key`, o un diccionario vacío si no existe.
static func row(key: StringName) -> Dictionary:
	if _by_key.is_empty():
		for entry: Dictionary in ROWS:
			_by_key[String(entry["key"])] = entry
	return _by_key.get(String(key), {})


## Todas las claves, en el orden de la tabla.
static func keys() -> Array[StringName]:
	var out: Array[StringName] = []
	for entry: Dictionary in ROWS:
		out.append(StringName(entry["key"]))
	return out


## Si `key` lleva varios archivos que se alternan (ver `alternatives`).
static func has_alternatives(key: StringName) -> bool:
	return bool(row(key).get("alternatives", false))


## Si los archivos de `key` son una lista de canciones (ver `playlist`).
static func has_playlist(key: StringName) -> bool:
	return bool(row(key).get("playlist", false))


## Si soltar un archivo nuevo para `key` lo SUMA a los que tiene (alternativas, variantes, canciones) en vez de
## reemplazar el que había.
static func adds_files(key: StringName) -> bool:
	return has_alternatives(key) or has_variants(key) or has_playlist(key)


## Si `key` lleva variantes con nombre, una por objeto (ver `variants`).
static func has_variants(key: StringName) -> bool:
	return bool(row(key).get("variants", false))
