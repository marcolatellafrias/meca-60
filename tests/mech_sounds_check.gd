extends Node

## LOS SONIDOS DE LA MECA QUE DEPENDEN DEL ESTADO (18/11/2026; ver MechSounds): la meca jaula, manejada por sus controles
## de adentro (MechCockpit), salta, levita, cae, hace un dash, camina, vacía el propulsor, carga y tira una piña, recibe un golpe y se queda sin energía; imprime cuántas veces sonó cada
## evento. Sin ventana:
##   godot --headless --path . res://tests/mech_sounds_check.tscn


func _ready() -> void:
	var ground := StaticBody3D.new()
	Clay.shape_box(ground, Vector3(800, 1, 800), Vector3(0, -0.5, 0))
	PhysicsLayers.mark_fixed(ground)
	add_child(ground)
	var mech := CageMech.new()
	mech.position = Vector3(0.0, Mech.standing_height(mech.cabin_shape), 0.0)
	add_child(mech)
	await _wait(1.5)
	var cockpit := (mech.keys as ToolMechKeys).cockpit
	cockpit.jump = true
	await _wait(0.3)
	cockpit.jump = false
	await _wait(0.4)
	cockpit.levitate = true
	cockpit.jump = true
	await _wait(1.0)
	cockpit.levitate = false
	cockpit.jump = false
	await _wait(3.0)
	print("en el piso: %s" % mech.grounded)
	cockpit.dash_way = Vector2(0.0, 1.0)
	cockpit.dash = true
	await _wait(0.2)
	cockpit.dash = false
	await _wait(1.0)
	# Camina: los pasos.
	cockpit.move = Vector2(0.0, 1.0)
	await _wait(2.0)
	cockpit.move = Vector2.ZERO
	await _wait(0.5)
	# Levita hasta vaciar el propulsor y sigue pidiendo.
	mech.mover.fly_fuel = 0.05
	cockpit.jump = true
	await _wait(0.3)
	cockpit.jump = false
	await _wait(0.1)
	cockpit.levitate = true
	cockpit.jump = true
	await _wait(1.0)
	cockpit.levitate = false
	cockpit.jump = false
	await _wait(2.5)
	# Una piña cargada (como el mando de su brazo) y un golpe que le entra.
	if mech.melee != null:
		mech.melee.charging_since = Time.get_ticks_msec() / 1000.0
		await _wait(0.6)
		mech.melee.charging_since = -1.0
		mech.melee.main_strike()
		await _wait(0.6)
	var health := Health.of(mech) if Health.of(mech) != null else Health.attach(mech, 100.0)
	await _wait(0.2)
	health.left -= 12.0
	await _wait(0.3)
	mech.energy.level = 0.01
	mech.energy.spend(0.01)
	await _wait(0.5)
	print("SONIDOS: ", MechSounds.heard)
	get_tree().quit()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
