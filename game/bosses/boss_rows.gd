class_name BossRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS JEFES (ver SandboxRow, docs/technical/sandbox.md). *El jefe bola se
## borró el 15/11/2026 (el usuario: «la trayectoria del juego va a ser más con pelear enemigos más humanoides… borraría
## todo lo de la bola»).* Ahora, el Luchador de orugas y las maquetas.

static func rows() -> Array[SandboxRow]:
	return [
		# EL LUCHADOR DE ORUGAS (Brawler): el jefe humanoide, de a un paso.
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Luchador de orugas") \
			.add(SandboxRow.Build.NEAR, [BrawlerArchetype.new()]) \
			.panel(KEY_F1, "el luchador: las orugas, la cintura, el horno, la ira y la arena", BrawlerPanel.new()),
		# LAS MAQUETAS (BossMaquettes): jefes de arcilla, quietos, con sus puntos débiles, sus fases y sus ataques de área.
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Maquetas de jefes") \
			.add(SandboxRow.Build.NEAR, BossRows.maquettes()),
	]


static func maquettes() -> Array:
	var all := []
	for i in BossMaquettes.ALL.size():
		all.append(BossMaquetteArchetype.new(i))
	return all
