extends Node3D

## LA JAULA (la 91 de tests/human_scale_look) REPENSADA, MAQUETAS DE ARCILLA (16/11/2026). El usuario: «el que más me
## gusta es el 91, la jaula… hay como una relación ahí entre el artillero y el que maneja… sacaría las dos escaleras…
## que sea como en el Halo, que depende de dónde apuntas para entrar… el torso me gusta como está. Pero… uno… le está
## tapando la cabeza al otro con la ametralladora… están como muy encimados… agrandar un poco la meca para espaciarlos
## más o subir uno más arriba… la jaula esa no me está funcionando… una barra alrededor, así con los controles, que estén
## al aire libre como la maqueta de cilindro abierto… controles similares… el de atrás… cómo su estructura se monta
## mejor en la parte de atrás… separarlo un poco más del otro».
##   · ABAJO, la cápsula del que maneja, igual que en la 91, sin escaleras (se entra apuntando y apretando E).
##   · ARRIBA, LOS BRAZOS de pie, al aire, dentro de un borde bajo con bevel (como el disco chico, tests/small_disc_look)
##     con sus controles adelante: dos palancas, botonera y reloj.
##   · ATRÁS, EL ARTILLERO, montado de otra manera en cada una:
##   93 · en una torre corta detrás del borde: más alto, la ametralladora pasa por encima de la cabeza de los brazos;
##   94 · un segundo tambor abierto, igual, pegado atrás: el artillero de pie en el suyo, a la misma altura;
##   95 · en un balcón más bajo, colgado del lomo de la cápsula, con su propia baranda;
##   96 · en la punta de una pluma que sale de atrás hacia arriba: lejos y alto.
##   tools/godot_ventana.sh res://tests/cage_ideas_look.tscn -- --salida=C:/carpeta --variante=93

const VIEW := Vector2i(1280, 720)
const VARIANTS := {
	93: "el artillero en una torre corta",
	94: "el artillero en su propio tambor abierto, atrás",
	95: "el artillero en un balcón más bajo",
	96: "el artillero en la punta de una pluma",
	97: "la torre: un pilar cuadrado entero, pegado",
	98: "la torre: una columna redonda",
	99: "la torre: la pared de la cápsula que sigue subiendo",
	100: "la torre: dos patas en A",
	101: "la torre: un cuello curvo",
	102: "la torre: cilindros que se achican",
	103: "montaje articulado: horquilla, en reposo",
	104: "montaje articulado: horquilla, apuntando al cielo",
	105: "montaje articulado: horquilla, girado a un costado",
	106: "montaje articulado: rótula",
	107: "el respaldo cabecea con el arma: en reposo",
	108: "el respaldo cabecea con el arma: al cielo",
	109: "el respaldo cabecea con el arma: a un costado",
	110: "el arma con su propio pie: en reposo",
	111: "el arma con su propio pie: al cielo",
	112: "el arma con su propio pie: a un costado",
	113: "con piernas y brazos de la meca real, al 30 %",
	114: "con piernas y brazos de la meca real, al 40 %",
	115: "cuadrada, piernas y brazos reales al 30 %",
	116: "cuadrada, piernas y brazos reales al 40 %",
	117: "cuadrada, pelvis más corta y caderas de bola, al 30 %",
	118: "cuadrada, pelvis más corta y caderas de bola, al 40 %",
	119: "cuadrada sobre una pelvis cilíndrica, al 30 %",
	120: "cuadrada sobre una pelvis cilíndrica, al 40 %",
	121: "la torre metida en el cuadrado, el borde en ángulo, al 30 %",
	122: "la torre metida en el cuadrado, el borde en ángulo, al 40 %",
	123: "atrás, el hueco de los recursos y la batería, al 30 %",
	124: "atrás, el hueco de los recursos y la batería, al 40 %",
	125: "atrás, arriba, la mochila del jetpack, al 30 %",
	126: "atrás, arriba, la mochila del jetpack, al 40 %",
	127: "mochila: la caja con cuatro toberas cortas",
	128: "mochila: la caja de tapa redonda",
	129: "mochila: la caja con el bisel abajo",
	130: "mochila: las toberas metidas",
	131: "mochila: bolas chicas arriba",
	132: "mochila: dos cajas mellizas",
	133: "cristal cuadrado",
	134: "cristal apaisado, a la altura de los ojos",
	135: "cristal vertical",
	136: "cristal octógono",
	137: "cristal hexágono",
	138: "cristal rombo",
	139: "cristal triángulo, la punta abajo",
	140: "cristal en arco",
	141: "cristal píldora acostada",
	142: "dos ojos de buey",
	143: "todo el frente de cristal",
	144: "burbuja que sobresale (media esfera)",
	145: "cilindro acostado que sobresale",
	146: "la 144 con el acorazado, la espada y el cañón de energía",
	147: "hombreras y el puño pesado con un palo eléctrico",
	148: "hombreras y el puño pesado con un palo de sierra",
	149: "hombreras y el puño pesado con un palo con disco de sierra",
	150: "hombreras y el puño pesado con un martillo eléctrico",
	151: "hombrera: media esfera",
	152: "hombrera: una placa chata inclinada",
	153: "hombrera: cilindro de adelante hacia atrás",
	154: "hombrera: tres láminas en cascada",
	155: "hombrera: un cubo",
	156: "hombrera: un disco de costado",
	157: "hombrera: prisma triangular, la arista hacia afuera",
	158: "hombrera: placa con una aleta hacia el cuello",
	159: "hombrera: cilindro acostado hacia afuera",
	160: "hombrera: dos placas, arriba y al costado",
	161: "hombrera: una bola grande achatada",
	162: "hombrera: un bloque hexagonal",
	163: "hombrera: la placa de la 152 con tres quiebres, más corta",
	164: "hombrera: la placa de la 152 en tres tramos (dos quiebres), más corta",
	165: "hombrera: la 163 al revés: empinada junto al cuello, chata afuera",
	167: "hombrera: la 163 al revés: chata adentro, el borde de afuera levantado",
	168: "la 166 con los hombros en el módulo de arriba",
	169: "hombros a +20 cm del piso de arriba",
	170: "hombros a +0 cm del piso de arriba",
	171: "hombros a -20 cm del piso de arriba",
	172: "hombros a -40 cm del piso de arriba",
	173: "hombros a -60 cm del piso de arriba",
	166: "hombrera: la 163 doblada hacia abajo de adelante hacia atrás",
}
## 151 a 162 (el usuario: «me gusta el 147… el 147 con muchas variaciones de hombreras, porque las de ahora no me
## gustan»): la 147 con otra hombrera, cada una de una forma primitiva.
const PAULDRONS := {151: "dome", 152: "slab", 153: "drum_z", 154: "lames", 155: "cube", 156: "disc", 157: "wedge", 158: "collar", 159: "drum_x", 160: "corner", 161: "ball", 162: "hex", 163: "fold4",
	164: "fold3", 165: "fold_up", 166: "fold_front", 167: "fold_lip", 168: "fold_front", 169: "fold_front", 170: "fold_front",
	171: "fold_front", 172: "fold_front", 173: "fold_front"}
## 168 (el usuario: «la misma meca, pero con los brazos… los hombros y las hombreras… en la parte de arriba, no de
## abajo»): la 166 con los hombros a media altura del puesto de arriba, el del que maneja.
const SHOULDERS_UP := [168]
## 169 a 173 (el usuario: «está muy alto… más bajo que eso, pero en varias graduaciones»): la 168 con los hombros a
## estas alturas respecto del piso del puesto de arriba (la 168, +38 cm; la 166, en la mitad de la caja de abajo).
const SHOULDER_HEIGHT := {169: 0.2, 170: 0.0, 171: -0.2, 172: -0.4, 173: -0.6}
## 147 a 150 (el usuario: «la espada prefiero que sea algo como más abstracto… un palo eléctrico, o un palo con sierra…
## que lo esté agarrando con la mano… los modelos de puños que hay en componentes… el puño pesado para agarrar… unas
## hombreras… una meca más full»): la 146 con el brazo derecho cerrado en el puño pesado de la armería, agarrando un
## palo, y hombreras de placa (las caras de octógono del acorazado, más grandes, sobre el hombro).
const POLES := {147: "electric", 148: "saw_bar", 149: "disc", 150: "hammer", 151: "electric", 152: "electric",
	153: "electric", 154: "electric", 155: "electric", 156: "electric", 157: "electric", 158: "electric",
	159: "electric", 160: "electric", 161: "electric", 162: "electric", 163: "electric", 164: "electric",
	165: "electric", 166: "electric", 167: "electric", 168: "electric", 169: "electric",
	170: "electric", 171: "electric", 172: "electric", 173: "electric"}
## 146 (el usuario: «nos quedamos con la 144… le agregamos la acorazado y le ponemos de una mano un brazo de espada y
## del otro un cañón de energía»): las placas del acorazado de la armería (ArmoryParts, tres caras de octógono en el
## brazo, el antebrazo, el muslo y la canilla), en el brazo derecho una espada (no estaba modelada: una hoja simple que
## sale de la boca del antebrazo, como las herramientas) y en el izquierdo el cañón de energía de la armería.
const ARMED := [146, 147, 148, 149, 150, 151, 152, 153, 154, 155, 156, 157, 158, 159, 160, 161, 162, 163, 164, 165, 166, 167, 168, 169, 170, 171, 172, 173]
## 133 a 145 (el usuario: «vamos con el 129… variaciones con distintas formas con el cristal del de abajo, siempre con
## formas simples, primitivas»): la 129 tal cual, con otra forma de ventana en la caja de abajo.
const GLASS_SHAPES := {133: "square", 134: "wide", 135: "tall", 136: "octagon", 137: "hexagon", 138: "diamond",
	139: "triangle", 140: "arch", 141: "pill", 142: "portholes", 143: "full", 144: "bubble", 145: "barrel", 146: "bubble", 147: "bubble",
	148: "bubble", 149: "bubble", 150: "bubble", 151: "bubble", 152: "bubble", 153: "bubble", 154: "bubble",
	155: "bubble", 156: "bubble", 157: "bubble", 158: "bubble", 159: "bubble", 160: "bubble", 161: "bubble", 162: "bubble",
	163: "bubble", 164: "bubble", 165: "bubble", 166: "bubble", 167: "bubble", 168: "bubble", 169: "bubble", 170: "bubble",
	171: "bubble", 172: "bubble", 173: "bubble"}
## 127 a 132 (el usuario: «no me gusta… pienses rediseños… los huecos de la batería y el hueco más chicos y que tenga
## más padding… las toberas abajo más cortas y las otras más chicas y los conos más cortos… una forma simple… si
## sobresalen un poco, no queda tan mal… ideas tuyas con esa base»): la 125 con el hueco y la batería al 70 %, más
## separados de todo, y seis mochilas simples, de lo que apenas asoma.
const JETPACK2 := {127: "flat", 128: "lid", 129: "bevel", 130: "recessed", 131: "small_balls", 132: "twin"}
## 125 y 126 (el usuario: «en la parte que le queda arriba haría como la mochila del jetpack»): la 123 y la 124 con,
## arriba del hueco y la batería, una mochila pegada a la cara de atrás: su caja, dos tanques redondos a los costados y
## dos toberas abajo, mirando hacia abajo y un poco atrás.
const JETPACK := [125, 126]
## 123 y 124 (el usuario: «en la parte de atrás debería tener un hueco por donde se meten recursos y otro módulo que sea
## como la batería… dos lugares atrás. Uno es un hueco y el otro es un slot para la batería empotrada… en una zona más o
## menos baja… no tan al margen»): la 121 y la 122 con, en la cara de atrás de la caja de abajo, a un tercio de su alto,
## el HUECO (un agujero oscuro con marco y un labio abajo, donde entra un cubo de recursos) y al lado el SLOT con la
## BATERÍA empotrada (asoma un poco, con sus bornes).
const BACK_SLOTS := [123, 124, 125, 126]
const BATTERY := Color(0.62, 0.6, 0.42)
## 121 y 122 (el usuario: «que la torre encaje mejor con esto de cuadrado… que no sobresalga… para atrás… como una parte
## del cuadrado de arriba… en la parte del tipo que mueve la nave, en vez de terminar derecho el corte, que esté en un
## ángulo leve, más corto adelante, más alto… atrás… más dinámica la forma»): la 119 y la 120 con la torre como un
## bloque dentro de la planta, contra la cara de atrás, y el borde de arriba subiendo de adelante (bajo, con sus
## controles) hasta atrás (a la altura de la torre). El que maneja, un poco más adelante.
const INTEGRATED := [121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132]
## 119 y 120 (el usuario: «otra variante en la que siguen siendo cilindros, pero la pelvis pasa a ser cilíndrica
## también. Así se diferencia de la caja de arriba»): la caja corta de la 117 apoyada sobre una pelvis que es un cilindro
## acostado de cadera a cadera, del color de las articulaciones, con los discos de las caderas en sus puntas.
const CYLINDER_PELVIS := [119, 120, 121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132]
## 117 y 118 (el usuario: «la zona de abajo de la que maneja los brazos es la pelvis… hacerla más corta y… los
## conectores de las piernas, en vez de esos cilindros, sean esferas»): la 115 y la 116 con la caja que baja menos
## (justo debajo del piso hundido) y la cadera de cada pierna una bola en vez del disco.
## 115 y 116 (el usuario: «una variante en vez de cilíndrica con formato cuadrado… la misma disposición de cosas,
## solamente que cuadrada»): la 113 y la 114 con la cápsula de abajo y el puesto de arriba de planta cuadrada, del
## mismo ancho; la ventana sigue redonda.
## 113 y 114 (el usuario: «cómo se vería esto mismo con brazos y piernas de meca real escaladas… simplemente… una
## foto»): la 110 con las piezas del juego —MechLeg (disco de cadera, rodilla y tobillo esféricos, el pie) y el brazo
## de PoseArm (hombro y codo esféricos, la mano de MechHand con sus falanges)— en la postura de MechBody, a esta escala.
const REAL_SCALE := {113: 0.3, 114: 0.4, 115: 0.3, 116: 0.4, 117: 0.3, 118: 0.4, 119: 0.3, 120: 0.4, 121: 0.3,
	122: 0.4, 123: 0.3, 124: 0.4, 125: 0.3, 126: 0.4, 127: 0.3, 128: 0.3, 129: 0.3, 130: 0.3, 131: 0.3, 132: 0.3}
## 110 a 112 (el usuario: «el arma no debería salir… del respaldar… debería tener su soporte en la base de la torre y
## su propia articulación… no debería estar atada al respaldar… está muy alta… el personaje le está sosteniendo… a la
## altura de su cabeza… el conductor… debería estar sentado, y por lo tanto bajar las barreras… tal vez… bajes también
## el de la ametralladora»): el de los brazos sentado, el borde más bajo; el plato que gira lleva el asiento y, adelante,
## el pie del arma con su horquilla; el arma cabecea en su horquilla y el respaldo en su perno, los dos el mismo ángulo.
## El arma, a la altura del pecho del artillero; todo el montaje, más bajo. [giro, cabeceo].
const OWN_FOOT := {
	110: [0.0, 0.0],
	111: [0.0, 45.0],
	112: [90.0, 20.0],
}
## 107 a 109 (el usuario: «me parece bien la 105… el giro está bien… para apuntar hacia arriba lo que se reclina es…
## el respaldo, no el asiento… junto con el arma… el arma la bajaste y ahora está a la altura casi de el conductor…
## la torre la subiría un poco desde abajo»): el rulemán gira el asiento entero; el respaldo, con el artillero de la
## cintura para arriba y el arma, cabecea sobre un perno a la altura de la cadera. El arma, bien por encima de la cabeza
## del de los brazos; la columna empieza más arriba. [giro (grados), cabeceo (grados, + hacia arriba)].
const RECLINES := {
	107: [0.0, 0.0],
	108: [0.0, 45.0],
	109: [90.0, 20.0],
}
## 103 a 106 (el usuario: «me gusta la 98… debería ser más como un attachment metálico… que se puede mover y que es
## articulable… si quiere apuntar hacia el cielo… que pueda… una articulación… y también girar a 360 grados»): la
## columna de la 98, de metal, con un rulemán arriba (gira 360°) y encima la articulación que cabecea, con el asiento,
## el artillero y el arma montados en ella. [articulación, giro (grados), cabeceo (grados, + hacia arriba)].
const MOUNTS := {
	103: ["fork", 0.0, 0.0],
	104: ["fork", 0.0, 40.0],
	105: ["fork", 90.0, -10.0],
	106: ["ball", 35.0, 25.0],
}
## 97 a 102 (el usuario: «vamos con el 93… está como flotando la torre… variaciones de la torre con distintas
## formas»): la 93 con la torre de otra forma, siempre pegada a la cápsula; la plataforma y el artillero, iguales.
const LIMBS := 0.3
## El borde con bevel: su ancho, el alto de afuera y el de adentro.
const RIM := 0.35
## Más bajo desde la 110 (el usuario: «el conductor… debería estar sentado, y por lo tanto bajar las barreras»).
const RIM_OUT := 0.72
const RIM_IN := 0.6
## La cápsula de abajo, de la cintura del cilindro hasta la cubierta (más alta desde la ventana redonda, para que la
## ventana tenga aire arriba y abajo).
const POD_TOP := 0.95
## La torre del artillero sobre la cubierta (m): en la metida en el cuadrado, también el alto de la pared de atrás.
const TOWER_TALL := 1.05
## La ventana grande (desde la 127): su radio; la caja de abajo deja el mismo margen arriba y abajo.
const BIG_WINDOW := 0.64
const BODY := Color(0.6, 0.61, 0.63)
const METAL := Color(0.55, 0.57, 0.6)
const DARK := Color(0.3, 0.31, 0.34)
const DECK := Color(0.68, 0.69, 0.7)
const RIM_COLOR := Color(0.22, 0.23, 0.25)
const RIM_DARK := RIM_COLOR
const HOLE := Color(0.08, 0.08, 0.1)
const GLASS := Color(0.62, 0.8, 0.92, 0.3)
const JOINT := Color(0.36, 0.375, 0.4)
const SKIN := Color(0.86, 0.66, 0.5)
const SEAT := Color(0.25, 0.42, 0.7)
const RED := Color(0.78, 0.18, 0.15)
const YELLOW := Color(0.95, 0.75, 0.15)
const FACE := Color(0.92, 0.9, 0.84)

var _folder := ""
var _variant := 93
## El número que se muestra y se guarda (la 133 a 145 se arman como la 129, con otra ventana).
var _number := 93
## La forma de la ventana de abajo ("" = la redonda de siempre).
var _glass := ""
var _eye: Camera3D = null
var _title: Label = null
var _bottom := 0.0
var _shoulder := Vector3.ZERO
var _top := 0.0
var _deck := 0.0
## La mitad del alto de la zona del de abajo (el usuario: «los hombros deberían crecer a la mitad de su zona»); si es 0,
## los hombros van donde iban.
var _arms_mid := 0.0
## Dónde mira el de los brazos (sus ojos), para la vista desde su lugar.
var _arms_eye := Vector3.ZERO
## Dónde agarra el puño pesado el palo (147 a 150), para la vista de cerca.
var _grip_at := Vector3.ZERO
## El hombro izquierdo (el del cañón), para la vista de cerca de la hombrera.
var _left_shoulder := Vector3.ZERO


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--salida="):
			_folder = argument.trim_prefix("--salida=")
		if argument.begins_with("--variante="):
			_variant = int(argument.trim_prefix("--variante="))
	_number = _variant
	if GLASS_SHAPES.has(_variant):
		_glass = GLASS_SHAPES[_variant]
		_variant = 129
	get_window().size = VIEW
	_stage()
	var body := MechBody.new()
	var limb_scale: float = REAL_SCALE.get(_variant, LIMBS)
	var hip_line := (body.WAIST - body.HIP_DROP) * limb_scale
	_bottom = hip_line + 0.25
	# Con la pelvis cilíndrica, la caja sube hasta apoyarse arriba del cilindro.
	if _variant in CYLINDER_PELVIS:
		_bottom = hip_line + body.LEG_THICKNESS * limb_scale * 0.55 + 0.27
		# La caja más corta (desde la 127): su fondo queda a la altura de `_bottom` + lo que dejó de bajar.
		if _variant >= 127:
			var pad := 0.83 - BIG_WINDOW
			_bottom = hip_line + body.LEG_THICKNESS * limb_scale * 0.55 - (0.85 - BIG_WINDOW - pad)
	# Del mismo ancho que la cápsula de abajo (el usuario: «del mismo ancho que la parte de abajo… sigue siendo una
	# cabina para una persona, no debería ser un espacio. Cada persona tiene su cosa»).
	var walk := 1.0 - RIM + 0.015
	if _variant >= 115:
		_square_pod_and_deck(1.0 - RIM)
	else:
		_pod_and_deck(walk)
	match _variant:
		93: _tower()
		94: _twin(walk)
		95: _balcony()
		96: _boom()
		97, 98, 99, 100, 101, 102: _tower_shape(_variant)
		103, 104, 105, 106: _mount(MOUNTS[_variant])
		107, 108, 109: _recline_mount(RECLINES[_variant])
		110, 111, 112: _own_foot_mount(OWN_FOOT[_variant])
		113, 114, 115, 116, 117, 118, 119, 120: _own_foot_mount([0.0, 0.0])
		121, 122, 123, 124, 125, 126, 127, 128, 129, 130, 131, 132: _own_foot_mount([0.0, 0.0], true)
	if REAL_SCALE.has(_variant):
		_real_limbs(limb_scale)
	else:
		_legs(hip_line)
		for s: float in [-1.0, 1.0]:
			_arm(Vector3(s * _shoulder.x, _shoulder.y, _shoulder.z), s)
	_standing(Vector3(-2.6, 0.0, -1.2))
	await get_tree().create_timer(2.0).timeout
	var whole := Vector3(0.0, _top * 0.5, 0.3)
	var k := _top / 5.0
	var shots: Array = []
	_title.text = "%d. %s" % [_number, VARIANTS[_number]]
	shots.append(await _view(whole + Vector3(-6.0, 2.5, -8.0) * k, whole, 45.0))
	_title.text = "%d. de atrás" % _number
	shots.append(await _view(whole + Vector3(6.0, 2.5, 8.0) * k, whole, 45.0))
	_title.text = "%d. de costado" % _number
	shots.append(await _view(whole + Vector3(-30.0, 0.0, 0.0), whole, 0.0, _top + 1.0))
	_title.text = "%d. de frente, de cerca: el de abajo por su ventana" % _number
	var window_y := _bottom + 0.9
	if _variant in CYLINDER_PELVIS:
		_title.text = "%d. de frente, de cerca: la ventana y la pelvis" % _number
		shots.append(await _view(Vector3(1.8, window_y - 0.5, -5.0), Vector3(0.0, window_y - 0.8, 0.0), 55.0))
	else:
		shots.append(await _view(Vector3(1.2, window_y + 0.6, -3.6), Vector3(0.0, window_y, 0.0), 50.0))
	if _number in ARMED:
		_title.text = "%d. de frente, entera: la espada (su derecha) y el cañón" % _number
		if POLES.has(_number):
			_title.text = "%d. de frente, entera: el palo (su derecha) y el cañón" % _number
		shots.append(await _view(Vector3(0.6, _top * 0.4, -10.0), Vector3(0.0, _top * 0.42, 0.0), 45.0))
	elif _glass != "":
		_title.text = "%d. de frente, derecho: la forma del cristal" % _number
		shots.append(await _view(Vector3(0.0, _arms_mid + 0.2, -4.6), Vector3(0.0, _arms_mid, 0.0), 40.0))
	elif _variant in BACK_SLOTS or JETPACK2.has(_variant):
		_title.text = "%d. de cerca, de atrás: el hueco y la batería" % _number
		if JETPACK2.has(_variant):
			_title.text = "%d. de cerca, de atrás: la mochila, el hueco y la batería" % _number
		if _variant in JETPACK:
			_title.text = "%d. de cerca, de atrás: la mochila, el hueco y la batería" % _number
		if _variant in JETPACK or JETPACK2.has(_variant):
			shots.append(await _view(Vector3(2.4, _bottom + 1.8, 6.4), Vector3(0.0, _bottom + 1.3, 0.8), 50.0))
		else:
			shots.append(await _view(Vector3(1.6, _bottom + 0.9, 4.8), Vector3(0.0, _bottom + 0.7, 0.8), 50.0))
	else:
		_title.text = "%d. de cerca, de atrás y arriba" % _number
		shots.append(await _view(Vector3(2.6, _top + 1.8, 4.2), Vector3(0.0, _deck + 0.6, 0.2), 55.0))
	if PAULDRONS.has(_number):
		_title.text = "%d. de cerca: la hombrera del lado del cañón" % _number
		shots.append(await _view(_left_shoulder + Vector3(-3.4, 1.5, -3.6), _left_shoulder + Vector3(0.4, -0.2, 0.0), 45.0))
		_save(shots)
		get_tree().quit()
		return
	if POLES.has(_number):
		_title.text = "%d. de cerca: el puño pesado y el palo, y la hombrera" % _number
		shots.append(await _view(_grip_at + Vector3(3.0, 1.0, -1.6), _grip_at + Vector3(-0.2, 0.9, 0.0), 50.0))
		_save(shots)
		get_tree().quit()
		return
	_title.text = "%d. de cerca, de costado: el de los brazos y el artillero" % _number
	shots.append(await _view(Vector3(-4.2, _deck + 1.6, 0.6), Vector3(0.0, _deck + 1.2, 0.6), 60.0))
	_save(shots)
	get_tree().quit()


## ── LA CÁPSULA Y LA CUBIERTA ─────────────────────────────────────────────────────────────────────────────────────

## La cápsula del que maneja (la de la 91: cilindro con el fondo redondo, la ranura, la tapa de la panza) y, encima, la
## cubierta de radio `walk` con su borde con bevel; el de los brazos de pie adelante, con sus controles.
func _pod_and_deck(walk: float) -> void:
	var pod := Vector3(0.0, _bottom + 0.85, 0.0)
	# La cápsula hueca (el usuario: «traer el cristal de la 92 para el que maneja los brazos, que es el de abajo… que
	# esté el hueco, así se ve… el personaje manejando»): la pared en segmentos, con un hueco adelante a la altura de los
	# ojos tapado por la burbuja de vidrio de la 92; el fondo, media esfera hacia abajo, que es también el piso.
	var low := pod.y - 0.7
	# El hueco, redondo (el usuario: «ahí la dejaste achatada… aprovechar el espacio para que vea bien… circular»): un
	# círculo de radio WINDOW centrado en `center`; cada segmento de la pared se corta donde el círculo lo cruza.
	var center := pod.y + 0.05
	var window := 0.52
	var count := 64
	var step := TAU / count
	for k in count:
		var a := step * (k + 0.5)
		var x := sin(a) * 0.95
		var front := cos(a) > 0.0 and absf(x) < window
		var bands: Array = [[low, pod.y + POD_TOP]]
		if front:
			var h := sqrt(window * window - x * x)
			bands = [[low, center - h], [center + h, pod.y + POD_TOP]]
		for band: Array in bands:
			var from: float = band[0]
			var to: float = band[1]
			var piece := Clay.box(self, Vector3(0.1, to - from, 2.0 * sin(step * 0.5) + 0.02),
				Vector3(sin(a) * 0.95, (from + to) * 0.5, -cos(a) * 0.95), BODY)
			piece.basis = Basis(Vector3.UP, PI * 0.5 - a)
	var belly := MeshInstance3D.new()
	var cap := SphereMesh.new()
	cap.radius = 1.0
	cap.height = 1.0
	cap.is_hemisphere = true
	belly.mesh = cap
	belly.material_override = Clay.material(BODY)
	belly.rotation_degrees.x = 180.0
	belly.position = Vector3(0.0, low, 0.0)
	add_child(belly)
	# El piso, hundido en el fondo redondo, para que los ojos queden a la altura del centro de la burbuja.
	var floor_y := low - 0.3
	Clay.cylinder(self, 0.93, 0.03, Vector3(0.0, floor_y + 0.015, 0.0), DECK)
	_seated(Vector3(0.0, floor_y + 0.03, 0.1))
	_ellipsoid(Vector3(window + 0.04, window + 0.04, 0.42), Vector3(0.0, center, -0.9), GLASS)
	var frame := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = window - 0.02
	torus.outer_radius = window + 0.07
	frame.mesh = torus
	frame.material_override = Clay.material(RIM_COLOR)
	frame.rotation_degrees.x = 90.0
	frame.position = Vector3(0.0, center, -0.96)
	add_child(frame)
	Clay.cylinder(self, 0.42, 0.06, Vector3(0.0, low - 1.0, 0.0), RIM_COLOR)
	Clay.cylinder(self, 0.34, 0.07, Vector3(0.0, low - 1.0, 0.0), HOLE)
	_deck = pod.y + POD_TOP
	var outer := walk + RIM
	_revolve(PackedVector2Array([Vector2(0.0, _deck), Vector2(walk, _deck)]), DECK)
	_revolve(PackedVector2Array([Vector2(walk, _deck), Vector2(walk, _deck + RIM_IN), Vector2(outer, _deck + RIM_OUT),
		Vector2(outer, _deck - 0.12), Vector2(0.0, _deck - 0.12)]), METAL)
	# Los controles de los brazos, adelante sobre el bevel; y él, de pie.
	var bevel := Vector2(RIM, RIM_OUT - RIM_IN)
	for item: Array in [[0.0, "drive"], [-0.55, "buttons"], [0.55, "dial"]]:
		_control(walk, item[0], item[1], bevel)
	# Sentado (desde la 110), con los controles al alcance de las manos.
	var seat := Vector3(0.0, _deck, -0.05)
	_seated(seat)
	_arms_eye = seat + Vector3(0.0, 1.2, 0.1)
	_shoulder = Vector3(outer + 0.3, _deck - 0.45, -0.1)
	_top = _deck + 1.9


## Un control sobre el bevel, en `angle` desde el frente (como en el disco chico); `offset`, corrido a lo largo del borde
## (para el borde recto de la cuadrada).
func _control(walk: float, angle: float, kind: String, bevel: Vector2, offset := 0.0) -> void:
	var outward := Vector3(sin(angle), 0.0, -cos(angle))
	var up := (Vector3.UP * bevel.x - outward * bevel.y).normalized()
	var along := Vector3(cos(angle), 0.0, sin(angle))
	var plate := Node3D.new()
	plate.basis = Basis(along, up, along.cross(up))
	plate.position = outward * (walk + RIM * 0.5) + Vector3(0.0, _deck + (RIM_IN + RIM_OUT) * 0.5, 0.0) + along * offset
	add_child(plate)
	match kind:
		"drive":
			for side: float in [-1.0, 1.0]:
				Clay.box(plate, Vector3(0.16, 0.06, 0.24), Vector3(side * 0.2, 0.03, 0.0), DARK)
				Clay.cylinder(plate, 0.025, 0.42, Vector3(side * 0.2, 0.24, 0.0), DARK)
				Clay.sphere(plate, 0.06, Vector3(side * 0.2, 0.46, 0.0), RED)
		"buttons":
			Clay.box(plate, Vector3(0.45, 0.04, 0.24), Vector3(0.0, 0.02, 0.0), DARK)
			for i in 3:
				Clay.cylinder(plate, 0.05, 0.06, Vector3((i - 1) * 0.14, 0.06, 0.0), YELLOW if i == 1 else RED)
		"dial":
			Clay.cylinder(plate, 0.15, 0.05, Vector3(0.0, 0.025, 0.0), FACE)
			Clay.box(plate, Vector3(0.02, 0.02, 0.13), Vector3(0.03, 0.06, -0.03), RED).rotation.y = 0.6


## LA CUADRADA (115, 116): la misma cápsula de abajo y el mismo puesto de arriba, de planta cuadrada de 2 m. La cápsula,
## una caja con el fondo plano un poco más abajo (donde la redonda tenía la media esfera); la ventana, redonda en la cara
## de adelante, con su burbuja y su marco; adentro, el piso hundido y el de abajo sentado. Arriba, el borde con su bevel
## en las cuatro caras y los controles en la de adelante.
func _square_pod_and_deck(walk: float) -> void:
	var pod_y := _bottom + 0.85
	var low := pod_y - 0.7
	var top := pod_y + POD_TOP
	var wall_top := top - 0.12
	var base := low - (0.42 if _variant >= 117 else 0.8)
	# Desde la 127, la ventana más grande y la caja que baja sólo lo que sube arriba de la ventana (el usuario: «tiene
	# más espacio sobre abajo que arriba, cuando deberían ser prácticamente iguales… el vidrio debería aprovechar al
	# máximo el espacio»).
	var center := pod_y + 0.05
	var window := 0.52
	if _variant >= 127:
		center = pod_y
		window = BIG_WINDOW
		base = center - window - (wall_top - center - window)
	var half := 1.0
	var wall := 0.1
	var mid := (base + wall_top) * 0.5
	_arms_mid = mid
	# Con la mochila, el hueco y la batería un poco más abajo, para que entre el aire de arriba.
	var slots_y := base + (wall_top - base) * (0.25 if _variant in JETPACK else 0.33)
	if _variant in BACK_SLOTS:
		_back_slots(slots_y, half)
	if _variant in JETPACK:
		# Agnóstica a los módulos (el usuario: «debería ocupar hasta arriba… el Jetpack es agnóstico a los módulos…
		# un padding tranquilo con respecto a el hueco y la batería»): del hueco + 30 cm hasta arriba de la pared de
		# atrás del puesto de arriba.
		# El aire (el usuario: «no está el padding que yo quiero»): 45 cm libres entre el marco del hueco y las puntas
		# de las toberas de abajo, que cuelgan 40 cm.
		_jetpack(slots_y + 0.48 + 0.45 + 0.4, top + TOWER_TALL - 0.05, half)
	if JETPACK2.has(_variant):
		# El hueco y la batería al 70 %, más separados; arriba, 40 cm de aire hasta lo que cuelgue de la mochila.
		var small_y := base + 0.45
		_back_slots(small_y, half, 0.7, 0.45)
		_jetpack_simple(JETPACK2[_variant], small_y + 0.33 + 0.4, top + TOWER_TALL - 0.05, half)
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(wall, wall_top - base, 2.0), Vector3(s * (half - wall * 0.5), mid, 0.0), BODY)
	Clay.box(self, Vector3(2.0, wall_top - base, wall), Vector3(0.0, mid, half - wall * 0.5), BODY)
	Clay.box(self, Vector3(2.0, 0.12, 2.0), Vector3(0.0, base + 0.06, 0.0), BODY)
	# El frente, en tiras verticales cortadas por el círculo de la ventana (o por la forma de la 133 a 145).
	var outlines := _glass_outlines()
	var strips := 25 if outlines.is_empty() else 80
	var width := 2.0 / strips
	for i in strips:
		var x := -half + width * (i + 0.5)
		var bands: Array = [[base, wall_top]]
		if not outlines.is_empty():
			bands = _wall_bands(outlines, x, center, base, wall_top)
		elif absf(x) < window:
			var h := sqrt(window * window - x * x)
			bands = [[base, center - h], [center + h, wall_top]]
		for band: Array in bands:
			var from: float = band[0]
			var to: float = band[1]
			Clay.box(self, Vector3(width + 0.005, to - from, wall), Vector3(x, (from + to) * 0.5, -half + wall * 0.5), BODY)
	var floor_y: float = low - 0.3 if _variant < 127 else base + 0.12
	Clay.box(self, Vector3(1.8, 0.03, 1.8), Vector3(0.0, floor_y + 0.015, 0.0), DECK)
	_seated(Vector3(0.0, floor_y + 0.03, 0.1))
	if not outlines.is_empty():
		_shaped_glass(outlines, center, half, wall)
	else:
		_ellipsoid(Vector3(window + 0.04, window + 0.04, 0.42), Vector3(0.0, center, -half + 0.05), GLASS)
		var frame := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = window - 0.02
		torus.outer_radius = window + 0.07
		frame.mesh = torus
		frame.material_override = Clay.material(RIM_COLOR)
		frame.rotation_degrees.x = 90.0
		frame.position = Vector3(0.0, center, -half - 0.01)
		add_child(frame)
	Clay.cylinder(self, 0.42, 0.06, Vector3(0.0, base - 0.01, 0.0), RIM_COLOR)
	Clay.cylinder(self, 0.34, 0.07, Vector3(0.0, base - 0.01, 0.0), HOLE)
	# ARRIBA: el piso y el borde con bevel en las cuatro caras (cada una, una pared baja y la tapa inclinada).
	_deck = top
	Clay.box(self, Vector3(2.02, 0.12, 2.02), Vector3(0.0, _deck - 0.06, 0.0), METAL)
	Clay.box(self, Vector3(walk * 2.0, 0.03, walk * 2.0), Vector3(0.0, _deck + 0.015, 0.0), DECK)
	var rise := Vector2(RIM, RIM_OUT - RIM_IN)
	var integrated := _variant in INTEGRATED
	if integrated:
		# Atrás, una pared a la altura de la torre; a los costados, paredes que suben de adelante hacia atrás.
		var back_tall := TOWER_TALL
		Clay.box(self, Vector3(1.99, back_tall, RIM - 0.01), Vector3(0.0, _deck + back_tall * 0.5, walk + RIM * 0.5),
			METAL)
		for s: float in [-1.0, 1.0]:
			_prism(s * (walk + RIM * 0.5), RIM - 0.01, PackedVector2Array([Vector2(-1.0, _deck),
				Vector2(-1.0, _deck + RIM_OUT), Vector2(1.0, _deck + back_tall), Vector2(1.0, _deck)]), METAL)
	for k in (1 if integrated else 4):
		var side := Node3D.new()
		side.rotation.y = PI * 0.5 * k
		add_child(side)
		Clay.box(side, Vector3(1.99, RIM_IN, RIM - 0.01), Vector3(0.0, _deck + RIM_IN * 0.5, -(walk + RIM * 0.5)), METAL)
		var cap := Clay.box(side, Vector3(1.99, 0.05, rise.length()), Vector3(0.0, _deck + (RIM_IN + RIM_OUT) * 0.5,
			-(walk + RIM * 0.5)), METAL)
		cap.basis = Basis(Vector3.RIGHT, -atan2(rise.y, rise.x))
		Clay.box(side, Vector3(1.99, RIM_OUT - RIM_IN, RIM * 0.5 - 0.01), Vector3(0.0, _deck + (RIM_IN + RIM_OUT) * 0.5,
			-(walk + RIM * 0.75)), METAL)
	for item: Array in [[-0.5, "buttons"], [0.0, "drive"], [0.5, "dial"]]:
		_control(walk, 0.0, item[1], rise, item[0])
	var seat := Vector3(0.0, _deck, -0.3 if integrated else -0.05)
	_seated(seat)
	_arms_eye = seat + Vector3(0.0, 1.2, 0.1)
	_shoulder = Vector3(1.3, _deck - 0.45, -0.1)
	_top = _deck + 1.9


## 146 · EL BRAZO ARMADO: las placas en el brazo y el antebrazo, y en la boca del antebrazo la espada (derecho) o el
## cañón de energía (izquierdo), sin la mano (la herramienta sale por donde se mete el puño). Las piezas de la armería
## están en la medida de la meca entera: se cuelgan de un nodo achicado a `k`.
func _armed_arm(upper: Node3D, forearm: Node3D, side: float, k: float, body: MechBody) -> void:
	var full := MechBody.new()
	_plate(upper, Vector3.RIGHT * side, k, full.UPPER_ARM * 0.75)
	if side < 0.0 and POLES.has(_number):
		_cannon_forearm(forearm, k)
		return
	_plate(forearm, Vector3.RIGHT * side, k, full.FOREARM * 0.7)
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * k
	holder.position = Vector3(0, 0, -body.FOREARM * 0.5 - ArmoryParts.TIP * k - 0.3 * k)
	forearm.add_child(holder)
	Clay.cylinder(holder, ArmoryParts.MOUTH, 0.7, Vector3(0, 0, ArmoryParts.TIP + 0.35),
		ArmoryParts.FOREARM_COLOR.darkened(0.15), Vector3(90, 0, 0))
	if side > 0.0 and POLES.has(_number):
		holder.queue_free()
		_pole_fist(forearm, side, body)
	elif side > 0.0:
		_sword(holder)
	else:
		ArmoryParts._energy_cannon(holder)


## 147 a 150 · EL CAÑÓN EN LUGAR DEL ANTEBRAZO (el usuario: «el cañón… debería reemplazar el antebrazo»): sin el
## cilindro del antebrazo ni su placa; desde el codo, un cuello y el cañón de energía de la armería, el mismo cilindro
## gris oscuro con su boca, que empieza ahí y termina donde terminaría el puño.
func _cannon_forearm(forearm: Node3D, k: float) -> void:
	(forearm.get_child(0) as Node3D).visible = false
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * k
	forearm.add_child(holder)
	var elbow := MechBody.new().FOREARM * 0.5
	# La boca, donde terminaría el puño (el usuario: «quede con el cañón el mismo largo que tendría con el puño»).
	var muzzle := ArmoryParts.TIP - 1.4
	Clay.cylinder(holder, 1.15, 1.0, Vector3(0, 0, elbow - 0.9), Clay.METAL.darkened(0.1), Vector3(90, 0, 0))
	var from := elbow - 1.4
	var to := muzzle + 0.8
	Clay.cylinder(holder, 1.45, from - to, Vector3(0, 0, (from + to) * 0.5), ArmoryParts.CANNON_COLOR, Vector3(90, 0, 0))
	# dos aros para que se lea el largo, y la boca
	for z: float in [from - 0.6, (from + to) * 0.5]:
		Clay.cylinder(holder, 1.55, 0.25, Vector3(0, 0, z), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.cylinder(holder, 1.05, 0.8, Vector3(0, 0, muzzle + 0.4), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.cylinder(holder, 0.6, 0.1, Vector3(0, 0, muzzle - 0.02), Clay.DARK, Vector3(90, 0, 0))


## 147 a 150 · EL PUÑO PESADO de la armería (la mano de la meca cerrada, engordada, con los pinches) en la punta del
## antebrazo, con los nudillos parados, y el palo pasando por adentro del puño: parado y un poco inclinado hacia adelante.
func _pole_fist(forearm: Node3D, side: float, body: MechBody) -> void:
	Clay.cylinder(forearm, ArmoryParts.MOUTH * body.thick, 0.7 * body.thick,
		Vector3(0, 0, -body.FOREARM * 0.5 + 0.05 * body.thick), ArmoryParts.FOREARM_COLOR.darkened(0.15), Vector3(90, 0, 0))
	var hand := MechHand.build(forearm, side)
	hand.fist = true
	hand.position = Vector3(0, 0, -body.FOREARM * 0.5)
	# Los nudillos parados en el mundo: el +Y de la mano (y el palo) hacia arriba, inclinado hacia adelante; los dedos
	# hacia donde apunta el antebrazo.
	var up := Basis(Vector3.RIGHT, -0.45) * Vector3.UP
	var ahead := -forearm.global_basis.z.normalized()
	ahead = (ahead - up * ahead.dot(up)).normalized()
	var back := -ahead
	hand.global_basis = Basis(up.cross(back), up, back)
	ArmoryParts.make_heavy(hand, body.thick)
	# El hueco del puño: delante de la palma, del lado al que cierran los dedos (−X para la derecha).
	var grip := Node3D.new()
	grip.position = Vector3(-side * 0.75, 0.0, -1.35)
	hand.add_child(grip)
	_grip_at = grip.global_position
	_pole(grip, POLES[_number])


## El palo, a lo largo de +Y del agarre (el puño en el origen; la mayor parte arriba), en la medida de la mano.
func _pole(grip: Node3D, kind: String) -> void:
	var low := -2.2
	var high := 6.5
	var shaft := Clay.DARK.lightened(0.18)
	Clay.cylinder(grip, 0.3, high - low, Vector3(0, (high + low) * 0.5, 0), shaft)
	# los topes de abajo y el anillo de arriba del puño
	Clay.cylinder(grip, 0.42, 0.4, Vector3(0, low, 0), MechBody.JOINT_COLOR)
	Clay.cylinder(grip, 0.4, 0.2, Vector3(0, 1.3, 0), MechBody.JOINT_COLOR)
	match kind:
		"electric":
			# las bobinas debajo de la cabeza y dos puntas con una bola entre ellas
			for i in 4:
				Clay.cylinder(grip, 0.5, 0.14, Vector3(0, high - 1.6 + i * 0.32, 0), Clay.METAL.darkened(0.25))
			Clay.cylinder(grip, 0.45, 0.4, Vector3(0, high, 0), MechBody.JOINT_COLOR)
			for x: float in [-0.3, 0.3]:
				Clay.cylinder(grip, 0.09, 1.2, Vector3(x, high + 0.8, 0), ArmoryParts.STEEL)
			Clay.sphere(grip, 0.24, Vector3(0, high + 0.85, 0), Color(0.55, 0.78, 0.9))
		"saw_bar":
			# una barra chata en la mitad de arriba, con los dientes al frente (−Z)
			var from := 2.0
			var bar := high + 1.0 - from
			Clay.box(grip, Vector3(0.26, bar, 1.0), Vector3(0, from + bar * 0.5, -0.25), ArmoryParts.STEEL)
			var teeth := 14
			for i in teeth:
				var y := from + 0.25 + (bar - 0.5) * i / (teeth - 1)
				var tooth := Clay.box(grip, Vector3(0.22, 0.26, 0.26), Vector3(0, y, -0.82), ArmoryParts.STEEL.darkened(0.3))
				tooth.basis = Basis(Vector3.RIGHT, PI * 0.25)
			Clay.box(grip, Vector3(0.5, 0.5, 1.2), Vector3(0, from, -0.2), Clay.METAL.darkened(0.1))
		"disc":
			var radius := 1.7
			var at := Vector3(0, high + radius * 0.6, 0)
			for x: float in [-0.3, 0.3]:
				Clay.box(grip, Vector3(0.18, radius * 0.9, 0.45), Vector3(x, high + radius * 0.25, 0), Clay.METAL.darkened(0.1))
			Clay.cylinder(grip, 0.4, 0.75, at, MechBody.JOINT_COLOR, Vector3(0, 0, 90))
			Clay.cylinder(grip, radius, 0.12, at, ArmoryParts.STEEL, Vector3(0, 0, 90))
			var teeth := 22
			for i in teeth:
				var angle := TAU * i / teeth
				var tooth := Clay.box(grip, Vector3(0.12, 0.24, 0.3), at + Vector3(0, cos(angle), sin(angle)) * (radius + 0.06),
					ArmoryParts.STEEL.darkened(0.3))
				tooth.basis = Basis(Vector3.RIGHT, -angle)
		"hammer":
			# una cabeza de cilindro atravesada, con las caras de golpe en bobinas
			var at := Vector3(0, high, 0)
			Clay.cylinder(grip, 0.85, 2.6, at, Clay.METAL.darkened(0.1), Vector3(90, 0, 0))
			for z: float in [-1.0, 1.0]:
				Clay.cylinder(grip, 0.95, 0.18, at + Vector3(0, 0, z * 0.9), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
				Clay.cylinder(grip, 0.55, 0.12, at + Vector3(0, 0, z * 1.36), Color(0.55, 0.78, 0.9), Vector3(90, 0, 0))


## LA HOMBRERA: caras de octógono, como las placas del acorazado pero más grandes, sobre el hombro (`at`): de arriba
## hacia afuera, con el largo de adelante hacia atrás.
func _pauldron(at: Vector3, side: float, thick: float) -> void:
	if side < 0.0:
		_left_shoulder = at
	if PAULDRONS.has(_number):
		_pauldron_shape(PAULDRONS[_number], at, side, thick * 0.78)
		return
	var gap := 0.04
	var plate := 0.07
	var apothem := thick * 0.78 + gap + plate * 0.5 + 0.06
	var width := 2.0 * apothem * tan(PI / 8.0)
	var length := thick * 2.1
	for step: int in [-1, 0, 1, 2]:
		var turn := Basis(Vector3.BACK, -side * step * PI * 0.25)
		var face := Clay.box(self, Vector3(width, plate, length), Vector3.ZERO, ArmoryParts.PLATE)
		face.transform = Transform3D(turn, at + turn * Vector3(0, apothem, 0))


## Una placa del acorazado (tres caras de octógono) sobre `piece`, del lado que mira a `toward`, a escala `k`.
func _plate(piece: Node3D, toward: Vector3, k: float, length: float) -> void:
	var holder := Node3D.new()
	holder.scale = Vector3.ONE * k
	piece.add_child(holder)
	ArmoryParts._wrap(holder, Transform3D(ArmoryParts._facing(piece, toward), Vector3.ZERO), length)


## LA ESPADA, en el marco de las herramientas de la armería (la boca en ArmoryParts.TIP, hacia −Z): un cuello que sale
## de la boca, una guarda cruzada y una hoja ancha y plana, de canto vertical, con la punta en cuña.
func _sword(root: Node3D) -> void:
	var tip := ArmoryParts.TIP
	Clay.cylinder(root, 0.8, 1.0, Vector3(0, 0, tip - 0.5), MechBody.JOINT_COLOR, Vector3(90, 0, 0))
	Clay.box(root, Vector3(0.7, 2.8, 0.5), Vector3(0, 0, tip - 1.2), Clay.METAL.darkened(0.1))
	var blade := 7.0
	var width := 1.3
	var thick := 0.28
	var start := tip - 1.45
	Clay.box(root, Vector3(thick, width, blade), Vector3(0, 0, start - blade * 0.5), ArmoryParts.STEEL)
	# el lomo: una tira más oscura en el medio de cada cara, para que se lea que es una hoja
	Clay.box(root, Vector3(thick + 0.06, 0.18, blade - 0.4), Vector3(0, 0, start - blade * 0.5 + 0.2),
		ArmoryParts.STEEL.darkened(0.3))
	# la punta: una cuña
	var point := 1.6
	var profile := PackedVector2Array([Vector2(start - blade, -width * 0.5), Vector2(start - blade, width * 0.5),
		Vector2(start - blade - point, 0.0)])
	var wedge := Node3D.new()
	root.add_child(wedge)
	_prism_in(wedge, thick, profile, ArmoryParts.STEEL)


## Como `_prism` (grosor en x, contorno en (z, y)) pero colgado de `parent`.
func _prism_in(parent: Node3D, thick: float, profile: PackedVector2Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector3Array()
	var count := profile.size()
	for side: float in [-thick * 0.5, thick * 0.5]:
		for point in profile:
			points.append(Vector3(side, point.y, point.x))
	for i in range(1, count - 1):
		for cap in [0, count]:
			for index: int in [cap, cap + i, cap + i + 1]:
				tool.add_vertex(points[index])
	for i in count:
		var j := (i + 1) % count
		for index: int in [i, j, count + j, i, count + j, count + i]:
			tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	parent.add_child(mesh)


## 151 a 162 · LAS HOMBRERAS PRIMITIVAS sobre el hombro `at` (la bola del hombro, de radio `r`), del lado `side`.
func _pauldron_shape(kind: String, at: Vector3, side: float, r: float) -> void:
	var plate := ArmoryParts.PLATE
	var edge := MechBody.JOINT_COLOR
	var out := Vector3(side, 0.0, 0.0)
	match kind:
		"dome":
			var cap := MeshInstance3D.new()
			var half := SphereMesh.new()
			half.radius = r * 1.4
			half.height = r * 1.4
			half.is_hemisphere = true
			cap.mesh = half
			cap.material_override = Clay.material(plate)
			cap.position = at + out * r * 0.15
			cap.scale = Vector3(1.0, 0.85, 1.0)
			add_child(cap)
			Clay.cylinder(self, r * 1.45, 0.06, at + out * r * 0.15, edge)
		"slab":
			var slab := Clay.box(self, Vector3(r * 2.7, 0.12, r * 2.7), at + out * r * 0.45 + Vector3(0, r * 1.15, 0), plate)
			slab.basis = Basis(Vector3.BACK, -side * deg_to_rad(18.0))
		"drum_z":
			Clay.cylinder(self, r * 1.3, r * 2.4, at + out * r * 0.15 + Vector3(0, r * 0.25, 0), plate, Vector3(90, 0, 0))
			for z: float in [-1.0, 1.0]:
				Clay.cylinder(self, r * 1.36, 0.06, at + out * r * 0.15 + Vector3(0, r * 0.25, z * r * 1.0), edge,
					Vector3(90, 0, 0))
		"lames":
			for i in 3:
				var angle := deg_to_rad(8.0 + i * 30.0)
				var lame := Clay.box(self, Vector3(r * 1.5, 0.1, r * 2.5 - i * 0.08), Vector3.ZERO, plate if i != 1 else plate.darkened(0.08))
				var turn := Basis(Vector3.BACK, -side * angle)
				lame.transform = Transform3D(turn, at + out * r * 0.2 + turn * Vector3(0, r * 1.25, 0))
		"fold4", "fold3":
			# La placa de la 152 quebrada (el usuario: «152 pero con 3 quebraduras y más corto»): tramos que arrancan
			# del lado del cuello casi chatos y se van doblando hacia afuera y abajo, más corta de adelante hacia atrás.
			var angles: Array = [0.0, 22.0, 46.0, 70.0] if kind == "fold4" else [0.0, 32.0, 64.0]
			var piece := r * (2.5 / angles.size())
			var point := at - out * r * 0.55 + Vector3(0, r * 1.2, 0)
			for i in angles.size():
				var turn := Basis(Vector3.BACK, -side * deg_to_rad(angles[i]))
				var along := turn * out
				var lame := Clay.box(self, Vector3(piece + 0.06, 0.12, r * 2.0), Vector3.ZERO, plate if i % 2 == 0 else plate.darkened(0.06))
				lame.transform = Transform3D(turn, point + along * piece * 0.5)
				point += along * piece
		"fold_up", "fold_front", "fold_lip":
			# La 163 con la curva al revés (el usuario: «la curvatura de la hombrera en la otra dirección»): cuatro tramos,
			# tres quiebres. `fold_up`: de adentro hacia afuera, bajando y después subiendo (cóncava, el borde de afuera
			# levantado). `fold_front`: los quiebres de adelante hacia atrás, un arco sobre el hombro.
			var front := kind == "fold_front"
			# De adelante hacia atrás: sube, pasa por arriba del hombro y baja (cae adelante y atrás, como la 163 a los costados).
			var angles: Array = [40.0, 13.0, -13.0, -40.0]
			if kind == "fold_up":
				angles = [70.0, 46.0, 22.0, 0.0]
			elif kind == "fold_lip":
				angles = [0.0, -15.0, -32.0, -50.0]
			var piece := r * (2.5 / angles.size()) if not front else r * 0.55
			var points: Array = [Vector3.ZERO]
			for a: float in angles:
				var d := Vector3(0, sin(deg_to_rad(a)), cos(deg_to_rad(a))) if front else 					Vector3(side * cos(deg_to_rad(a)), -sin(deg_to_rad(a)), 0)
				points.append(points[-1] + d * piece)
			var low := INF
			var high := -INF
			var middle := Vector3.ZERO
			for q: Vector3 in points:
				low = minf(low, q.y)
				high = maxf(high, q.y)
				middle += q / points.size()
			var shift := at + (out * r * 0.25 if front else out * r * 0.4) - Vector3(middle.x, 0, middle.z)
			shift.y += (r * 1.05 - low) if not front else (r * 1.3 - high)
			for i in angles.size():
				var a := deg_to_rad(angles[i])
				var from: Vector3 = points[i] + shift
				var to: Vector3 = points[i + 1] + shift
				var size := Vector3(r * 1.7, 0.12, piece + 0.06) if front else Vector3(piece + 0.06, 0.12, r * 2.0)
				var lame := Clay.box(self, size, (from + to) * 0.5, plate if i % 2 == 0 else plate.darkened(0.06))
				lame.basis = Basis(Vector3.RIGHT, -a) if front else Basis(Vector3.BACK, -side * a)
		"cube":
			var block := Clay.box(self, Vector3.ONE * r * 2.3, at + out * r * 0.35 + Vector3(0, r * 0.55, 0), plate)
			block.basis = Basis(Vector3.BACK, -side * deg_to_rad(10.0))
		"disc":
			Clay.cylinder(self, r * 1.5, 0.14, at + out * (r + 0.12) + Vector3(0, r * 0.15, 0), plate, Vector3(0, 0, 90))
			Clay.cylinder(self, r * 0.55, 0.2, at + out * (r + 0.2) + Vector3(0, r * 0.15, 0), edge, Vector3(0, 0, 90))
		"wedge":
			var ridge := Clay.cylinder(self, r * 1.35, r * 2.5, at + out * r * 0.15 + Vector3(0, r * 0.45, 0), plate,
				Vector3(90, 0, 0))
			(ridge.mesh as CylinderMesh).radial_segments = 3
			ridge.basis = Basis(Vector3.RIGHT, PI * 0.5) * Basis(Vector3.UP, PI * 0.5)
		"collar":
			var top := Clay.box(self, Vector3(r * 2.5, 0.12, r * 2.5), at + out * r * 0.35 + Vector3(0, r * 1.15, 0), plate)
			top.basis = Basis(Vector3.BACK, -side * deg_to_rad(15.0))
			Clay.box(self, Vector3(0.1, r * 1.3, r * 2.2), at - out * r * 0.65 + Vector3(0, r * 1.75, 0), plate.darkened(0.05))
		"drum_x":
			Clay.cylinder(self, r * 1.2, r * 1.7, at + out * r * 0.35 + Vector3(0, r * 0.3, 0), plate, Vector3(0, 0, 90))
			Clay.cylinder(self, r * 1.26, 0.06, at + out * (r * 1.2) + Vector3(0, r * 0.3, 0), edge, Vector3(0, 0, 90))
		"corner":
			var top := Clay.box(self, Vector3(r * 2.2, 0.12, r * 2.4), at + out * r * 0.2 + Vector3(0, r * 1.2, 0), plate)
			top.basis = Basis(Vector3.BACK, -side * deg_to_rad(8.0))
			Clay.box(self, Vector3(0.12, r * 1.7, r * 2.4), at + out * (r * 1.25) + Vector3(0, r * 0.2, 0), plate)
		"ball":
			var ball := Clay.sphere(self, r * 1.32, at + out * r * 0.2 + Vector3(0, r * 0.2, 0), plate)
			ball.scale = Vector3(1.0, 0.85, 1.0)
			Clay.cylinder(self, r * 1.36, 0.06, at + out * r * 0.2 + Vector3(0, r * 0.2, 0), edge)
		"hex":
			var hex := Clay.cylinder(self, r * 1.45, r * 0.9, at + out * r * 0.25 + Vector3(0, r * 0.75, 0), plate)
			(hex.mesh as CylinderMesh).radial_segments = 6
			Clay.cylinder(self, r * 1.5, 0.06, at + out * r * 0.25 + Vector3(0, r * 0.3, 0), edge).mesh.radial_segments = 6


## ── LAS FORMAS DEL CRISTAL (133 a 145) ───────────────────────────────────────────────────────────────────────────

## Los contornos convexos de la ventana, en (x, y) respecto del centro de la cara; vacío para la redonda de siempre.
## Caben en ±0,83 de alto (el margen de 19 cm) y ±0,9 de ancho.
func _glass_outlines() -> Array:
	match _glass:
		"square": return [_rect(1.28, 1.28, 0.0)]
		"wide": return [_rect(1.72, 0.8, 0.2)]
		"tall": return [_rect(0.86, 1.36, 0.0)]
		"octagon": return [_polygon(Vector2.ZERO, 0.68, 8, PI / 8.0)]
		"hexagon": return [_polygon(Vector2.ZERO, 0.7, 6, 0.0)]
		"diamond": return [_polygon(Vector2.ZERO, 0.74, 4, 0.0)]
		"triangle": return [PackedVector2Array([Vector2(-0.82, 0.52), Vector2(0.82, 0.52), Vector2(0.0, -0.62)])]
		"arch":
			var arch := PackedVector2Array([Vector2(-0.62, -0.62), Vector2(0.62, -0.62)])
			for i in 21:
				var a := PI * i / 20.0
				arch.append(Vector2(cos(a) * 0.62, 0.02 + sin(a) * 0.62))
			return [arch]
		"pill":
			var pill := PackedVector2Array()
			for i in 21:
				var a := -PI * 0.5 + PI * i / 20.0
				pill.append(Vector2(0.46 + cos(a) * 0.38, 0.15 + sin(a) * 0.38))
			for i in 21:
				var a := PI * 0.5 + PI * i / 20.0
				pill.append(Vector2(-0.46 + cos(a) * 0.38, 0.15 + sin(a) * 0.38))
			return [pill]
		"portholes":
			return [_polygon(Vector2(-0.46, 0.12), 0.38, 32, 0.0), _polygon(Vector2(0.46, 0.12), 0.38, 32, 0.0)]
		"full": return [_rect(1.74, 1.42, 0.0)]
		"bubble": return [_polygon(Vector2.ZERO, 0.64, 40, 0.0)]
		"barrel": return [_rect(1.6, 0.86, 0.12)]
	return []


func _rect(w: float, h: float, y: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w * 0.5, y - h * 0.5), Vector2(w * 0.5, y - h * 0.5),
		Vector2(w * 0.5, y + h * 0.5), Vector2(-w * 0.5, y + h * 0.5)])


func _polygon(at: Vector2, radius: float, sides: int, phase: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in sides:
		var a := phase + TAU * i / sides
		points.append(at + Vector2(cos(a), sin(a)) * radius)
	return points


## Los tramos de pared de la tira vertical en `x`: lo que queda entre la base, los huecos de los contornos y arriba.
func _wall_bands(outlines: Array, x: float, center: float, base: float, wall_top: float) -> Array:
	var holes: Array = []
	for outline: PackedVector2Array in outlines:
		var low := INF
		var high := -INF
		for i in outline.size():
			var a := outline[i]
			var b := outline[(i + 1) % outline.size()]
			if is_equal_approx(a.x, b.x) or x < minf(a.x, b.x) or x > maxf(a.x, b.x):
				continue
			var y := lerpf(a.y, b.y, (x - a.x) / (b.x - a.x))
			low = minf(low, y)
			high = maxf(high, y)
		if low < high:
			holes.append([center + low, center + high])
	holes.sort_custom(func(p: Array, q: Array) -> bool: return p[0] < q[0])
	var bands: Array = []
	var from := base
	for hole: Array in holes:
		bands.append([from, hole[0]])
		from = hole[1]
	bands.append([from, wall_top])
	return bands


## El vidrio y su marco: una placa plana con el contorno, salvo la burbuja (media esfera) y el cilindro acostado,
## que sobresalen hacia adelante.
func _shaped_glass(outlines: Array, center: float, half: float, wall: float) -> void:
	var face := -half - 0.01
	for outline: PackedVector2Array in outlines:
		var count := outline.size()
		for i in count:
			var a := outline[i]
			var b := outline[(i + 1) % count]
			var along := b - a
			var bar := Clay.box(self, Vector3(along.length() + 0.08, 0.09, 0.07),
				Vector3((a.x + b.x) * 0.5, center + (a.y + b.y) * 0.5, face), RIM_COLOR)
			bar.basis = Basis(Vector3.BACK, along.angle())
		match _glass:
			"bubble":
				_ellipsoid(Vector3(0.66, 0.66, 0.62), Vector3(0.0, center, -half + wall * 0.5), GLASS)
			"barrel":
				var drum := MeshInstance3D.new()
				var tube := CylinderMesh.new()
				tube.top_radius = 0.43
				tube.bottom_radius = 0.43
				tube.height = 1.6
				drum.mesh = tube
				drum.material_override = Clay.material(GLASS)
				drum.basis = Basis(Vector3.BACK, PI * 0.5).scaled(Vector3(1.0, 1.0, 0.75))
				drum.position = Vector3(0.0, center + 0.12, -half + wall * 0.5)
				add_child(drum)
				for s: float in [-1.0, 1.0]:
					Clay.box(self, Vector3(0.05, 0.9, 0.36), Vector3(s * 0.8, center + 0.12, -half - 0.12), RIM_COLOR)
			_:
				_slab(outline, center, -half + wall * 0.5, 0.03, GLASS)


## Una placa de grosor `thick` en z con el contorno convexo `outline` en (x, y), centrada en `z`.
func _slab(outline: PackedVector2Array, center: float, z: float, thick: float, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector3Array()
	var count := outline.size()
	for side: float in [-thick * 0.5, thick * 0.5]:
		for point in outline:
			points.append(Vector3(point.x, center + point.y, z + side))
	for i in range(1, count - 1):
		for cap in [0, count]:
			for index: int in [cap, cap + i, cap + i + 1]:
				tool.add_vertex(points[index])
	for i in count:
		var j := (i + 1) % count
		for index: int in [i, j, count + j, i, count + j, count + i]:
			tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	add_child(mesh)


## ATRÁS, EL HUECO Y LA BATERÍA, a la altura `y` (su centro) en la cara de atrás (`half`, su distancia al centro).
func _back_slots(y: float, half: float, k := 1.0, x := 0.48) -> void:
	var face := half + 0.005
	var size := 0.72 * k
	# El hueco: el marco, el fondo oscuro y un labio abajo para apoyar el cubo.
	var hole := Vector3(-x, y, face)
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.08, size + 0.16, 0.06), hole + Vector3(s * (size + 0.08) * 0.5, 0.0, 0.02), RIM_COLOR)
		Clay.box(self, Vector3(size + 0.16, 0.08, 0.06), hole + Vector3(0.0, s * (size + 0.08) * 0.5, 0.02), RIM_COLOR)
	Clay.box(self, Vector3(size, size, 0.02), hole, HOLE)
	Clay.box(self, Vector3(size + 0.16, 0.05, 0.22 * k), hole + Vector3(0.0, -(size + 0.16) * 0.5, 0.12 * k), DARK)
	# El slot de la batería: su marco, y la batería metida, que asoma con sus dos bornes arriba.
	var slot := Vector3(x, y, face)
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.08, size + 0.16, 0.06), slot + Vector3(s * (size + 0.08) * 0.5, 0.0, 0.02), RIM_COLOR)
		Clay.box(self, Vector3(size + 0.16, 0.08, 0.06), slot + Vector3(0.0, s * (size + 0.08) * 0.5, 0.02), RIM_COLOR)
	Clay.box(self, Vector3(size, size, 0.02), slot, HOLE)
	Clay.box(self, Vector3(0.63, 0.63, 0.3) * k, slot, BATTERY)
	Clay.box(self, Vector3(0.65, 0.08, 0.32) * k, slot + Vector3(0.0, 0.18 * k, 0.0), BATTERY.darkened(0.3))
	for bx: float in [-0.16, 0.16]:
		Clay.cylinder(self, 0.05 * k, 0.08 * k, slot + Vector3(bx * k, 0.355 * k, 0.05 * k), DARK)
	Clay.box(self, Vector3(0.3, 0.05, 0.04) * k, slot + Vector3(0.0, -0.1 * k, 0.16 * k), DARK)

## LAS MOCHILAS SIMPLES (127 a 132), de `bottom` (lo más bajo, toberas incluidas) a `to`, en la cara de atrás: una forma
## simple, y lo que asoma, poco.
func _jetpack_simple(style: String, bottom: float, to: float, half: float) -> void:
	var depth := 0.38
	var z := half + depth * 0.5
	var shell := DARK.lightened(0.15)
	match style:
		"flat":
			# Una caja y cuatro campanas cortas, derechas, en fila abajo.
			var from := bottom + 0.2
			Clay.box(self, Vector3(1.6, to - from, depth), Vector3(0.0, (from + to) * 0.5, z), shell)
			Clay.box(self, Vector3(1.64, 0.05, depth + 0.04), Vector3(0.0, to - 0.25, z), RIM_COLOR)
			for x: float in [-0.54, -0.18, 0.18, 0.54]:
				_bell(Vector3(x, from, z), 0.07, 0.12, 0.18, 0.0)
		"lid":
			# Una caja con la tapa de arriba redonda (medio cilindro acostado) y dos toberas de bola chica abajo.
			var from := bottom + 0.3
			var top_y := to - depth * 0.5
			Clay.box(self, Vector3(1.5, top_y - from, depth), Vector3(0.0, (from + top_y) * 0.5, z), shell)
			Clay.cylinder(self, depth * 0.5, 1.5, Vector3(0.0, top_y, z), shell, Vector3(0.0, 0.0, 90.0))
			for s: float in [-1.0, 1.0]:
				Clay.sphere(self, 0.12, Vector3(s * 0.45, from - 0.04, z), JOINT)
				_bell(Vector3(s * 0.45, from - 0.12, z), 0.07, 0.12, 0.16, deg_to_rad(8.0) * s)
		"bevel":
			# Una caja con la arista de abajo y atrás cortada en bisel; en el bisel, tres toberas cortas hacia abajo y atrás.
			var from := bottom + 0.1
			_prism(0.0, 1.6, PackedVector2Array([Vector2(half, from), Vector2(half, to), Vector2(half + depth, to),
				Vector2(half + depth, from + 0.35), Vector2(half + 0.1, from)]), shell)
			Clay.box(self, Vector3(1.64, 0.05, depth + 0.04), Vector3(0.0, to - 0.25, z), RIM_COLOR)
			var mid := Vector2(half + (0.1 + depth) * 0.5, from + 0.175)
			for x: float in [-0.45, 0.0, 0.45]:
				var holder := Node3D.new()
				holder.position = Vector3(x, mid.y, mid.x)
				holder.rotation.x = deg_to_rad(-40.0)
				add_child(holder)
				Clay.cylinder(holder, 0.1, 0.05, Vector3.ZERO, RIM_COLOR)
				_bell_in(holder, 0.07, 0.12, 0.16)
		"recessed":
			# Una caja lisa; abajo, las bocas de las toberas metidas (aros y fondo oscuro), y tres rejillas en la cara.
			var from := bottom
			Clay.box(self, Vector3(1.6, to - from, depth), Vector3(0.0, (from + to) * 0.5, z), shell)
			for x: float in [-0.4, 0.4]:
				Clay.cylinder(self, 0.16, 0.04, Vector3(x, from - 0.01, z), RIM_COLOR)
				Clay.cylinder(self, 0.12, 0.05, Vector3(x, from - 0.015, z), HOLE)
			for i in 3:
				Clay.box(self, Vector3(1.0, 0.04, 0.02), Vector3(0.0, to - 0.3 - i * 0.12, half + depth + 0.005), HOLE)
		"small_balls":
			# Una caja; arriba, en sus esquinas, dos bolas chicas metidas a medias con una campana corta; abajo, dos campanas
			# cortas.
			var from := bottom + 0.18
			Clay.box(self, Vector3(1.4, to - from, depth), Vector3(0.0, (from + to) * 0.5, z), shell)
			for s: float in [-1.0, 1.0]:
				var ball := Vector3(s * 0.7, to - 0.25, z)
				Clay.sphere(self, 0.17, ball, JOINT)
				_bell(ball + Vector3(0.0, -0.15, 0.0), 0.06, 0.1, 0.16, deg_to_rad(10.0) * s)
				_bell(Vector3(s * 0.35, from, z), 0.07, 0.12, 0.17, 0.0)
		"twin":
			# Dos cajas mellizas con la tapa redonda, separadas por una ranura; cada una con una campana corta abajo.
			var from := bottom + 0.18
			var top_y := to - depth * 0.5
			for s: float in [-1.0, 1.0]:
				var x := s * 0.4
				Clay.box(self, Vector3(0.72, top_y - from, depth), Vector3(x, (from + top_y) * 0.5, z), shell)
				Clay.cylinder(self, depth * 0.5, 0.72, Vector3(x, top_y, z), shell, Vector3(0.0, 0.0, 90.0))
				_bell(Vector3(x, from, z), 0.08, 0.14, 0.18, 0.0)
			Clay.box(self, Vector3(1.6, 0.12, depth * 0.6), Vector3(0.0, (from + top_y) * 0.5, z), RIM_COLOR)


## Una campana dentro de `holder`, colgando de su origen hacia su −Y.
func _bell_in(holder: Node3D, narrow: float, wide: float, length: float) -> void:
	var nozzle := MeshInstance3D.new()
	var bell := CylinderMesh.new()
	bell.top_radius = narrow
	bell.bottom_radius = wide
	bell.height = length
	nozzle.mesh = bell
	nozzle.material_override = Clay.material(RIM_COLOR)
	nozzle.position = Vector3(0.0, -length * 0.5, 0.0)
	holder.add_child(nozzle)


## LA MOCHILA DEL JETPACK, en la cara de atrás (`half`) entre `from` y `to` (alturas): la caja, dos tanques redondos a
## los costados con sus aros, y dos toberas abajo, mirando hacia abajo y un poco atrás.
func _jetpack(from: float, to: float, half: float) -> void:
	# Toda la espalda de ancho (el usuario: «el ancho… debería ocupar toda la espalda, y que las toberas esfera
	# izquierda y derecha sobresalgan»).
	var tall := to - from
	var center := Vector3(0.0, from + tall * 0.5, half + 0.22)
	# Más angosta (el usuario: «quedó demasiado ancho… las toberas con esferas deberían no sobresalir… más angosto todo»):
	# las bolas llegan justo al borde de la espalda y la caja va de centro a centro de las bolas.
	var ball_radius := 0.32
	var ball_x := 1.0 - ball_radius
	Clay.box(self, Vector3(ball_x * 2.0, tall, 0.44), center, DARK.lightened(0.15))
	for y: float in [0.25, -0.2]:
		Clay.box(self, Vector3(ball_x * 2.0 + 0.04, 0.06, 0.48), center + Vector3(0.0, tall * y, 0.0), RIM_COLOR)
	# Arriba, a los costados, las dos toberas de bola grande, que sobresalen de la espalda; la campana sale de abajo de la
	# bola, apenas abierta hacia afuera.
	for s: float in [-1.0, 1.0]:
		var ball := Vector3(s * ball_x, to - ball_radius, center.z)
		Clay.sphere(self, ball_radius, ball, JOINT)
		_bell(ball + Vector3(0.0, -0.3, 0.0), 0.12, 0.24, 0.5, deg_to_rad(12.0) * s)
	# Abajo, dos campanas sin bola, colgando del fondo de la mochila, apenas abiertas hacia afuera.
	var low := from
	for s: float in [-1.0, 1.0]:
		Clay.cylinder(self, 0.13, 0.06, Vector3(s * 0.3, low - 0.03, center.z), RIM_COLOR)
		_bell(Vector3(s * 0.3, low - 0.05, center.z), 0.09, 0.19, 0.4, deg_to_rad(8.0) * s)


## UNA CAMPANA que cuelga de `at` (su boca chica arriba), de `length` de largo, abierta `tilt` hacia afuera (radianes,
## hacia +x si es positivo).
func _bell(at: Vector3, narrow: float, wide: float, length: float, tilt: float) -> void:
	var holder := Node3D.new()
	holder.position = at
	holder.rotation.z = tilt
	add_child(holder)
	var nozzle := MeshInstance3D.new()
	var bell := CylinderMesh.new()
	bell.top_radius = narrow
	bell.bottom_radius = wide
	bell.height = length
	nozzle.mesh = bell
	nozzle.material_override = Clay.material(RIM_COLOR)
	nozzle.position = Vector3(0.0, -length * 0.5, 0.0)
	holder.add_child(nozzle)

## Un prisma de grosor `thick` en x, centrado en `x`, con el contorno convexo `profile` en (z, y).
func _prism(x: float, thick: float, profile: PackedVector2Array, color: Color) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := PackedVector3Array()
	var count := profile.size()
	for side: float in [-thick * 0.5, thick * 0.5]:
		for point in profile:
			points.append(Vector3(x + side, point.y, point.x))
	for i in range(1, count - 1):
		for cap in [0, count]:
			for tri: Array in [[cap, cap + i, cap + i + 1]]:
				for index: int in tri:
					tool.add_vertex(points[index])
	for i in count:
		var j := (i + 1) % count
		for tri: Array in [[i, j, count + j], [i, count + j, count + i]]:
			for index: int in tri:
				tool.add_vertex(points[index])
	tool.generate_normals()
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	add_child(mesh)


## ── EL ARTILLERO ─────────────────────────────────────────────────────────────────────────────────────────────────

## 93 · UNA TORRE CORTA detrás del borde, pegada al lomo: arriba, una plataforma redonda con baranda, él sentado y el
## arma, que pasa por encima de la cabeza del de los brazos.
func _tower() -> void:
	var foot := Vector3(0.0, _deck - 0.5, 1.45)
	var high := _deck + 1.35
	Clay.box(self, Vector3(0.7, high - foot.y, 0.5), Vector3(0.0, (high + foot.y) * 0.5, foot.z), BODY)
	Clay.cylinder(self, 0.7, 0.12, Vector3(0.0, high, foot.z), METAL)
	_ring_rail(Vector3(0.0, high, foot.z), 0.7, 0.55, PI * 0.6)
	_gunner(Vector3(0.0, high + 0.06, foot.z + 0.05))
	_top = high + 1.3


## 103 a 106 · EL MONTAJE ARTICULADO: la columna metálica abrazada al lomo con dos grampas; arriba, el rulemán con
## sus bulones (gira); encima, la horquilla con su perno (cabecea) o una rótula; y la cuna con el asiento, el artillero
## y el arma, que se mueve entera.
func _mount(plan: Array) -> void:
	var joint: String = plan[0]
	var pod_y := _bottom + 0.85
	var z := 1.15
	var low := pod_y - 0.4
	var head := _deck + 0.9
	Clay.cylinder(self, 0.26, head - low, Vector3(0.0, (head + low) * 0.5, z), METAL)
	Clay.sphere(self, 0.26, Vector3(0.0, low, z), METAL)
	for y: float in [pod_y - 0.1, _deck - 0.25]:
		Clay.cylinder(self, 0.33, 0.1, Vector3(0.0, y, z), DARK)
		Clay.box(self, Vector3(0.18, 0.1, 0.3), Vector3(0.0, y, z - 0.3), DARK)
	# El rulemán: dos aros y los bulones.
	Clay.cylinder(self, 0.4, 0.1, Vector3(0.0, head + 0.05, z), RIM_COLOR)
	for i in 8:
		var a := TAU * i / 8.0
		Clay.cylinder(self, 0.03, 0.05, Vector3(sin(a) * 0.33, head + 0.12, z - cos(a) * 0.33), DARK)
	var yaw := Node3D.new()
	yaw.position = Vector3(0.0, head + 0.1, z)
	yaw.rotation.y = -deg_to_rad(float(plan[1]))
	add_child(yaw)
	Clay.cylinder(yaw, 0.36, 0.1, Vector3(0.0, 0.05, 0.0), METAL)
	var pitch := Node3D.new()
	if joint == "fork":
		# La horquilla: dos chapas y el perno de lado a lado.
		for s: float in [-1.0, 1.0]:
			Clay.box(yaw, Vector3(0.08, 0.55, 0.34), Vector3(s * 0.34, 0.37, 0.0), METAL)
		Clay.cylinder(yaw, 0.07, 0.86, Vector3(0.0, 0.5, 0.0), DARK, Vector3(0.0, 0.0, 90.0))
		for s: float in [-1.0, 1.0]:
			Clay.cylinder(yaw, 0.11, 0.04, Vector3(s * 0.4, 0.5, 0.0), RIM_COLOR, Vector3(0.0, 0.0, 90.0))
		pitch.position = Vector3(0.0, 0.5, 0.0)
	else:
		# La rótula: un cuello corto y la bola.
		Clay.cylinder(yaw, 0.16, 0.25, Vector3(0.0, 0.2, 0.0), METAL)
		Clay.sphere(yaw, 0.24, Vector3(0.0, 0.42, 0.0), JOINT)
		pitch.position = Vector3(0.0, 0.42, 0.0)
	pitch.rotation.x = deg_to_rad(float(plan[2]))
	yaw.add_child(pitch)
	# La cuna: la placa con el asiento, el artillero, el apoyapiés, el arma y el escudo.
	Clay.box(pitch, Vector3(0.6, 0.08, 0.7), Vector3(0.0, 0.0, 0.05), DARK)
	if joint == "ball":
		Clay.cylinder(pitch, 0.1, 0.18, Vector3(0.0, -0.1, 0.0), DARK)
	_seated_in(pitch, Vector3(0.0, -0.38, 0.05))
	Clay.box(pitch, Vector3(0.5, 0.06, 0.25), Vector3(0.0, -0.3, -0.55), DARK)
	Clay.segment(Clay.box(pitch, Vector3.ONE, Vector3.ZERO, DARK), Vector3(0.0, 0.0, -0.25), Vector3(0.0, -0.3, -0.55),
		0.06)
	var gun := Vector3(0.0, 0.48, -0.7)
	Clay.segment(Clay.box(pitch, Vector3.ONE, Vector3.ZERO, DARK), Vector3(0.0, 0.0, -0.25), gun, 0.08)
	Clay.box(pitch, Vector3(0.3, 0.25, 0.5), gun + Vector3(0.0, 0.0, 0.1), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(pitch, 0.035, 0.9, gun + Vector3(x, y, -0.55), RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(pitch, Vector3(0.9, 0.5, 0.05), gun + Vector3(0.0, -0.05, -0.2), METAL)
	_top = head + 2.0


## 107 a 109 · EL RESPALDO QUE CABECEA: la columna (que empieza más arriba que en la 105), el rulemán, el asiento que
## gira con él y, sobre un perno a la altura de la cadera, el respaldo con el artillero y el arma.
func _recline_mount(plan: Array) -> void:
	var z := 1.15
	var low := _deck - 0.75
	var head := _deck + 1.2
	Clay.cylinder(self, 0.26, head - low, Vector3(0.0, (head + low) * 0.5, z), METAL)
	Clay.sphere(self, 0.26, Vector3(0.0, low, z), METAL)
	for y: float in [low + 0.25, _deck - 0.1]:
		Clay.cylinder(self, 0.33, 0.1, Vector3(0.0, y, z), DARK)
		Clay.box(self, Vector3(0.18, 0.1, 0.3), Vector3(0.0, y, z - 0.3), DARK)
	Clay.cylinder(self, 0.4, 0.1, Vector3(0.0, head + 0.05, z), RIM_COLOR)
	for i in 8:
		var a := TAU * i / 8.0
		Clay.cylinder(self, 0.03, 0.05, Vector3(sin(a) * 0.33, head + 0.12, z - cos(a) * 0.33), DARK)
	var yaw := Node3D.new()
	yaw.position = Vector3(0.0, head + 0.1, z)
	yaw.rotation.y = -deg_to_rad(float(plan[0]))
	add_child(yaw)
	# Lo que gira y no cabecea: el plato, el pie del asiento, el asiento, las piernas y el apoyapiés.
	Clay.cylinder(yaw, 0.36, 0.1, Vector3(0.0, 0.05, 0.0), METAL)
	Clay.box(yaw, Vector3(0.14, 0.25, 0.14), Vector3(0.0, 0.22, 0.1), DARK)
	Clay.box(yaw, Vector3(0.5, 0.1, 0.48), Vector3(0.0, 0.38, 0.05), SEAT)
	Clay.box(yaw, Vector3(0.34, 0.14, 0.42), Vector3(0.0, 0.5, -0.12), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(yaw, Vector3(0.12, 0.38, 0.12), Vector3(side * 0.1, 0.27, -0.32), SKIN)
	Clay.box(yaw, Vector3(0.45, 0.05, 0.2), Vector3(0.0, 0.08, -0.4), DARK)
	Clay.segment(Clay.box(yaw, Vector3.ONE, Vector3.ZERO, DARK), Vector3(0.0, 0.12, 0.05), Vector3(0.0, 0.08, -0.35),
		0.05)
	# El perno del respaldo, de lado a lado, atrás del asiento a la altura de la cadera.
	var pivot := Vector3(0.0, 0.48, 0.25)
	Clay.cylinder(yaw, 0.06, 0.62, pivot, RIM_COLOR, Vector3(0.0, 0.0, 90.0))
	for side: float in [-1.0, 1.0]:
		Clay.box(yaw, Vector3(0.05, 0.22, 0.14), pivot + Vector3(side * 0.29, -0.1, 0.0), DARK)
	var pitch := Node3D.new()
	pitch.position = pivot
	pitch.rotation.x = deg_to_rad(float(plan[1]))
	yaw.add_child(pitch)
	# Lo que cabecea: el respaldo, él de la cintura para arriba, los brazos del arma y el arma con su escudo.
	Clay.box(pitch, Vector3(0.5, 0.75, 0.1), Vector3(0.0, 0.38, 0.05), SEAT)
	Clay.box(pitch, Vector3(0.38, 0.55, 0.24), Vector3(0.0, 0.32, -0.12), SKIN)
	Clay.sphere(pitch, 0.12, Vector3(0.0, 0.73, -0.14), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(pitch, Vector3(0.1, 0.1, 0.38), Vector3(side * 0.24, 0.38, -0.36), SKIN)
	var gun := Vector3(0.0, 0.62, -0.85)
	for side: float in [-1.0, 1.0]:
		Clay.segment(Clay.box(pitch, Vector3.ONE, Vector3.ZERO, DARK), Vector3(side * 0.3, 0.15, 0.02),
			gun + Vector3(side * 0.18, -0.05, 0.15), 0.06)
	Clay.box(pitch, Vector3(0.42, 0.06, 0.06), gun + Vector3(0.0, -0.05, 0.15), DARK)
	Clay.box(pitch, Vector3(0.3, 0.25, 0.5), gun + Vector3(0.0, 0.0, 0.1), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(pitch, 0.035, 0.9, gun + Vector3(x, y, -0.55), RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(pitch, Vector3(0.9, 0.5, 0.05), gun + Vector3(0.0, -0.05, -0.2), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(pitch, 0.03, 0.2, gun + Vector3(side * 0.13, -0.05, 0.35), YELLOW, Vector3(90.0, 0.0, 0.0))
	_top = head + 2.1


## 110 a 112 · EL ARMA CON SU PROPIO PIE: la columna, el rulemán; en el plato que gira, el asiento (el respaldo cabecea
## sobre su perno) y, adelante, el pie del arma con su horquilla (el arma cabecea ahí, el mismo ángulo).
func _own_foot_mount(plan: Array, integrated := false) -> void:
	var z := 0.72 if integrated else 1.15
	# Empieza más arriba (el usuario: «la torre de atrás debería comenzar más arriba. Así hay más espacio libre atrás»):
	# apenas debajo de la cubierta, con una sola grampa.
	var low := _deck - 0.35
	# Más alta que la del principio (el usuario: «la torre… un poquito más alta… no llega a coincidir con el conductor,
	# pero tampoco es lo suficientemente alta como para que se note que es algo distinto… así no está tan justo con la
	# cabeza»).
	var head := _deck + TOWER_TALL
	if integrated:
		# Un bloque dentro de la planta, contra la cara de atrás, a la altura de la pared de atrás.
		Clay.box(self, Vector3(1.2, TOWER_TALL, 0.56), Vector3(0.0, _deck + TOWER_TALL * 0.5, z), BODY)
		Clay.box(self, Vector3(1.22, 0.08, 0.58), Vector3(0.0, head - 0.15, z), RIM_COLOR)
	else:
		Clay.cylinder(self, 0.26, head - low, Vector3(0.0, (head + low) * 0.5, z), METAL)
		Clay.sphere(self, 0.26, Vector3(0.0, low, z), METAL)
		for y: float in [_deck - 0.12]:
			Clay.cylinder(self, 0.33, 0.1, Vector3(0.0, y, z), DARK)
			Clay.box(self, Vector3(0.18, 0.1, 0.3), Vector3(0.0, y, z - 0.3), DARK)
	Clay.cylinder(self, 0.42, 0.1, Vector3(0.0, head + 0.05, z), RIM_COLOR)
	for i in 8:
		var a := TAU * i / 8.0
		Clay.cylinder(self, 0.03, 0.05, Vector3(sin(a) * 0.35, head + 0.12, z - cos(a) * 0.35), DARK)
	var angle := deg_to_rad(float(plan[1]))
	var yaw := Node3D.new()
	yaw.position = Vector3(0.0, head + 0.1, z)
	yaw.rotation.y = -deg_to_rad(float(plan[0]))
	add_child(yaw)
	# El plato, alargado hacia adelante para llevar el pie del arma.
	Clay.cylinder(yaw, 0.4, 0.1, Vector3(0.0, 0.05, 0.1), METAL)
	var reach := 0.35 if integrated else 0.5
	Clay.box(yaw, Vector3(0.3, 0.1, reach - 0.05), Vector3(0.0, 0.05, -reach * 0.5 - 0.15), METAL)
	# El asiento: su pie, el asiento, las piernas y el apoyapiés.
	Clay.box(yaw, Vector3(0.14, 0.25, 0.14), Vector3(0.0, 0.22, 0.15), DARK)
	Clay.box(yaw, Vector3(0.5, 0.1, 0.48), Vector3(0.0, 0.38, 0.1), SEAT)
	Clay.box(yaw, Vector3(0.34, 0.14, 0.42), Vector3(0.0, 0.5, -0.07), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(yaw, Vector3(0.12, 0.38, 0.12), Vector3(side * 0.13, 0.27, -0.27), SKIN)
		Clay.box(yaw, Vector3(0.12, 0.05, 0.2), Vector3(side * 0.2, 0.12, -0.38), DARK)
	# El respaldo y él de la cintura para arriba, sobre el perno de la cadera.
	var pivot := Vector3(0.0, 0.48, 0.3)
	Clay.cylinder(yaw, 0.06, 0.62, pivot, RIM_COLOR, Vector3(0.0, 0.0, 90.0))
	for side: float in [-1.0, 1.0]:
		Clay.box(yaw, Vector3(0.05, 0.22, 0.14), pivot + Vector3(side * 0.29, -0.1, 0.0), DARK)
	var back := Node3D.new()
	back.position = pivot
	back.rotation.x = angle
	yaw.add_child(back)
	Clay.box(back, Vector3(0.5, 0.75, 0.1), Vector3(0.0, 0.38, 0.05), SEAT)
	Clay.box(back, Vector3(0.38, 0.55, 0.24), Vector3(0.0, 0.32, -0.12), SKIN)
	Clay.sphere(back, 0.12, Vector3(0.0, 0.73, -0.14), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.segment(Clay.box(back, Vector3.ONE, Vector3.ZERO, SKIN), Vector3(side * 0.22, 0.5, -0.12),
			Vector3(side * 0.16, 0.28, -0.5), 0.1)
	# EL PIE DEL ARMA, adelante en el plato, con su horquilla; el arma cabecea en ella.
	var foot := Vector3(0.0, 0.1, -reach)
	var trunnion := Vector3(0.0, 0.78, -reach)
	Clay.cylinder(yaw, 0.08, trunnion.y - foot.y - 0.1, Vector3(0.0, (trunnion.y + foot.y) * 0.5 - 0.05, foot.z), DARK)
	for side: float in [-1.0, 1.0]:
		Clay.box(yaw, Vector3(0.05, 0.22, 0.12), trunnion + Vector3(side * 0.2, -0.06, 0.0), DARK)
	Clay.box(yaw, Vector3(0.45, 0.06, 0.12), trunnion + Vector3(0.0, -0.17, 0.0), DARK)
	Clay.cylinder(yaw, 0.04, 0.5, trunnion, RIM_COLOR, Vector3(0.0, 0.0, 90.0))
	var gun := Node3D.new()
	gun.position = trunnion
	gun.rotation.x = angle
	yaw.add_child(gun)
	Clay.box(gun, Vector3(0.3, 0.25, 0.55), Vector3(0.0, 0.0, -0.05), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(gun, 0.035, 0.9, Vector3(x, y, -0.75), RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(gun, Vector3(0.9, 0.5, 0.05), Vector3(0.0, 0.05, -0.38), METAL)
	# Las manijas, hacia atrás, a la altura de las manos.
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(gun, 0.03, 0.22, Vector3(side * 0.16, -0.06, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))
	_top = head + 1.6


## 113 y 114 · LAS PIERNAS Y LOS BRAZOS DEL JUEGO, a escala `k`: un cuerpo de medidas (MechBody) achicado; las piernas
## son MechLeg puestas con `leg`; los brazos, las piezas de PoseArm (cilindros, el hombro y el codo esféricos, la mano
## de MechHand) puestas con `arm`, en guardia.
func _real_limbs(k: float) -> void:
	var full := MechBody.new()
	var body := MechBody.new()
	body.thick = full.thick * k
	body.WAIST = full.WAIST * k
	body.HIP_X = full.HIP_X * k
	body.HIP_DROP = full.HIP_DROP * k
	body.THIGH = full.THIGH * k
	body.SHIN = full.SHIN * k
	body.LEG_THICKNESS = full.LEG_THICKNESS * k
	body.JOINT_RADIUS = full.JOINT_RADIUS * k
	body.ANKLE = full.ANKLE * k
	body.FOOT_SIZE = full.FOOT_SIZE * k
	body.FOOT_AHEAD = full.FOOT_AHEAD * k
	body.STANCE_X = full.STANCE_X * k
	body.UPPER_ARM = full.UPPER_ARM * k
	body.FOREARM = full.FOREARM * k
	var waist := Transform3D(Basis(), Vector3(0.0, body.WAIST, 0.0))
	if _variant in CYLINDER_PELVIS:
		var hip_y := body.WAIST - body.HIP_DROP
		Clay.cylinder(self, body.LEG_THICKNESS * 0.55, body.HIP_X * 2.0 - body.LEG_THICKNESS * 0.9,
			Vector3(0.0, hip_y, 0.0), MechBody.JOINT_COLOR, Vector3(0.0, 0.0, 90.0))
	for side: float in [-1.0, 1.0]:
		var leg := MechLeg.new()
		leg.measures = body
		add_child(leg)
		leg.pose(body.leg(body.hip(waist, side), body.foot_rest(Transform3D(), side), Basis()))
		if _variant in [117, 118]:
			leg._hip.visible = false
			Clay.sphere(self, body.JOINT_RADIUS * 1.1, body.hip(waist, side), MechBody.JOINT_COLOR)
	var thick := body.LEG_THICKNESS
	for side: float in [-1.0, 1.0]:
		var shoulder := Vector3(side * (1.0 + thick * 0.7), _arms_mid if _arms_mid != 0.0 else _deck - 0.5, -0.1)
		if _number in SHOULDERS_UP:
			shoulder.y = _deck + 0.38
		if SHOULDER_HEIGHT.has(_number):
			shoulder.y = _deck + float(SHOULDER_HEIGHT[_number])
		var fist := shoulder + Vector3(side * 0.25, -body.UPPER_ARM * 0.75, -body.FOREARM * 0.85)
		var pose := body.arm(shoulder, fist, side, Basis())
		var upper := Clay.limb(self, thick * 0.5, body.UPPER_ARM, Vector3.ZERO, Clay.METAL.darkened(0.1))
		var forearm := Clay.limb(self, thick * 0.5, body.FOREARM, Vector3.ZERO, Clay.METAL.darkened(0.2))
		upper.transform = pose["upper"]
		forearm.transform = pose["forearm"]
		Clay.sphere(upper, thick * 0.78, Vector3(0, 0, body.UPPER_ARM * 0.5), MechBody.JOINT_COLOR)
		Clay.sphere(forearm, thick * 0.66, Vector3(0, 0, body.FOREARM * 0.5), MechBody.JOINT_COLOR)
		if POLES.has(_number):
			_pauldron(shoulder, side, thick)
		if _number in ARMED:
			_armed_arm(upper, forearm, side, k, body)
			continue
		var hand := MechHand.build(forearm, side)
		hand.transform = Transform3D(Basis(Vector3.BACK, PI * 0.5).scaled(Vector3.ONE * body.thick),
			Vector3(0, 0, -body.FOREARM * 0.5))
	if _number in ARMED:
		for leg: Node in find_children("*", "MechLeg", true, false):
			for piece: Node3D in [leg._thigh, leg._shin]:
				var length: float = (MechBody.new().THIGH * 0.75) if piece == leg._thigh else (MechBody.new().SHIN * 0.8)
				_plate(piece, Vector3.FORWARD, k, length)


## Un piloto sentado colgado de `parent` (como `_seated`), mirando a −Z del padre.
func _seated_in(parent: Node3D, at: Vector3) -> void:
	Clay.box(parent, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(parent, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(parent, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(parent, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(parent, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(parent, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(parent, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## 97 a 102 · LA TORRE DE OTRAS FORMAS, pegada a la cápsula (de radio 1); arriba, la misma plataforma de la 93.
func _tower_shape(kind: int) -> void:
	var high := _deck + 1.35
	var pod_y := _bottom + 0.85
	var z := 1.3
	match kind:
		97:
			# Un pilar cuadrado desde abajo de la cápsula hasta la plataforma, metido en su lomo.
			var low := _bottom - 0.2
			Clay.box(self, Vector3(0.75, high - low, 0.65), Vector3(0.0, (high + low) * 0.5, 1.0), BODY)
			z = 1.25
		98:
			# Una columna redonda, metida en el lomo, con un aro donde se apoya.
			var low := pod_y - 0.3
			Clay.cylinder(self, 0.36, high - low, Vector3(0.0, (high + low) * 0.5, 1.1), BODY)
			Clay.cylinder(self, 0.44, 0.12, Vector3(0.0, _deck - 0.1, 1.1), RIM_COLOR)
			Clay.sphere(self, 0.36, Vector3(0.0, low, 1.1), BODY)
			z = 1.2
		99:
			# La pared de la cápsula sigue subiendo atrás: un tramo de cilindro (un tercio de vuelta) hasta la plataforma.
			var step := TAU / 36.0
			for k in 12:
				var a := PI - step * 6 + step * (k + 0.5)
				var piece := Clay.box(self, Vector3(0.16, high - _deck + 0.2, 2.0 * 1.0 * sin(step * 0.5) + 0.02),
					Vector3(sin(a) * 0.93, (high + _deck - 0.2) * 0.5, -cos(a) * 0.93), BODY)
				piece.basis = Basis(Vector3.UP, PI * 0.5 - a)
			z = 1.0
		100:
			# Dos patas en A, de los costados del lomo a la plataforma, con un travesaño.
			for s: float in [-1.0, 1.0]:
				Clay.segment(Clay.box(self, Vector3.ONE, Vector3.ZERO, DARK), Vector3(s * 0.65, pod_y - 0.3, 0.75),
					Vector3(s * 0.25, high - 0.05, 1.35), 0.16)
				Clay.sphere(self, 0.14, Vector3(s * 0.65, pod_y - 0.3, 0.75), JOINT)
			Clay.box(self, Vector3(0.95, 0.1, 0.1), Vector3(0.0, (pod_y + high) * 0.5 - 0.1, 1.05), DARK)
		101:
			# Un cuello curvo de tramos gruesos: sale del lomo, se va para atrás y sube a la plataforma.
			var from := Vector3(0.0, pod_y - 0.4, 0.85)
			var bend := Vector3(0.0, pod_y + 0.3, 1.75)
			var to := Vector3(0.0, high - 0.05, 1.35)
			var last := from
			for i in range(1, 9):
				var t := i / 8.0
				var at := from.lerp(bend, t).lerp(bend.lerp(to, t), t)
				Clay.segment(Clay.box(self, Vector3.ONE, Vector3.ZERO, BODY), last, at, 0.42 - 0.12 * t)
				Clay.sphere(self, (0.42 - 0.12 * t) * 0.62, at, BODY)
				last = at
		102:
			# Cilindros apilados que se achican hacia arriba, el primero metido en el lomo.
			var y := pod_y - 0.4
			var parts := [[0.55, 0.75, 1.05], [0.45, 0.8, 1.15], [0.36, high - (pod_y - 0.4) - 1.55, 1.25]]
			for part: Array in parts:
				var radius: float = part[0]
				var tall: float = part[1]
				Clay.cylinder(self, radius, tall, Vector3(0.0, y + tall * 0.5, part[2]), BODY)
				Clay.cylinder(self, radius + 0.04, 0.06, Vector3(0.0, y + tall, part[2]), RIM_COLOR)
				y += tall
			z = 1.25
	Clay.cylinder(self, 0.7, 0.12, Vector3(0.0, high, z), METAL)
	_ring_rail(Vector3(0.0, high, z), 0.7, 0.55, PI * 0.6)
	_gunner(Vector3(0.0, high + 0.06, z + 0.05))
	_top = high + 1.3


## 94 · UN SEGUNDO TAMBOR ABIERTO, igual al de los brazos, pegado atrás de la cápsula y colgando de su lomo: el
## artillero de pie adentro, el arma montada sobre su borde de atrás.
func _twin(walk: float) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(0.0, 0.0, 2.05)
	add_child(holder)
	var outer := walk + RIM
	Clay.cylinder(holder, outer, 1.2, Vector3(0.0, _deck - 0.6, 0.0), BODY)
	Clay.sphere(holder, outer, Vector3(0.0, _deck - 1.2, 0.0), BODY)
	_revolve(PackedVector2Array([Vector2(0.0, _deck), Vector2(walk, _deck)]), DECK, holder)
	_revolve(PackedVector2Array([Vector2(walk, _deck), Vector2(walk, _deck + RIM_IN), Vector2(outer, _deck + RIM_OUT),
		Vector2(outer, _deck - 0.12), Vector2(0.0, _deck - 0.12)]), METAL, holder)
	Clay.box(self, Vector3(0.9, 0.5, 0.4), Vector3(0.0, _deck - 0.6, 1.0), BODY)
	_mounted_gun(Vector3(0.0, _deck + RIM_OUT, 2.05 + outer * 0.75), PI)
	_standing(Vector3(0.0, _deck, 2.05 + 0.15))


## (YA NO SE USA) LA CUBIERTA MÁS GRANDE: el artillero de pie en el borde de atrás, el arma montada sobre el borde, mirando hacia
## atrás; gira sobre su poste.
func _rim_gun(walk: float) -> void:
	var at := Vector3(0.0, _deck + RIM_OUT, walk + RIM * 0.6)
	_mounted_gun(at, PI)
	_standing(Vector3(0.0, _deck, walk - 0.55))


## 95 · UN BALCÓN MÁS BAJO, colgado del lomo de la cápsula: su piso, su baranda y el arma sobre ella, mirando atrás.
func _balcony() -> void:
	var floor_y := _deck - 0.9
	var center := Vector3(0.0, floor_y, 1.75)
	Clay.box(self, Vector3(1.6, 0.12, 1.2), center + Vector3(0.0, -0.06, 0.0), METAL)
	for s: float in [-1.0, 1.0]:
		Clay.segment(Clay.box(self, Vector3.ONE, Vector3.ZERO, DARK), Vector3(s * 0.6, floor_y - 0.1, 1.2),
			Vector3(s * 0.5, floor_y - 0.9, 0.85), 0.1)
	_box_rail(center, Vector2(1.6, 1.2), 1.0)
	_mounted_gun(Vector3(0.0, floor_y + 1.0, 2.35), PI)
	_standing(Vector3(0.0, floor_y, 1.75))


## 96 · LA PLUMA: un brazo que sale del lomo hacia atrás y arriba; en la punta, una plataforma redonda con baranda, él
## sentado y el arma.
func _boom() -> void:
	var root := Vector3(0.0, _deck - 0.3, 0.95)
	var tip := Vector3(0.0, _deck + 1.5, 2.3)
	Clay.segment(Clay.box(self, Vector3.ONE, Vector3.ZERO, DARK), root, tip, 0.3)
	Clay.sphere(self, 0.22, root, JOINT)
	Clay.sphere(self, 0.2, tip, JOINT)
	Clay.cylinder(self, 0.7, 0.12, tip + Vector3(0.0, 0.1, 0.0), METAL)
	_ring_rail(tip + Vector3(0.0, 0.1, 0.0), 0.7, 0.55, PI * 0.6)
	_gunner(tip + Vector3(0.0, 0.16, 0.05))
	_top = tip.y + 1.4


## Un arma montada en un poste (para el que va de pie): el poste, el cuerpo, el caño, el escudo y las manijas; `turn`,
## hacia dónde apunta (0, adelante).
func _mounted_gun(at: Vector3, turn: float) -> void:
	var gun := Node3D.new()
	gun.position = at
	gun.rotation.y = turn
	add_child(gun)
	Clay.cylinder(gun, 0.07, 0.3, Vector3(0.0, 0.15, 0.0), DARK)
	Clay.box(gun, Vector3(0.26, 0.26, 0.6), Vector3(0.0, 0.42, -0.05), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(gun, 0.035, 0.9, Vector3(x, 0.42 + y, -0.8), RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(gun, Vector3(0.7, 0.4, 0.04), Vector3(0.0, 0.5, -0.38), METAL)
	for side: float in [-1.0, 1.0]:
		Clay.cylinder(gun, 0.03, 0.2, Vector3(side * 0.13, 0.38, 0.3), YELLOW, Vector3(90.0, 0.0, 0.0))


## Una baranda redonda (postes y pasamanos) de radio `radius` y alto `tall`, sin el tramo de adelante (`open`, el ancho
## del hueco en radianes, para que tire el arma).
func _ring_rail(center: Vector3, radius: float, tall: float, open: float) -> void:
	var count := 20
	for i in count:
		var a := TAU * (i + 0.5) / count
		if absf(wrapf(a, -PI, PI)) < open * 0.5:
			continue
		var at := center + Vector3(sin(a) * radius, tall, -cos(a) * radius)
		var rail := Clay.box(self, Vector3(0.04, 0.04, 2.0 * radius * sin(PI / count) + 0.02), at, RIM_COLOR)
		rail.basis = Basis(Vector3.UP, PI * 0.5 - a)
		if i % 2 == 0:
			Clay.box(self, Vector3(0.035, tall, 0.035), at - Vector3(0.0, tall * 0.5, 0.0), RIM_COLOR)


## Una baranda rectangular alrededor de un piso de `size`, sin el lado que da a la cápsula.
func _box_rail(center: Vector3, size: Vector2, tall: float) -> void:
	var y := center.y + tall
	Clay.box(self, Vector3(size.x, 0.04, 0.04), Vector3(0.0, y, center.z + size.y * 0.5), RIM_COLOR)
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.04, 0.04, size.y), Vector3(s * size.x * 0.5, y, center.z), RIM_COLOR)
		for z: float in [center.z - size.y * 0.5, center.z + size.y * 0.5]:
			Clay.box(self, Vector3(0.035, tall, 0.035), Vector3(s * size.x * 0.5, center.y + tall * 0.5, z), RIM_COLOR)


## UNA VUELTA de un perfil (`r`, `y`) alrededor del eje: suave alrededor, con aristas en las esquinas.
func _revolve(profile: PackedVector2Array, color: Color, parent: Node3D = null) -> void:
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 64
	for s in sides:
		var a0 := TAU * s / sides
		var a1 := TAU * (s + 1) / sides
		for p in profile.size() - 1:
			var p0 := profile[p]
			var p1 := profile[p + 1]
			var edge := p1 - p0
			var normal := Vector2(edge.y, -edge.x).normalized()
			var quad := [[p0, a0], [p1, a0], [p1, a1], [p0, a1]]
			for corner: int in [0, 1, 2, 0, 2, 3]:
				var point: Vector2 = quad[corner][0]
				var angle: float = quad[corner][1]
				var out := Vector3(sin(angle), 0.0, -cos(angle))
				tool.set_normal(out * normal.x + Vector3.UP * normal.y)
				tool.add_vertex(out * point.x + Vector3.UP * point.y)
	var mesh := MeshInstance3D.new()
	mesh.mesh = tool.commit()
	var paint := Clay.material(color).duplicate() as StandardMaterial3D
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh.material_override = paint
	(parent if parent != null else self).add_child(mesh)


## ── LAS PIEZAS ───────────────────────────────────────────────────────────────────────────────────────────────────

## Un elipsoide de arcilla (o de vidrio) de radios `radii`.
func _ellipsoid(radii: Vector3, at: Vector3, color: Color) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.0
	sphere.height = 2.0
	mesh.mesh = sphere
	mesh.material_override = Clay.material(color)
	mesh.scale = radii
	mesh.position = at
	add_child(mesh)
	return mesh


## La ventanita baja del que maneja: una ranura oscura.
func _slit(at: Vector3, wide: float) -> void:
	Clay.box(self, Vector3(wide, 0.18, 0.2), at, HOLE)


## LA TAPA DE LA PANZA: un aro y el agujero, y la escalerita que cuelga hasta cerca del suelo.
func _belly(at: Vector3) -> void:
	Clay.cylinder(self, 0.42, 0.06, at, RIM_COLOR)
	Clay.cylinder(self, 0.34, 0.07, at, HOLE)
	var foot := 0.45
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.04, at.y - foot, 0.04), Vector3(s * 0.2, (at.y + foot) * 0.5, at.z + 0.3), RIM_COLOR)
	for i in int((at.y - foot) / 0.3):
		Clay.box(self, Vector3(0.4, 0.035, 0.035), Vector3(0.0, foot + 0.3 * i, at.z + 0.3), RIM_COLOR)


## Agarraderas para trepar (`count`, cada 0,35 m hacia arriba) en una cara.
func _rungs(at: Vector3, count: int, _facing: float) -> void:
	for i in count:
		Clay.box(self, Vector3(0.45, 0.04, 0.08), at + Vector3(0.0, 0.35 * i, 0.0), RIM_COLOR)


## La escalera de atrás, del artillero: de `at` hasta `to` (alto), separada del cuerpo.
func _rungs_back(at: Vector3, to: float) -> void:
	for s: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.04, to - at.y + 0.5, 0.04), Vector3(s * 0.22, (at.y + to + 0.5) * 0.5, at.z), RIM_COLOR)
	for i in int((to - at.y) / 0.3) + 1:
		Clay.box(self, Vector3(0.44, 0.035, 0.035), Vector3(0.0, at.y + 0.3 * i, at.z), RIM_COLOR)


## EL ARTILLERO al aire: su asiento, él, la ametralladora (cuatro caños) apuntando adelante y un escudo.
func _gunner(at: Vector3) -> void:
	_seated(at)
	var gun := at + Vector3(0.0, 0.85, -0.75)
	Clay.box(self, Vector3(0.3, 0.25, 0.5), gun + Vector3(0.0, 0.0, 0.1), DARK)
	for x: float in [-0.06, 0.06]:
		for y: float in [-0.06, 0.06]:
			Clay.cylinder(self, 0.035, 0.9, gun + Vector3(x, y, -0.55), RIM_COLOR, Vector3(90.0, 0.0, 0.0))
	Clay.box(self, Vector3(1.0, 0.55, 0.05), gun + Vector3(0.0, -0.05, -0.2), DARK)


## UN PILOTO SENTADO, de arcilla, mirando adelante (−Z), con su silla: `at`, el piso debajo del asiento.
func _seated(at: Vector3) -> void:
	Clay.box(self, Vector3(0.5, 0.1, 0.48), at + Vector3(0.0, 0.42, 0.05), SEAT)
	Clay.box(self, Vector3(0.5, 0.7, 0.1), at + Vector3(0.0, 0.8, 0.3), SEAT)
	Clay.box(self, Vector3(0.38, 0.55, 0.24), at + Vector3(0.0, 0.76, 0.14), SKIN)
	Clay.sphere(self, 0.12, at + Vector3(0.0, 1.17, 0.12), SKIN)
	Clay.box(self, Vector3(0.34, 0.14, 0.42), at + Vector3(0.0, 0.54, -0.1), SKIN)
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.12, 0.42, 0.12), at + Vector3(side * 0.1, 0.27, -0.28), SKIN)
		Clay.box(self, Vector3(0.1, 0.1, 0.38), at + Vector3(side * 0.24, 0.8, -0.12), SKIN)


## UNA PERSONA PARADA, de arcilla (1,75 m): `at`, el piso entre los pies.
func _standing(at: Vector3) -> void:
	for side: float in [-1.0, 1.0]:
		Clay.box(self, Vector3(0.14, 0.85, 0.16), at + Vector3(side * 0.1, 0.425, 0.0), SKIN)
		Clay.box(self, Vector3(0.1, 0.6, 0.1), at + Vector3(side * 0.27, 1.15, 0.0), SKIN)
	Clay.box(self, Vector3(0.4, 0.6, 0.24), at + Vector3(0.0, 1.15, 0.0), SKIN)
	Clay.sphere(self, 0.13, at + Vector3(0.0, 1.62, 0.0), SKIN)


## UN BRAZO de arcilla desde el hombro: el antebrazo hacia adelante.
func _arm(shoulder: Vector3, side: float) -> void:
	var body := MechBody.new()
	var upper := body.UPPER_ARM * LIMBS
	var fore := body.FOREARM * LIMBS
	var thick := body.LEG_THICKNESS * LIMBS
	var elbow := shoulder + Vector3(side * 0.25, -1.0, 0.25).normalized() * upper
	var hand := elbow + Vector3(0.0, -0.25, -1.0).normalized() * fore
	Clay.sphere(self, thick * 0.7, shoulder, JOINT)
	_limb(shoulder, elbow, thick * 0.48, Clay.METAL.darkened(0.1))
	Clay.sphere(self, thick * 0.55, elbow, JOINT)
	_limb(elbow, hand, thick * 0.45, Clay.METAL.darkened(0.2))
	Clay.sphere(self, thick * 0.6, hand, JOINT)


## LAS PIERNAS de arcilla.
func _legs(hip_y: float) -> void:
	var body := MechBody.new()
	var thick := body.LEG_THICKNESS * LIMBS
	var hip_x := body.HIP_X * LIMBS
	var thigh := body.THIGH * LIMBS
	var foot := body.FOOT_SIZE * LIMBS
	Clay.cylinder(self, thick * 0.43, hip_x * 2.0, Vector3(0.0, hip_y, 0.0), JOINT, Vector3(0.0, 0.0, 90.0))
	for side: float in [-1.0, 1.0]:
		var hip := Vector3(side * hip_x, hip_y, 0.0)
		var ankle := Vector3(side * (hip_x + 0.3 * LIMBS), thick * 0.33 + foot.y * 0.5, 0.0)
		var span := hip.distance_to(ankle)
		var bend := sqrt(maxf(thigh * thigh - span * span * 0.25, 0.0))
		var knee := (hip + ankle) * 0.5 + Vector3(0.0, 0.0, -bend)
		Clay.sphere(self, thick * 0.62, hip, JOINT)
		_limb(hip, knee, thick * 0.5, Clay.METAL.darkened(0.1))
		Clay.sphere(self, thick * 0.62, knee, JOINT)
		_limb(knee, ankle, thick * 0.5, Clay.METAL.darkened(0.2))
		Clay.sphere(self, thick * 0.53, ankle, JOINT)
		Clay.box(self, foot, Vector3(ankle.x, foot.y * 0.5, ankle.z - 0.4 * LIMBS), JOINT)


func _limb(a: Vector3, b: Vector3, radius: float, color: Color) -> void:
	var holder := Clay.limb(self, radius, a.distance_to(b), Vector3.ZERO, color)
	var along := (b - a).normalized()
	var up := Vector3.UP if absf(along.y) < 0.95 else Vector3.BACK
	holder.transform = Transform3D(Basis.looking_at(along, up), (a + b) * 0.5)


## ── LO DE SIEMPRE ────────────────────────────────────────────────────────────────────────────────────────────────

func _stage() -> void:
	var ground := StaticBody3D.new()
	Clay.solid(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0), Color(0.82, 0.80, 0.76))
	add_child(ground)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	sun.shadow_enabled = true
	add_child(sun)
	var world := WorldEnvironment.new()
	world.environment = Environment.new()
	world.environment.background_mode = Environment.BG_COLOR
	world.environment.background_color = Color(0.75, 0.82, 0.9)
	world.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	world.environment.ambient_light_color = Color(0.85, 0.86, 0.9)
	add_child(world)
	_eye = Camera3D.new()
	_eye.far = 1000.0
	add_child(_eye)
	_eye.make_current()
	var layer := CanvasLayer.new()
	add_child(layer)
	_title = Label.new()
	_title.position = Vector2(24, 10)
	_title.add_theme_font_size_override("font_size", 36)
	_title.add_theme_color_override("font_color", Color.BLACK)
	_title.add_theme_color_override("font_outline_color", Color.WHITE)
	_title.add_theme_constant_override("outline_size", 10)
	layer.add_child(_title)


## Una vista: con `fov`, en perspectiva; con fov 0, sin perspectiva, de `ortho` de alto.
func _view(from: Vector3, to: Vector3, fov: float, ortho := 0.0) -> Image:
	if fov > 0.0:
		_eye.projection = Camera3D.PROJECTION_PERSPECTIVE
		_eye.fov = fov
	else:
		_eye.projection = Camera3D.PROJECTION_ORTHOGONAL
		_eye.size = ortho
	_eye.global_position = from
	_eye.look_at(to, Vector3.UP if absf((to - from).normalized().y) < 0.99 else Vector3.FORWARD)
	for i in 4:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()


func _save(shots: Array) -> void:
	if _folder.is_empty() or DisplayServer.get_name() == "headless":
		return
	var first: Image = shots[0]
	var w := first.get_width() / 2
	var h := first.get_height() / 2
	var sheet := Image.create(w * 2, h * ceili(shots.size() / 2.0), false, first.get_format())
	for index in shots.size():
		var shot: Image = shots[index]
		shot.resize(w, h, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(shot, Rect2i(Vector2i.ZERO, shot.get_size()), Vector2i(w * (index % 2), h * (index / 2)))
	var path := "%s/jaula_%d.png" % [_folder, _number]
	sheet.save_png(path)
	print("CAPTURA ", path)
