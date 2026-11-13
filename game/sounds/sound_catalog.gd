class_name SoundCatalog

## EL CATÁLOGO DE CLAVES DE SONIDO: una fila por sonido del juego, que dice CÓMO SUENA. Agregar un sonido es agregar una
## fila acá y pedirla desde la clase que suena, en su constante `SOUNDS` (ver SoundEntity: ahí se dice CUÁNDO suena —el
## evento, el estado, el movimiento— y con qué capas, corte y continuidad). La fila Sonidos del sandbox la muestra (ver
## SoundParcelArchetype), igual que el panel de sonidos de cada parcela (F1, ver SoundPanel). Ver
## character-parametric:docs/technical/audio.md.
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
## reemplazar el que hay; lo decidió el usuario el 11/10/2026 para los eventos del ambiente, los pasos, los
## golpes de paquete y los choques, lo que se oye muchas veces seguidas), `playlist` (UNA LISTA DE CANCIONES: sus
## archivos suenan uno tras otro, en el orden de sus nombres, sin sortear —las emisoras de la radio—; soltar uno lo
## suma) y `variants` (LLEVA VARIANTES CON NOMBRE:
## `timbre_dingdong.ogg`, `timbre_ring.ogg`…; cada objeto suena siempre con una, la suya —ver SoundEntity.sound_variant—,
## y no al azar como las alternativas; soltar una en el panel la suma. Lo decidió el usuario el 11/10/2026).

const ROWS := [
	# ── Lo que se toca: un golpe por acción ──────────────────────────────────────────────────────────────────────────
	{"key": "boton", "category": "controles", "bus": "Efectos", "test": "click", "title": "Botón y tecla: apretar",
		"use": "apretar un botón, una tecla o el manipulador Morse (al bajar el clic)"},
	{"key": "palanca", "category": "controles", "bus": "Efectos", "test": "click", "title": "Palanca",
		"use": "una palanca o un interruptor que llega al fondo o cambia de posición"},
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
	{"key": "pagina", "category": "controles", "bus": "Efectos", "test": "click", "title": "Página del manual",
		"use": "pasar una página del manual"},
	{"key": "silla_sienta", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Silla: sentarse", "use": "sentarse en una silla o un asiento de la meca"},
	{"key": "silla_levanta", "category": "controles", "bus": "Efectos", "test": "", "loop": false,
		"title": "Silla: pararse", "use": "pararse de una silla o un asiento de la meca"},

	# ── Genéricos: de nadie en particular, para usar donde haga falta (ver SoundEntity.GENERIC) ──────────────────────
	{"key": "error", "category": "genericos", "bus": "Efectos", "test": "buzz", "title": "Error",
		"use": "equivocarse: la clave mal puesta, tocar el alambre, la expendedora sin stock, un daño de la meca"},
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
	{"key": "sirena", "category": "avisos", "bus": "Efectos", "test": "siren", "title": "Sirena",
		"use": "la sirena de aviso de la meca, prendida (en loop)"},

	# ── Aparatos prendidos ───────────────────────────────────────────────────────────────────────────────────────────
	{"key": "ventilador", "category": "aparatos", "bus": "Efectos", "test": "hum", "unit": 2.0, "max": 10.0,
		"title": "Ventilador", "use": "el ventilador industrial girando; el tono sigue la velocidad (en loop)"},

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
