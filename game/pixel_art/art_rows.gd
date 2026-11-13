class_name ArtRows
extends RefCounted

## LAS FILAS DEL SANDBOX DEL ARTE (ver SandboxRow, docs/sandbox.md): pintar con píxeles y las partículas.

static func rows() -> Array[SandboxRow]:
	var particles := ParticleArchetype.catalogue()
	var particle_row := SandboxRow.new(SandboxSuper.Id.ART, "Partículas").add(SandboxRow.Build.NEAR, particles)
	for made in ParticleArchetype.row_keys(particles[0] as ParticleArchetype):
		particle_row.key(made)
	return [
		SandboxRow.new(SandboxSuper.Id.ART, "Píxeles") 			.add(SandboxRow.Build.NEAR, [PixelArtArchetype.new()]) 			.panel(KEY_F1, "pintar con píxeles la cara que mirás", PixelPaintPanel.new()),
		particle_row,
	]
