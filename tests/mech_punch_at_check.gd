extends Node3D

## LA PIÑA HACIA UN PUNTO (MechArm.punch_at; sin ventana, unos 30 segundos): una meca discreta y una física, quietas,
## tiran con el brazo derecho hacia cinco puntos (al frente, a cada lado, arriba, abajo, y uno lejos, que se recorta).
## Por cada una: a qué distancia del punto (o de lo que alcanza) pasó lo más cerca la mano.
##   godot --headless --path . res://tests/mech_punch_at_check.tscn

## Adónde apunta, desde el hombro, en el espacio de la meca (en largos de brazo, ver MechBody.reach).
const AIMS := {
	"al frente": Vector3(0.0, 0.0, -9.0),
	"a la izquierda": Vector3(-5.0, 0.0, -8.0),
	"a la derecha": Vector3(4.0, 0.0, -8.0),
	"arriba": Vector3(-1.0, 5.0, -8.0),
	"abajo": Vector3(-1.0, -5.0, -8.0),
	"lejos (se recorta)": Vector3(0.0, 0.0, -40.0),
}


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(400, 1, 400), Vector3(0, -0.5, 0))
	add_child(ground)
	PhysicsLayers.mark_fixed(ground)
	for kind: Mech.Arms in [Mech.Arms.POSE, Mech.Arms.MUSCLE]:
		var mech := Mech.new()
		mech.arms_kind = kind
		mech.has_cabin = false
		mech.scripted = true
		# Con «-- --redonda», la caja de la cabina redonda.
		if OS.get_cmdline_user_args().has("--redonda"):
			mech.cabin_shape = Mech.Cabin.ROUND
		mech.position = Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0)
		add_child(mech)
		await _seconds(2.0)
		var arm: MechArm = mech.arms[mech.arms.size() - 1]
		for label: String in AIMS:
			var base := arm.anchor.global_transform
			var shoulder := base * arm.shoulder_local
			var point := shoulder + base.basis * arm._local(AIMS[label] * MechBody.reach)
			var reach := float((MechArm.PUNCHES[MechArm.Punch.STRAIGHT][1][1] as Vector3).length()) * MechBody.reach
			var goal := shoulder + (point - shoulder).limit_length(reach)
			var fired := arm.punch_at(point)
			var closest := INF
			var clock := 0.0
			while clock < 2.0:
				await get_tree().physics_frame
				clock += 1.0 / Engine.physics_ticks_per_second
				closest = minf(closest, arm._hand.global_position.distance_to(goal))
			print("%s, %s: %s · la mano pasó a %.2f m de donde apunta (el brazo alcanza %.1f m)" % [mech.name, label,
				"la tiró" if fired else "NO LA TIRÓ", closest, reach])
		mech.queue_free()
		await _seconds(0.5)
	get_tree().quit()


func _seconds(seconds: float) -> void:
	var clock := 0.0
	while clock < seconds:
		await get_tree().physics_frame
		clock += 1.0 / Engine.physics_ticks_per_second
