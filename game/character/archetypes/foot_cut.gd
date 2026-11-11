class_name FootCut
extends Resource

## ── UN LOOP CUT DEL PIE DE CAJA (22/10/2026, lo pidió el dios del juego, en el low poly) ─────────────────────────────
## El pie low poly es una caja acostada del talón a la punta (ver ProceduralBodyUtil._box_foot), y cada uno de estos es
## un anillo que la cruza de lado a lado. De sus cuatro lados se mueven tres —arriba, adentro y afuera—: el de abajo es la
## suela y se queda siempre en el piso. Los cortes a lo largo no se editan: son la densidad (ver BodyDensity.foot_across).

## Dónde cae, del talón (0) a la punta (1), en fracción del largo del pie.
@export_range(0.0, 1.0, 0.01) var at := 0.0
## Su alto desde el piso, en metros: el lado de arriba.
@export_range(0.005, 0.2, 0.001, "suffix:m") var height := 0.06
## Hasta dónde llega hacia adentro (hacia la otra pierna) desde el eje del tobillo, en metros.
@export_range(0.005, 0.2, 0.001, "suffix:m") var inner := 0.045
## Y hacia afuera.
@export_range(0.005, 0.2, 0.001, "suffix:m") var outer := 0.045


static func make(new_at: float, new_height: float, new_inner: float, new_outer: float) -> FootCut:
	var out := FootCut.new()
	out.at = new_at
	out.height = new_height
	out.inner = new_inner
	out.outer = new_outer
	return out


func copy() -> FootCut:
	return make(at, height, inner, outer)


func blend(other: FootCut, f: float) -> FootCut:
	return make(lerpf(at, other.at, f), lerpf(height, other.height, f), lerpf(inner, other.inner, f),
		lerpf(outer, other.outer, f))


## Los metros, escalados (la lupa del sandbox): `at` es una fracción y no se toca.
func scale_metres(factor: float) -> void:
	height *= factor
	inner *= factor
	outer *= factor


func signature() -> String:
	return "%.4f,%.4f,%.4f,%.4f;" % [at, height, inner, outer]
