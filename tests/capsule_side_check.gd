extends Node3D

## DE COSTADO MANDA EL CÓDIGO: QUE NO SE ROMPA LO DE SIEMPRE (unos 10 segundos, sin ventana; ver CharacterRigidBody3D,
## DE COSTADO MANDA EL CÓDIGO). Cuatro carriles, cada uno con un flaco alto:
##   1. SUBE UNA ESCALERA de 1,5 m (la cápsula por su rampa, ver Stairs) hasta el descanso.
##   2. EN UNA RAMPA de 20°: quieto 3 s (no tiene que resbalar) y después la sube.
##   3. CONTRA UNA PARED EN DIAGONAL: va a 45° contra la pared y tiene que deslizarse a lo largo.
##   4. LE PEGA UN CUBO de 30 kg a 6 m/s, parado: retrocede, se inclina y sigue de pie.
##   godot --headless --path . res://tests/capsule_side_check.tscn

const STONE := Color(0.6, 0.58, 0.55)
const SLOPE_DEG := 20.0
const RAMP_LEN := 8.0


func _ready() -> void:
	var ground := StaticBody3D.new()
	add_child(ground)
	Clay.solid(ground, Vector3(80, 1, 40), Vector3(0, -0.5, 0), STONE)
	# 1. La escalera.
	var stairs_top := Vector3(0.0, 1.5, 2.0 + Stairs.run_for(1.5) + 1.0)
	Stairs.flight(self, Vector3(0.0, 0.0, 2.0), Vector3.BACK, 1.5, 1.6, STONE)
	Stairs.landing(self, stairs_top, Vector2(1.6, 2.0), 0.0, STONE)
	# 2. La rampa: una tabla que arranca en el piso en z = 2 y sube hacia +z.
	var slope := deg_to_rad(SLOPE_DEG)
	var up_along := Vector3(0.0, sin(slope), cos(slope))
	var ramp := StaticBody3D.new()
	add_child(ramp)
	var ramp_basis := Basis(Vector3.RIGHT, -slope)
	var ramp_center := Vector3(6.0, 0.0, 2.0) + up_along * RAMP_LEN * 0.5 - (ramp_basis * Vector3.UP) * 0.15
	Clay.solid(ramp, Vector3(2.0, 0.3, RAMP_LEN), ramp_center, STONE, ramp_basis)
	var ramp_start := Vector3(6.0, 0.0, 2.0)
	# 3. La pared, a lo largo de x.
	var wall := StaticBody3D.new()
	add_child(wall)
	Clay.solid(wall, Vector3(12.0, 2.0, 0.3), Vector3(16.0, 1.0, 3.0), STONE)
	var climber := PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, Vector3(0, 0, 0), PI)
	var rester := PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, ramp_start + up_along * 3.0, PI)
	var mover := PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, Vector3(12.0, 0, 0), PI)
	var target := PeopleArchetype.spawn(self, EntityArchetype.Archetype.lanky, Vector3(26.0, 0, 0), PI)
	for bi: BoneInstantiator in [climber, rester, mover, target]:
		CharacterActions.of(bi)
	await get_tree().create_timer(1.0).timeout
	var floor_y := target.char_rigidbody.global_position.y
	var rest_at := rester.char_rigidbody.global_position
	var move_from := mover.char_rigidbody.global_position
	CharacterActions.of(climber).go_to(stairs_top, true, true)
	CharacterActions.of(mover).go_to(Vector3(20.0, 0.0, 8.0), true)
	# 4. El cubo, desde 3 m adelante, a 6 m/s.
	var cube := (PackageArchetype.catalogue()[1] as PackageArchetype).build_body()
	add_child(cube)
	cube.mass = 30.0
	cube.global_position = target.char_rigidbody.global_position + Vector3(0.0, 0.3, 3.0)
	cube.linear_damp_mode = RigidBody3D.DAMP_MODE_REPLACE
	cube.linear_damp = 0.0
	cube.linear_velocity = Vector3(0.0, 1.0, -6.0)
	var target_from := target.char_rigidbody.global_position
	var lean := 0.0
	var fell := false
	var t := 0.0
	while t < 3.0:
		await get_tree().physics_frame
		t += get_physics_process_delta_time()
		lean = maxf(lean, target.char_rigidbody.impact_xz.length())
		fell = fell or target._is_ragdolling()
	print("2. RAMPA, quieto 3 s: se corrió %.2f m" % (rester.char_rigidbody.global_position - rest_at).length())
	var ramp_top := ramp_start + up_along * (RAMP_LEN - 0.5)
	CharacterActions.of(rester).go_to(ramp_top, true, true)
	print("4. CUBO: retrocedió %.2f m · inclinación máxima %.2f · %s" % [
		(target.char_rigidbody.global_position - target_from).length(), lean, "SE CAYÓ" if fell else "de pie"])
	await get_tree().create_timer(6.0).timeout
	var climbed := climber.char_rigidbody.global_position
	print("1. ESCALERA: subió %.2f m (el descanso, %.2f) · le falta %.2f m" % [climbed.y - floor_y, stairs_top.y,
		Vector2(climbed.x - stairs_top.x, climbed.z - stairs_top.z).length()])
	var on_ramp := rester.char_rigidbody.global_position
	print("2. RAMPA, subiéndola: subió %.2f m (hasta la punta, %.2f) · le falta %.2f m" % [on_ramp.y - rest_at.y,
		ramp_top.y - (ramp_start + up_along * 3.0).y, Vector2(on_ramp.x - ramp_top.x, on_ramp.z - ramp_top.z).length()])
	var slid := mover.char_rigidbody.global_position - move_from
	print("3. PARED: se deslizó %.2f m a lo largo y %.2f hacia la pared (la pared está a 3 m)" % [slid.x, slid.z])
	get_tree().quit()
