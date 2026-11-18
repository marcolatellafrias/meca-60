class_name PeopleArchetype
extends SeededArchetype

## UNA PERSONA DE CHARACTER-PARAMETRIC en su parcela: el personaje de allá entero (esqueleto, cuerpo, cara, cápsula
## física, equilibrio y muñeco), traído al proyecto (ver game/character_port/LEEME.md). Uno por arquetipo, en la fila
## Personajes, parados; se los empuja y se caen como allá, y se levantan solos (ver CharacterGetUp). Para ver la escala
## al lado de la meca y que reaccionen con el mismo sistema que la meca de equilibrio (lo pidió el usuario el
## 11/11/2026). J, K y L tiran bolas como en la parcela de la meca de equilibrio (ver TestBall).
##
## Sin el genérico (el usuario no lo quiere ver); el gordo atlético sí. Sin ropa, como la fila de allá.

const PLAYER_SCENE := preload("res://game/character/player.tscn")
const FOOTPRINT := Vector2(4.5, 4.5)
## El orden de la fila, el mismo que allá, sin el genérico.
const ROW_ORDER: Array[EntityArchetype.Archetype] = [EntityArchetype.Archetype.fat_man, EntityArchetype.Archetype.buff,
	EntityArchetype.Archetype.lanky, EntityArchetype.Archetype.kid, EntityArchetype.Archetype.old,
	EntityArchetype.Archetype.fat_athletic]

var archetype := EntityArchetype.Archetype.fat_man


static func catalogue() -> Array[SeededArchetype]:
	var out: Array[SeededArchetype] = []
	for each in ROW_ORDER:
		var row := PeopleArchetype.new()
		row.archetype = each
		row.display_name = String(EntityArchetype.Archetype.keys()[each]).capitalize()
		out.append(row)
	return out


func max_footprint() -> Vector2:
	return FOOTPRINT


func describe(_seed_value: int) -> PackedStringArray:
	var arch := EntityArchetype.create(archetype)
	return PackedStringArray([
		"el personaje de character-parametric, sin ropa",
		"%d kg · se levanta a los %.1f s de quedar quieto" % [roundi(arch.weight), arch.time_to_standup],
	])


func build(_seed_value: int, parent: Node3D) -> Node3D:
	var root := Node3D.new()
	root.name = "Persona"
	parent.add_child(root)
	# Mirando hacia donde uno llega (−X).
	PeopleArchetype.spawn(root, archetype, root.global_position, PI * 0.5)
	return root


func keys() -> Array[SandboxKey]:
	return TestBall.keys(self)


## LAS TRES FUERZAS PARA ESTA PERSONA, con el equilibrio de character-parametric (CharacterRigidBody3D): un golpe de
## frente la inclina Δv × `HitSpring.LEAN_PER_MS` / firmeza, la firmeza es su peso sobre 60 kg por su estabilidad de atrás, y se
## cae en `ragdoll_threshold`. La mueve a la mitad, la deja al 90 % y la tira al 160 % (a una persona liviana la bola le
## rebota y le deja menos: medido el 11/11/2026, al chico un 75 %; por eso la que tira tiene margen).
func ball_pushes() -> Array[float]:
	var arch := EntityArchetype.create(archetype)
	var firmness := maxf(arch.weight / CharacterRigidBody3D.REFERENCE_WEIGHT * arch.backwards_stability, 0.05)
	var falls_at := 0.85
	var out: Array[float] = []
	for share: float in [0.5, 0.9, 1.6]:
		out.append(TestBall.push_for(arch.weight, falls_at * share * firmness / HitSpring.LEAN_PER_MS))
	return out


## UNA PERSONA DE CHARACTER-PARAMETRIC parada en `at` (en el mundo), mirando a `yaw`, colgada de `parent`: como la arma
## la fila de personajes de allá (CharacterArchetype.build), pero de las que se simulan (`CharacterKind.npc`: se la
## choca y se cae) y con quien la levante (CharacterGetUp).
static func spawn(parent: Node3D, archetype_kind: EntityArchetype.Archetype, at: Vector3, yaw: float) -> BoneInstantiator:
	var look := CharacterLooks.for_archetype(archetype_kind)
	var bi := PLAYER_SCENE.instantiate() as BoneInstantiator
	bi.master_seed = EntityInstantiation.debug_seed(archetype_kind, look.seed)
	look.dress(bi)
	bi.kind = CharacterKind.npc()
	bi.name = String(EntityArchetype.Archetype.keys()[archetype_kind]).capitalize()
	parent.add_child(bi)
	bi.place_at(at, yaw)
	var get_up := CharacterGetUp.new()
	get_up.bi = bi
	bi.add_child(get_up)
	return bi
