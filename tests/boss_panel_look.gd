extends Node

## EL PANEL DE UN JEFE (con ventana, unos 5 segundos, sin el sandbox): abre el F1 del Luchador (BrawlerPanel) y saca una
## captura de la pestaña de un poder y de la de un modo, para ver los tildes de modos, las listas para elegir (de qué
## punto sale, con qué pega, las poses) y las variantes. Guarda en la carpeta de --fotos= (si no, en user://).

var _folder := "user://"


func _ready() -> void:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--fotos="):
			_folder = argument.trim_prefix("--fotos=")
	var panel := BrawlerPanel.new()
	add_child(panel)
	panel.setup_panel()
	panel.toggle()
	await _frames(20)
	for tab_name: String in ["Lanzallamas", "Embestida", "Modo vuelo"]:
		var found := false
		for bar: TabBar in panel.find_children("*", "TabBar", true, false):
			for index in bar.tab_count:
				if bar.get_tab_title(index) == tab_name:
					bar.current_tab = index
					found = true
		await _frames(20)
		print("pestaña %s: %s" % [tab_name, "abierta" if found else "NO ESTÁ"])
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_folder.path_join("panel_%s.png" % tab_name.to_lower().replace(" ", "_")))
	get_tree().quit()


func _frames(count: int) -> void:
	for index in count:
		await get_tree().process_frame
