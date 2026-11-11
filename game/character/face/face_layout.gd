class_name FaceLayout

## LA CARA DE TODOS: los ojos y la boca, como los eligió el dios del juego en las maquetas (13 y 14/10/2026) y no como
## estructuras con formas que se cambian: el 15/10/2026 pidió borrar los gestos viejos —los ojos con pupila (redondo,
## almendrado, cerrado), las bocas con dientes (hablando, abierta, haciendo fuerza), el parpadeo y la boca que se movía
## con la voz— y dejar sólo los nuevos.
##
##   · LOS OJOS, círculos blancos con borde y sin pupila, donde estaban las esferitas de la primera maqueta: al 60 % del
##     cilindro de la forma, a un quinto del ancho del medio y con un radio del 5 % del ancho (`EYES`).
##   · LA BOCA, una línea curva de trazo constante con los extremos redondeados, en una de sus poses (`MOUTHS`): plana,
##     enojada, triste —sutil: el medio plano y apenas caídas las puntas—, semiabierta —más angosta, abre hacia arriba y
##     adentro es la cara—, ancha o angosta; y con labios o sin, un marco grueso y oscuro alrededor de la línea (cuando
##     abre, cada labio crece sólo para afuera).
##
## Todo sale de la FORMA de la cabeza (ver HeadForm), no de números fijos de la cara: el lugar de los ojos es una
## fracción del cilindro y los tamaños, del ancho. Y todo son caminos vectoriales (ver FaceFeature), los mismos que un
## extra, así que los dibuja la misma malla de tinta (ver FaceFeatureMesh) sobre el mismo paño (ver FacePlane.Cloth).
##
## Lo que se apoya en la cara —los lentes, la pipa, las cejas, la barba, las orejas, los extra que cuelgan de los ojos o
## de la boca— pregunta acá dónde están (`eyes`, `mouth_place`).

## LOS OJOS: a qué fracción del cilindro, cuánto se separan del medio y su radio, los dos en fracción del ancho a esa
## altura. `eyes` deja probar otros (ver ClayHeadRecipes, «ojos_posicion»).
const EYES := {"height": 0.6, "apart": 0.2, "radius": 0.05}

## LA BOCA: cuánto debajo de los ojos lo dice cada forma (ver HeadForm.mouth_drop), salvo que las capturas prueben otra
## para todas (`mouth_drop_override`, ver CharacterRecipes, «boca_altura»; −1 ninguna). Todo lo que se apoya en la boca
## —la barba, la pipa, las orejas, la nariz de los extra— la lee de acá (ver `mouth_place`). Los colores y los gruesos de
## la boca y de los ojos son del panel de rasgos (ver FaceStyle).
static var mouth_drop_override := -1.0
## Cuánto más ancho que la línea es el labio, de cada lado, en gruesos de la línea.
const LIP_EXTRA := 2.6
const LIP_COLOR := Color(0.13, 0.03, 0.03)
## En cuántos tramos va la línea: cada tramo es su propio camino (ver `_quad`).
const MOUTH_STEPS := 16

## LAS POSES DE LA BOCA: [nombre, ancho (fracción del ancho de la cabeza), curva (fracción del ancho; ⚠ en el paño + es
## para ABAJO, así que la enojada, el medio arriba, es −), abierta (fracción del ancho), puntas caídas (fracción del
## ancho: el medio plano y las puntas abajo)].
const MOUTHS := [
	["plana", 0.34, 0.0, 0.0, 0.0],
	["enojada", 0.34, -0.06, 0.0, 0.0],
	["triste", 0.34, 0.0, 0.0, 0.025],
	["semiabierta", 0.26, 0.0, 0.09, 0.0],
	["ancha", 0.46, 0.0, 0.0, 0.0],
	["angosta", 0.24, 0.0, 0.0, 0.0],
]
const PLAIN := 0


## CUÁNTO DEBAJO DE LOS OJOS VA LA BOCA en esta forma, en fracción del alto de la cabeza.
static func mouth_drop_of(form: HeadForm) -> float:
	return mouth_drop_override if mouth_drop_override >= 0.0 else form.mouth_drop


## Los nombres de las poses, para los carteles.
static func mouth_names() -> PackedStringArray:
	var out := PackedStringArray()
	for spec: Array in MOUTHS:
		out.append(str(spec[0]))
	return out


## LA CARA ENTERA de una forma: los ojos y la boca en esa pose, con o sin labios, y las ojeras del color de la piel
## (`skin`). El ancho de la boca es de la forma (ver HeadForm.mouth_width).
##
## `look` es LO DE CADA PERSONAJE en la cara (ver CharacterLook): "eye_shape" (ver EYE_SHAPES), "eye_tilt" en grados, y
## las arrugas que lleva, "crow_feet", "forehead_lines" y "nasolabial". Vacío, la cara de siempre.
static func features(form: HeadForm, pose := PLAIN, lips := 0.0, lip_color := LIP_COLOR,
		skin := SKIN_DEFAULT, look := {}) -> Array:
	var out: Array = eye_bags(form, skin) if FaceStyle.current().eye_bags else []
	var eye_shape := int(look.get("eye_shape", 0))
	if look.get("crow_feet", false):
		out.append_array(crow_feet(form, skin, eye_shape))
	if look.get("forehead_lines", false):
		out.append_array(forehead_lines(form, skin))
	if look.get("nasolabial", false):
		out.append_array(nasolabial_folds(form, skin))
	out.append(eyes_drawn(form, eye_shape, float(look.get("eye_tilt", 0.0))))
	out.append_array(mouth(form, pose, lips, lip_color))
	return out


## ── LOS OJOS DE CADA UNO (22/10/2026, lo pidió el dios del juego) ───────────────────────────────────────────────────
## Su forma (`EYE_SHAPES`: [nombre, cuánto más ancho, cuánto más bajo]) y su inclinación, en grados: + la punta de afuera
## arriba. Es el dibujo y nada más: dónde están y su tamaño siguen siendo `eyes`, lo que leen los lentes y las cejas.
const EYE_SHAPES := [
	["redondos", 1.0, 1.0],
	["estirados", 1.5, 0.62],
]


static func eyes_drawn(form: HeadForm, shape := 0, tilt := 0.0) -> FaceFeature:
	var out := eyes(form)
	var spec: Array = EYE_SHAPES[clampi(shape, 0, EYE_SHAPES.size() - 1)]
	if is_equal_approx(float(spec[1]), 1.0) and is_equal_approx(float(spec[2]), 1.0) and is_zero_approx(tilt):
		return out
	# EN LA CAJA DEL OJO, y para arriba: estirar y girar los nodos (y sus manijas, que son direcciones, igual). El espejo
	# da vuelta la x, así que los dos ojos levantan la punta de afuera.
	var turn := Transform2D(deg_to_rad(tilt), Vector2.ZERO) * Transform2D(0.0, Vector2(float(spec[1]), float(spec[2])),
		0.0, Vector2.ZERO)
	var nodes := PackedVector2Array()
	for p in out.nodes:
		nodes.append(turn.basis_xform(p))
	out.nodes = nodes
	return out


## ── LAS ARRUGAS (22/10/2026, lo pidió el dios del juego: «además de las ojeras») ────────────────────────────────────
## Líneas como las ojeras —grueso parejo, puntas redondas— del mismo color que ellas (la piel más oscura y desaturada,
## ver FaceStyle), colgadas de los rasgos: su lugar y su tamaño salen del radio del ojo y del lugar de la boca.
##   · LAS PATAS DE GALLO: tres rayitas en abanico desde la punta de afuera de cada ojo.
##   · LAS DE LA FRENTE: tres líneas apenas arqueadas, arriba de las cejas, más cortas cuanto más arriba.
##   · LAS NASOGENIANAS: de al lado de la nariz hasta pasada la comisura, curvas hacia afuera.
## `WRINKLES` son sus números, en radios del ojo salvo que diga otra cosa.
const WRINKLES := {
	"crow_from": 1.4, "crow_length": 0.9, "crow_spread": 28.0, "crow_thick": 0.09,
	"forehead_from": 0.2, "forehead_step": 0.055, "forehead_arch": 0.25, "forehead_thick": 0.08,
	"fold_thick": 0.1,
}
const WRINKLE_STEPS := 8


## El color de las ojeras y las arrugas: la piel más oscura y desaturada (ver FaceStyle).
static func skin_shade(skin: Color) -> Color:
	var style := FaceStyle.current()
	return Color.from_hsv(skin.h, skin.s * (1.0 - style.bag_desaturate), skin.v * (1.0 - style.bag_darken))


## El radio del ojo, su separación del medio (los dos en metros) y su altura en el paño.
static func _eye_frame(form: HeadForm) -> Array:
	var cloth := FacePlane.Cloth.of(form)
	var y := eye_y(form)
	var width := form.section_at_height(y).x
	return [cloth, width * float(EYES["radius"]) * form.eye_size, width * form.eye_apart, y / cloth.height]


static func crow_feet(form: HeadForm, skin := SKIN_DEFAULT, eye_shape := 0) -> Array:
	var frame := _eye_frame(form)
	var cloth: FacePlane.Cloth = frame[0]
	var r: float = frame[1]
	var apart: float = frame[2]
	var wide: float = float(EYE_SHAPES[clampi(eye_shape, 0, EYE_SHAPES.size() - 1)][1])
	var from: float = apart + r * wide * float(WRINKLES["crow_from"])
	var long: float = r * float(WRINKLES["crow_length"])
	var thick: float = r * float(WRINKLES["crow_thick"])
	var out: Array = []
	for side in [-1.0, 1.0]:
		for k in [-1.0, 0.0, 1.0]:
			var angle := deg_to_rad(float(WRINKLES["crow_spread"]) * k)
			var centre := func(t: float) -> Vector2:
				# (+ para abajo en el paño: la de arriba es −.)
				return Vector2(side * (from + cos(angle) * long * t), -sin(angle) * long * t)
			out.append_array(_round_line(cloth, frame[3], (from + long + r) * 2.0, centre, WRINKLE_STEPS / 2, thick,
				skin_shade(skin)))
	return out


static func forehead_lines(form: HeadForm, skin := SKIN_DEFAULT) -> Array:
	var frame := _eye_frame(form)
	var cloth: FacePlane.Cloth = frame[0]
	var r: float = frame[1]
	var apart: float = frame[2]
	var thick: float = r * float(WRINKLES["forehead_thick"])
	var arch: float = r * float(WRINKLES["forehead_arch"])
	var out: Array = []
	for k in 3:
		var v: float = float(frame[3]) + float(WRINKLES["forehead_from"]) + float(WRINKLES["forehead_step"]) * k
		var half: float = apart * (1.25 - 0.2 * k)
		var centre := func(t: float) -> Vector2:
			var s := 2.0 * t - 1.0
			return Vector2(s * half, -arch * (1.0 - s * s))
		out.append_array(_round_line(cloth, v, half * 2.0 + r * 2.0, centre, WRINKLE_STEPS * 2, thick, skin_shade(skin)))
	return out


static func nasolabial_folds(form: HeadForm, skin := SKIN_DEFAULT) -> Array:
	var frame := _eye_frame(form)
	var cloth: FacePlane.Cloth = frame[0]
	var r: float = frame[1]
	var apart: float = frame[2]
	var head_w := form.section_at_height(eye_y(form)).x
	var mouth_half: float = head_w * float(MOUTHS[PLAIN][1]) * form.mouth_width * 0.5
	var drop: float = cloth.height * mouth_drop_of(form)
	var thick: float = r * float(WRINKLES["fold_thick"])
	var out: Array = []
	for side in [-1.0, 1.0]:
		var start := Vector2(side * apart * 0.55, drop * 0.5)
		var bend := Vector2(side * maxf(apart * 0.85, mouth_half + r * 0.9), drop * 0.78)
		var end := Vector2(side * (mouth_half + r * 0.6), drop * 1.1)
		var centre := func(t: float) -> Vector2:
			return start.lerp(bend, t).lerp(bend.lerp(end, t), t)
		out.append_array(_round_line(cloth, frame[3], (absf(bend.x) + r) * 2.0, centre, WRINKLE_STEPS * 2, thick,
			skin_shade(skin)))
	return out


## ── LAS OJERAS (20/10/2026) ─────────────────────────────────────────────────────────────────────────────────────────
## Lo pidió el dios del juego, el primero de los rasgos de la cara nuevos: debajo de cada ojo, una LÍNEA CURVA con las
## puntas redondeadas —como la boca, de grueso parejo—, del color de la piel pero más oscura y desaturada. Cuelga del
## ojo: su lugar y su tamaño salen del radio del ojo, así siguen a la cara en cualquier forma. Sus números son del panel
## de rasgos (ver FaceStyle); `EYE_BAGS` es lo que era fijo.
##   · `drop`: cuánto más abajo del centro del ojo va su medio, en radios del ojo.
##   · `width`: su largo, en radios.  `sag`: cuánto baja el medio respecto de las puntas, en radios (una sonrisa: las
##     puntas suben).  `thick`: su medio-grueso, en radios.
##   · `darken` y `desaturate`: cuánto más oscura y menos saturada que la piel (fracciones).
const EYE_BAGS := {"drop": 1.55, "width": 1.6, "sag": 0.35, "thick": 0.13, "darken": 0.3, "desaturate": 0.35}
## La piel de quien no dice la suya (las hojas de rasgos, el editor).
const SKIN_DEFAULT := Color(0.85, 0.68, 0.55)
const EYE_BAG_STEPS := 10


static func eye_bags(form: HeadForm, skin := SKIN_DEFAULT, spec := {}) -> Array:
	# LOS NÚMEROS SON DEL PANEL DE RASGOS (ver FaceStyle), salvo que una captura pruebe otros (`spec`).
	if spec.is_empty():
		var style := FaceStyle.current()
		spec = {"drop": style.bag_drop, "width": style.bag_width, "sag": style.bag_sag, "thick": style.bag_thick,
			"darken": style.bag_darken, "desaturate": style.bag_desaturate}
	var cloth := FacePlane.Cloth.of(form)
	var y := eye_y(form)
	var width := form.section_at_height(y).x
	var r: float = width * float(EYES["radius"]) * form.eye_size
	var apart: float = width * form.eye_apart
	var color := Color.from_hsv(skin.h, skin.s * (1.0 - float(spec["desaturate"])),
		skin.v * (1.0 - float(spec["darken"])))
	var long: float = r * float(spec["width"])
	var sag: float = r * float(spec["sag"])
	var thick: float = r * float(spec["thick"])
	var drop: float = r * float(spec["drop"])
	var v := y / cloth.height
	var out: Array = []
	for side in [-1.0, 1.0]:
		var centre := func(t: float) -> Vector2:
			var s := 2.0 * t - 1.0
			# ⚠ EN EL PAÑO + ES PARA ABAJO (como la boca): el medio, más abajo que las puntas.
			return Vector2(side * apart + s * long * 0.5, drop + sag * (1.0 - s * s))
		out.append_array(_round_line(cloth, v, apart * 2.0 + long, centre, EYE_BAG_STEPS, thick, color))
	return out


## UNA LÍNEA CURVA DE GRUESO PAREJO con media vuelta en cada punta, de a tramos chicos (como la boca, ver `mouth`):
## `centre(t)` es su medio, de 0 a 1, en metros de la cara respecto de la altura `v` (y + para abajo, como en el paño).
static func _round_line(cloth: FacePlane.Cloth, v: float, box: float, centre: Callable, steps: int, thick: float,
		color: Color) -> Array:
	var out: Array = []
	var up := func(t: float) -> Vector2:
		var a: Vector2 = centre.call(maxf(t - 0.01, 0.0))
		var b: Vector2 = centre.call(minf(t + 0.01, 1.0))
		var along := (b - a).normalized()
		return Vector2(-along.y, along.x) * thick
	for k in steps:
		var t0 := float(k) / float(steps)
		var t1 := float(k + 1) / float(steps)
		var c0: Vector2 = centre.call(t0)
		var c1: Vector2 = centre.call(t1)
		var n0: Vector2 = up.call(t0)
		var n1: Vector2 = up.call(t1)
		out.append(_quad(cloth, v, box, [c0 + n0, c1 + n1, c1 - n1, c0 - n0], color))
	# LAS PUNTAS REDONDAS, DE A TRAMOS TAMBIÉN: cada media vuelta en `ROUND_CAP_STEPS` tramos de cuatro puntas, que se
	# angostan como un cuarto de círculo hacia la punta. Un polígono de media vuelta entera se triangulaba distinto según la
	# cara —quedaban triángulos chatos que a veces se descartan— y la malla de rasgos tiene que tener el mismo conteo en
	# todas (ver tests/face_features).
	for end: float in [0.0, 1.0]:
		var c: Vector2 = centre.call(end)
		var n: Vector2 = up.call(end)
		var tip: Vector2 = Vector2(n.y, -n.x) if end == 1.0 else Vector2(-n.y, n.x)
		for k in ROUND_CAP_STEPS:
			var f0: float = float(k) / float(ROUND_CAP_STEPS) * PI * 0.5 * ROUND_CAP_REACH
			var f1: float = float(k + 1) / float(ROUND_CAP_STEPS) * PI * 0.5 * ROUND_CAP_REACH
			var a0: Vector2 = c + tip * sin(f0)
			var a1: Vector2 = c + tip * sin(f1)
			out.append(_quad(cloth, v, box, [a0 + n * cos(f0), a1 + n * cos(f1), a1 - n * cos(f1), a0 - n * cos(f0)],
				color))
	return out


## En cuántos tramos va cada punta redonda de una línea (ver `_round_line`), y hasta qué parte del cuarto de vuelta llega
## (no del todo: el último tramo sería un punto).
const ROUND_CAP_STEPS := 4
const ROUND_CAP_REACH := 0.96


## A qué altura van los ojos, en metros desde el fondo de la forma.
static func eye_y(form: HeadForm, spec := EYES) -> float:
	return form.bottom_dome + form.height * float(spec["height"])


## LOS OJOS, un círculo y su espejo, como rasgo dibujable. Su lugar y su tamaño en las coordenadas de la cara (ver
## FaceFeature) son también lo que leen los que se apoyan en los ojos.
static func eyes(form: HeadForm, spec := EYES) -> FaceFeature:
	var cloth := FacePlane.Cloth.of(form)
	var y := eye_y(form, spec)
	var width := form.section_at_height(y).x
	# LA SEPARACIÓN Y EL TAMAÑO SON DE LA FORMA (ver HeadForm.eye_apart, eye_size), salvo que una captura pruebe otros
	# (`spec` propio).
	var diameter := width * float(spec["radius"]) * 2.0 * (form.eye_size if spec == EYES else 1.0)
	var apart: float = form.eye_apart if spec == EYES else float(spec["apart"])
	var style := FaceStyle.current()
	var out := feature(cloth, width * apart, y, diameter, diameter, style.eye_white, true)
	out.nodes = FaceFeature.circle_nodes()
	out.stroke_color = style.eye_line
	out.stroke = style.eye_stroke
	return out


## DÓNDE VA LA BOCA y de qué ancho, como rasgo sin dibujo (sin nodos): lo que leen la barba, la pipa y los extra que
## cuelgan de ella. Su alto es el grueso de la línea.
static func mouth_place(form: HeadForm) -> FaceFeature:
	var cloth := FacePlane.Cloth.of(form)
	var y := eye_y(form) - cloth.height * mouth_drop_of(form)
	var head_w := form.section_at_height(eye_y(form)).x
	return feature(cloth, 0.0, y, head_w * float(MOUTHS[PLAIN][1]), head_w * FaceStyle.current().mouth_thick * 2.0,
		FaceStyle.current().mouth_color, false)


## ── LA BOCA, DE A TRAMOS CHICOS ─────────────────────────────────────────────────────────────────
## La línea es la curva engordada para los dos lados, con media vuelta en cada punta; semiabierta, la mitad de arriba
## sube y la de abajo se queda, y lo de adentro es la cara. Los labios, la misma banda más gruesa, en su color y debajo
## de la línea (ver FaceFeature.on_top).
##
## ⚠ DE A TRAMOS CHICOS: un contorno entero se triangula con triángulos largos de punta a punta, que en la cara curva
## quedan metidos adentro y sólo se ve el borde (pasó). Cada tramo es su propio rasgo y se apoya solo.
##
## LOS LABIOS: `lips` es su grosor (ver CharacterLook.lips; 0 o menos, sin labios) y `lip_color` su color. El de
## siempre, `CharacterLook.LIPS`, crece `LIP_EXTRA` gruesos de la línea para cada lado; otro grosor, en proporción.
static func mouth(form: HeadForm, pose := PLAIN, lips := 0.0, lip_color := LIP_COLOR) -> Array:
	var lip_extra := LIP_EXTRA * maxf(lips, 0.0) / CharacterLook.LIPS
	var spec: Array = MOUTHS[clampi(pose, 0, MOUTHS.size() - 1)]
	var cloth := FacePlane.Cloth.of(form)
	var head_w := form.section_at_height(eye_y(form)).x
	var y := eye_y(form) - cloth.height * mouth_drop_of(form)
	var w := head_w * float(spec[1]) * form.mouth_width
	var curve := head_w * float(spec[2])
	var opening := head_w * float(spec[3])
	var droop := head_w * float(spec[4])
	var style := FaceStyle.current()
	var thick := head_w * style.mouth_thick
	var center := func(t: float) -> Vector2:
		var s := absf(2.0 * t - 1.0)
		return Vector2((t - 0.5) * w, curve * (1.0 - s * s) + droop * pow(s, 3.0))
	var gap := func(t: float) -> float:
		return opening * sin(PI * t)
	var v := y / cloth.height
	var line: Array = []
	var lip_band: Array = []
	for k in MOUTH_STEPS:
		var t0 := float(k) / float(MOUTH_STEPS)
		var t1 := float(k + 1) / float(MOUTH_STEPS)
		var c0: Vector2 = center.call(t0)
		var c1: Vector2 = center.call(t1)
		var g0: float = gap.call(t0)
		var g1: float = gap.call(t1)
		for side in ([-1.0, 0.0] if opening > 0.0 else [0.0]):
			var o0 := Vector2(0.0, g0 * side)
			var o1 := Vector2(0.0, g1 * side)
			line.append(_quad(cloth, v, w, [c0 + o0 + Vector2(0, thick), c1 + o1 + Vector2(0, thick),
				c1 + o1 - Vector2(0, thick), c0 + o0 - Vector2(0, thick)], style.mouth_color))
			if lips > 0.0:
				# Abierta, cada labio crece sólo para afuera (el de arriba para arriba, que en el paño es −): si no,
				# los dos se tocan en el hueco y adentro deja de ser la cara.
				var out := thick * (1.0 + lip_extra)
				var up := -thick if opening > 0.0 and side == 0.0 else -out
				var down := thick if opening > 0.0 and side < 0.0 else out
				lip_band.append(_quad(cloth, v, w, [c0 + o0 + Vector2(0, down), c1 + o1 + Vector2(0, down),
					c1 + o1 + Vector2(0, up), c0 + o0 + Vector2(0, up)], lip_color))
	# LAS PUNTAS, media vuelta cada una (en la semiabierta, donde las dos mitades se juntan).
	for end: Array in [[1.0, PI * 0.5, -PI * 0.5], [0.0, -PI * 0.5, -PI * 1.5]]:
		var c: Vector2 = center.call(end[0])
		for layer in ([0, 1] if lips > 0.0 else [0]):
			var r := thick if layer == 0 else thick * (1.0 + lip_extra)
			var cap := [c]
			for k in 9:
				var a := lerpf(end[1], end[2], float(k) / 8.0)
				cap.append(c + Vector2(cos(a), sin(a)) * r)
			if layer == 0:
				line.append(_quad(cloth, v, w, cap, style.mouth_color))
			else:
				lip_band.append(_quad(cloth, v, w, cap, lip_color))
	for each: FaceFeature in line:
		each.on_top = true
	return lip_band + line


## UN RASGO RELLENO a `x` metros del medio y `y` de alto, de `w` por `h` metros, en el paño de la forma. Sin nodos: el
## que lo pide le pone el camino.
static func feature(cloth: FacePlane.Cloth, x: float, y: float, w: float, h: float, color: Color,
		mirror: bool) -> FaceFeature:
	var f := FaceFeature.new()
	f.kind = FaceFeature.KIND_PATH
	f.closed = true
	f.filled = true
	f.fill_color = color
	f.stroke = 0.0
	var v := y / cloth.height
	f.at_u = x / maxf(cloth.reach(v), 1e-4)
	f.at_v = v
	f.size_x = w / cloth.height
	f.size_y = h / cloth.height
	f.mirror = mirror
	return f


## UN TRAMO como rasgo: un polígono chico en metros de la cara (y para arriba), en la caja de la boca.
static func _quad(cloth: FacePlane.Cloth, v: float, w: float, corners: Array, color: Color) -> FaceFeature:
	var box := maxf(w, 1e-4) * 1.4
	var points := PackedVector2Array()
	for p: Vector2 in corners:
		points.append(Vector2(p.x, -p.y))
	var circle := FaceFeature.circle_nodes()
	var reference := PackedVector2Array()
	for k in range(0, circle.size(), 3):
		reference.append(circle[k])
	if (_area(points) > 0.0) != (_area(reference) > 0.0):
		points.reverse()
	var nodes := PackedVector2Array()
	for p in points:
		nodes.append_array([p / box, Vector2.ZERO, Vector2.ZERO])
	var f := FaceFeature.new()
	f.kind = FaceFeature.KIND_PATH
	f.nodes = nodes
	f.small_polygon = true
	f.closed = true
	f.filled = true
	f.fill_color = color
	f.stroke = 0.0
	f.at_u = 0.0
	f.at_v = v
	f.size_x = box / cloth.height
	f.size_y = box / cloth.height
	return f


## El área con signo de un polígono: su signo dice el sentido.
static func _area(points: PackedVector2Array) -> float:
	var total := 0.0
	for k in points.size():
		var a: Vector2 = points[k]
		var b: Vector2 = points[(k + 1) % points.size()]
		total += a.x * b.y - b.x * a.y
	return total * 0.5
