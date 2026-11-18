class_name BossRows
extends RefCounted

## LAS FILAS DEL SANDBOX DE LOS JEFES (ver SandboxRow, docs/technical/sandbox.md). *El jefe bola se
## borró el 15/11/2026 (el usuario: «la trayectoria del juego va a ser más con pelear enemigos más humanoides… borraría
## todo lo de la bola»).* Ahora, el Luchador de orugas y las maquetas.

## El panel de todos los jefes, en F7 en cada fila de jefes (el usuario: «un panel F de categoría de voces, y los paneles
## de cada voz serían más paneles de parcela»; el sandbox no tiene panel de supercategoría: la misma tecla en cada fila).
const ALL_LABEL := "todos los jefes: la escala y las marcas en el piso"


static func luchador() -> SandboxRow:
	var parcel := BrawlerArchetype.new()
	return SandboxRow.new(SandboxSuper.Id.BOSSES, "Luchador de orugas") \
		.add(SandboxRow.Build.NEAR, [parcel]) \
		.parcel_panel(parcel, KEY_F1, "el luchador: el cuerpo, sus modos y sus poderes (se tildan, con sus variantes)",
			BrawlerPanel.new()) \
		.panel(KEY_F7, ALL_LABEL, BossSettingsPanel.new())


static func rows() -> Array[SandboxRow]:
	return [
		# EL LUCHADOR DE ORUGAS (Brawler): el jefe humanoide, de a un paso. F1, su panel (de su parcela); F7, lo de
		# todos los jefes (en todas las filas de jefes, la misma tecla).
		BossRows.luchador(),
		# EL TALLER DE JEFES (BossWorkshopArchetype): armar cuerpos con piezas y ver qué encaja.
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Taller de jefes") \
			.add(SandboxRow.Build.NEAR, [BossWorkshopArchetype.new()]) \
			.panel(KEY_F7, ALL_LABEL, BossSettingsPanel.new()),
		# LAS MAQUETAS (BossMaquettes): jefes de arcilla, quietos, con sus puntos débiles, sus fases y sus ataques de área.
		SandboxRow.new(SandboxSuper.Id.BOSSES, "Maquetas de jefes") \
			.add(SandboxRow.Build.NEAR, BossRows.maquettes()) \
			.panel(KEY_F7, ALL_LABEL, BossSettingsPanel.new()),
	]


static func maquettes() -> Array:
	var all := []
	for i in BossMaquettes.ALL.size():
		all.append(BossMaquetteArchetype.new(i))
	return all
