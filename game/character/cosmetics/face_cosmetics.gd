class_name FaceCosmetics
extends RefCounted

## ── LOS COSMÉTICOS DE LA CARA QUE HAY (18/11/2026) ──────────────────────────────────────────────────────────────────
## Las primeras pruebas del sistema (ver FaceCosmetic): unos bigotes, apoyados en la altura de la boca, y unas cejas,
## en la de los ojos. Números de la cabeza de referencia, en metros: `(x, arriba del ancla, medio alto)`.

## LAS MARCAS de las dos alturas, para verlas en la vitrina: una raya fina a lo ancho.
static func eye_mark() -> FaceCosmetic:
	return FaceCosmetic.make("ojos", FaceCosmetic.Anchor.EYES, [Vector3(0, 0, 0.0015), Vector3(0.05, 0, 0.0015)],
		true, 0.001, Color(0.2, 0.45, 0.95))


static func mouth_mark() -> FaceCosmetic:
	return FaceCosmetic.make("boca", FaceCosmetic.Anchor.MOUTH, [Vector3(0, 0, 0.0015), Vector3(0.035, 0, 0.0015)],
		true, 0.001, Color(0.9, 0.2, 0.2))


static func mustaches() -> Array[FaceCosmetic]:
	var out: Array[FaceCosmetic] = []
	out.append(FaceCosmetic.make("fino", FaceCosmetic.Anchor.MOUTH,
		[Vector3(0, 0.011, 0.003), Vector3(0.018, 0.010, 0.0028), Vector3(0.028, 0.007, 0.002)], true, 0.004))
	out.append(FaceCosmetic.make("manubrio", FaceCosmetic.Anchor.MOUTH,
		[Vector3(0, 0.012, 0.005), Vector3(0.016, 0.010, 0.005), Vector3(0.030, 0.006, 0.0035),
			Vector3(0.040, 0.012, 0.0025)], true, 0.006))
	out.append(FaceCosmetic.make("morsa", FaceCosmetic.Anchor.MOUTH,
		[Vector3(0, 0.011, 0.008), Vector3(0.018, 0.007, 0.008), Vector3(0.030, -0.004, 0.007),
			Vector3(0.034, -0.012, 0.004)], true, 0.008))
	out.append(FaceCosmetic.make("cepillo", FaceCosmetic.Anchor.MOUTH,
		[Vector3(0, 0.011, 0.005), Vector3(0.012, 0.011, 0.005)], true, 0.007))
	return out


static func brows() -> Array[FaceCosmetic]:
	var out: Array[FaceCosmetic] = []
	out.append(FaceCosmetic.make("rectas", FaceCosmetic.Anchor.EYES,
		[Vector3(0.012, 0.020, 0.004), Vector3(0.036, 0.020, 0.004)], false, 0.004))
	out.append(FaceCosmetic.make("arqueadas", FaceCosmetic.Anchor.EYES,
		[Vector3(0.010, 0.018, 0.003), Vector3(0.023, 0.024, 0.0035), Vector3(0.038, 0.018, 0.0025)], false, 0.004))
	out.append(FaceCosmetic.make("gruesas", FaceCosmetic.Anchor.EYES,
		[Vector3(0.010, 0.020, 0.007), Vector3(0.037, 0.022, 0.006)], false, 0.006))
	out.append(FaceCosmetic.make("enojadas", FaceCosmetic.Anchor.EYES,
		[Vector3(0.010, 0.013, 0.004), Vector3(0.037, 0.025, 0.004)], false, 0.004))
	return out
