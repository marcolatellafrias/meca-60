class_name BaseBagRig
extends Node3D

## LA BOLSA CON FÍSICA (el usuario, 17/11/2026: «la bolsa de boxeo… con varios loop cuts y con físicas y con huesos, así
## cuando le pego reacciona… que cuelgue con una soga… así se siente satisfactorio pegarle»):
##   · LA CHAPA hexagonal en el techo (BaseBag.plate), fija.
##   · LA CADENA: eslabones sueltos (cuerpos rígidos) de eslabón grande, cada uno colgado del anterior con un perno
##     (PinJoint3D); el primero, de la chapa.
##   · LA BOLSA, en TRAMOS (`PIECES` cuerpos rígidos, uno debajo del otro) unidos por articulaciones de cono
##     (ConeTwistJoint3D) que la dejan doblarse un poco (SWING grados por articulación) y casi no torcerse. El de arriba
##     cuelga de la cadena.
##   · LA PIEL: la malla low poly con cortes de lazo y sombreado suave (BaseBag.skinned_mesh), con un hueso por tramo; cada
##     cuadro los huesos copian a los tramos, así la bolsa se dobla donde se dobla la física.
## El marco: el origen es el punto del techo; la bolsa cuelga hacia −Y. `hit` le pega (para las pruebas y el video).
## Los valores son para mirar, no los de la meca (el usuario: «la meca todavía no tiene valores de referencia»).

## Los tramos de la bolsa, los cortes de lazo de la piel, lo que se dobla cada articulación (grados) y lo que se tuerce.
const PIECES := 4
const CUTS := 9
const SWING := 9.0
const TWIST := 3.0
## Lo que pesa la bolsa entera (kg) y cada eslabón, y lo que frenan (para que no se hamaque para siempre).
const BAG_MASS := 600.0
const LINK_MASS := 20.0
const LINEAR_DAMP := 0.15
const ANGULAR_DAMP := 0.6

var _pieces: Array[RigidBody3D] = []
var _skeleton: Skeleton3D
var _piece_tall := 1.0


## La arma: la chapa en el origen, `chain` metros de cadena y la bolsa de `radius` y `tall` debajo.
func build(radius: float, tall: float, chain: float, color: Color) -> void:
	var ceiling := StaticBody3D.new()
	ceiling.name = "Chapa"
	add_child(ceiling)
	BaseBag.plate(ceiling, Vector3.ZERO)
	var hook := Vector3.DOWN * BaseBag.PLATE_THICK
	var link := BaseBag.CHAIN_LINK
	var count := maxi(1, int(round(chain / (link * 0.8))))
	var step := chain / count
	var above: PhysicsBody3D = ceiling
	for i in count:
		var body := RigidBody3D.new()
		body.name = "Eslabón %d" % (i + 1)
		body.mass = LINK_MASS
		body.linear_damp = LINEAR_DAMP
		body.angular_damp = ANGULAR_DAMP
		body.position = hook + Vector3.DOWN * step * (i + 0.5)
		add_child(body)
		BaseBag.chain_link(body, link, i % 2 == 1)
		var shape := CollisionShape3D.new()
		var capsule := CapsuleShape3D.new()
		capsule.radius = link * 0.18
		capsule.height = link
		shape.shape = capsule
		body.add_child(shape)
		_pin(above, body, hook + Vector3.DOWN * step * i)
		above = body
	# LA BOLSA, en tramos
	var top := hook + Vector3.DOWN * chain
	_piece_tall = tall / PIECES
	for i in PIECES:
		var body := RigidBody3D.new()
		body.name = "Tramo %d" % (i + 1)
		body.mass = BAG_MASS / PIECES
		body.linear_damp = LINEAR_DAMP
		body.angular_damp = ANGULAR_DAMP
		body.position = top + Vector3.DOWN * _piece_tall * (i + 0.5)
		add_child(body)
		var shape := CollisionShape3D.new()
		var cylinder := CylinderShape3D.new()
		cylinder.radius = radius
		cylinder.height = _piece_tall
		shape.shape = cylinder
		body.add_child(shape)
		var joint_at := top + Vector3.DOWN * _piece_tall * i
		if i == 0:
			_pin(above, body, joint_at)
		else:
			_cone(above, body, joint_at)
		above = body
		_pieces.append(body)
	_skin(radius, tall, top, color)


## UN PERNO entre dos cuerpos, en `at` (marco de la bolsa).
func _pin(a: PhysicsBody3D, b: PhysicsBody3D, at: Vector3) -> void:
	var joint := PinJoint3D.new()
	joint.position = at
	add_child(joint)
	joint.node_a = joint.get_path_to(a)
	joint.node_b = joint.get_path_to(b)


## UNA ARTICULACIÓN DE CONO entre dos tramos, en `at`, con el eje a lo largo de la bolsa (el X de la articulación).
func _cone(a: PhysicsBody3D, b: PhysicsBody3D, at: Vector3) -> void:
	var joint := ConeTwistJoint3D.new()
	joint.transform = Transform3D(Basis(Vector3.BACK, -PI * 0.5), at)
	joint.set_param(ConeTwistJoint3D.PARAM_SWING_SPAN, deg_to_rad(SWING))
	joint.set_param(ConeTwistJoint3D.PARAM_TWIST_SPAN, deg_to_rad(TWIST))
	add_child(joint)
	joint.node_a = joint.get_path_to(a)
	joint.node_b = joint.get_path_to(b)


## LA PIEL: el esqueleto (un hueso por tramo, con la cabeza arriba de su tramo), la malla y su piel (las poses de reposo).
func _skin(radius: float, tall: float, top: Vector3, color: Color) -> void:
	_skeleton = Skeleton3D.new()
	_skeleton.position = top
	add_child(_skeleton)
	var skin := Skin.new()
	for i in PIECES:
		var bone := _skeleton.add_bone("tramo_%d" % (i + 1))
		if i > 0:
			_skeleton.set_bone_parent(bone, i - 1)
		var rest := Transform3D(Basis(), Vector3.DOWN * (_piece_tall if i > 0 else 0.0))
		_skeleton.set_bone_rest(bone, rest)
		_skeleton.set_bone_pose_position(bone, rest.origin)
		skin.add_bind(bone, Transform3D(Basis(), Vector3.DOWN * _piece_tall * i).affine_inverse())
	var mesh := MeshInstance3D.new()
	mesh.mesh = BaseBag.skinned_mesh(radius, tall, PIECES, CUTS)
	mesh.material_override = Clay.material(color)
	mesh.skin = skin
	_skeleton.add_child(mesh)
	mesh.skeleton = mesh.get_path_to(_skeleton)


## CADA CUADRO, los huesos copian a los tramos: la pose de cada hueso es la de su tramo (corrida a su cabeza), en el
## marco del esqueleto y relativa al hueso de arriba.
func _process(_delta: float) -> void:
	if _pieces.is_empty():
		return
	var into := _skeleton.global_transform.affine_inverse()
	var above := Transform3D()
	for i in PIECES:
		var head := into * _pieces[i].global_transform * Transform3D(Basis(), Vector3.UP * _piece_tall * 0.5)
		var local := above.affine_inverse() * head
		_skeleton.set_bone_pose_position(i, local.origin)
		_skeleton.set_bone_pose_rotation(i, local.basis.get_rotation_quaternion())
		above = head


## LE PEGA: un impulso (N·s, mundo) en `at` (mundo), al tramo más cercano.
func hit(impulse: Vector3, at: Vector3) -> void:
	var best: RigidBody3D = null
	var best_distance := INF
	for body in _pieces:
		var distance := body.global_position.distance_to(at)
		if distance < best_distance:
			best_distance = distance
			best = body
	if best != null:
		best.apply_impulse(impulse, at - best.global_position)


## Los tramos (para seguirlos desde afuera).
func pieces() -> Array[RigidBody3D]:
	return _pieces
